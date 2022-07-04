const std = @import("std");
const gl = @import("gl");
const glo = @import("glo");
const imutil = @import("imutil");
const Document = @import("./document.zig").Document;
const layout = @import("./layout.zig");
const font = @import("./font.zig");
const ubo_buffer = @import("./ubo_buffer.zig");
const CellVertex = layout.CellVertex;
const Cursor = @import("./cursor.zig").Cursor;

const CELL_GLYPH_VS = @embedFile("./shaders/cell_glyph.vs");
const CELL_GLYPH_FS = @embedFile("./shaders/cell_glyph.fs");
const CELL_GLYPH_GS = @embedFile("./shaders/cell_glyph.gs");

pub fn screenToDevice(m: *[16]f32, width: u32, height: u32, cell_width: u32, cell_height: u32) void {
    const xmod = width % cell_width;
    const xmargin = @intToFloat(f32, xmod) / @intToFloat(f32, width);
    _ = xmargin;
    const ymod = height % cell_height;
    const ymargin = @intToFloat(f32, ymod) / @intToFloat(f32, height);
    _ = ymargin;

    m[0] = 2.0 / @intToFloat(f32, width);
    m[5] = -(2.0 / @intToFloat(f32, height));
    m[12] = -1;
    m[13] = 1;
}

pub const Screen = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    cell_width: u32,
    cell_height: u32,
    cells: [65536]CellVertex = undefined,
    shader: glo.Shader,
    vbo: glo.Vbo,
    vao: glo.Vao,
    ubo_global: glo.Ubo(ubo_buffer.Global),
    ubo_glyphs: glo.Ubo(ubo_buffer.Glyphs),
    document: ?Document = null,
    gen: u32 = 0,
    layout: layout.LineLayout = .{},
    draw_count: u32 = 0,
    atlas: *font.Atlas,
    texture: ?glo.Texture = null,
    cursor: *Cursor,

    pub fn new(allocator: std.mem.Allocator, font_size: u32) *Self {
        var shader = glo.Shader.load(allocator, CELL_GLYPH_VS, CELL_GLYPH_FS, CELL_GLYPH_GS) catch unreachable;
        var vbo = glo.Vbo.init();
        var vao = glo.Vao.init(vbo, shader.createVertexLayout(allocator), null);
        var ubo_global = glo.Ubo(ubo_buffer.Global).init();
        var ubo_glyphs = glo.Ubo(ubo_buffer.Glyphs).init();
        var cursor = Cursor.new(allocator);

        var self = allocator.create(Self) catch unreachable;
        self.* = .{
            .allocator = allocator,
            .cell_width = font_size / 2,
            .cell_height = font_size,
            .shader = shader,
            .vbo = vbo,
            .vao = vao,
            .ubo_global = ubo_global,
            .ubo_glyphs = ubo_glyphs,
            .atlas = font.Atlas.new(allocator),
            .cursor = cursor,
        };

        vbo.setVertices(CellVertex, &self.cells, true);

        return self;
    }

    pub fn delete(self: *Self) void {
        if (self.texture) |*texture| {
            texture.deinit();
        }
        self.atlas.delete();
        self.shader.deinit();
        self.allocator.destroy(self);
    }

    pub fn open(self: *Self, path: []const u8) !void {
        self.document = Document.open(self.allocator, path);
        self.gen += 1;
    }

    pub fn loadFont(self: *Self, path: []const u8, font_size: f32, atlas_size: u32) !void {
        self.texture = try self.atlas.loadFont(path, font_size, atlas_size);
        for (self.atlas.glyphs) |*g, i| {
            self.ubo_glyphs.buffer.glyphs[i] = .{
                .xywh = .{ @intToFloat(f32, g.x0), @intToFloat(f32, g.y0), @intToFloat(f32, g.x1), @intToFloat(f32, g.y1) },
                .offset = .{ g.xoff, g.yoff, g.xoff2, g.yoff2 },
            };
        }
        self.ubo_glyphs.upload();
        self.ubo_global.buffer.atlasSize = .{ @intToFloat(f32, atlas_size), @intToFloat(f32, atlas_size) };
        self.ubo_global.buffer.ascent = self.atlas.ascents[0];
        self.ubo_global.buffer.descent = self.atlas.descents[0];
    }

    fn getDocumentBuffer(self: Self) ?[]const u16 {
        return if (self.document) |document| document.buffer.items else null;
    }

    pub fn render(self: *Self, mouse_input: imutil.MouseInput) void {
        if (mouse_input.is_active) {
            // process keyboard event
        }

        // clear
        gl.viewport(0, 0, @intCast(c_int, mouse_input.width), @intCast(c_int, mouse_input.height));
        gl.clearColor(0.3, 0.6, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // ubo_global
        self.ubo_global.buffer.cellSize = .{ @intToFloat(f32, self.cell_width), @intToFloat(f32, self.cell_height) };
        self.ubo_global.buffer.screenSize = .{ @intToFloat(f32, mouse_input.width), @intToFloat(f32, mouse_input.height) };
        self.ubo_global.buffer.projection = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };
        screenToDevice(&self.ubo_global.buffer.projection, mouse_input.width, mouse_input.height, self.cell_width, self.cell_height);
        self.ubo_global.upload();

        self.shader.use();
        defer self.shader.unuse();

        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
        if (self.texture) |*texture| {
            texture.bind();
        }
        self.shader.setUbo("Global", 0, self.ubo_global.handle);
        self.shader.setUbo("Glyphs", 1, self.ubo_glyphs.handle);

        // layout cells
        const rows = mouse_input.height / self.cell_height;
        const cols = mouse_input.width / self.cell_width;
        if (self.layout.layout(rows, cols, self.gen, &self.cells, self.getDocumentBuffer(), self.atlas)) |draw_count| {
            self.draw_count = draw_count;
            self.vbo.update(self.cells, .{});
        }

        self.vao.draw(self.draw_count, .{ .topology = gl.POINTS });

        self.cursor.draw(0, 0, self.ubo_global.handle);
    }
};
