const std = @import("std");
const gl = @import("gl");
const glo = @import("glo");
const Document = @import("./document.zig").Document;
const layout = @import("./layout.zig");
const font = @import("./font.zig");
const ubo_buffer = @import("./ubo_buffer.zig");
const CellVertex = layout.CellVertex;

const VS = @embedFile("./simple.vs");
const FS = @embedFile("./simple.fs");
const GS = @embedFile("./simple.gs");

pub fn screenToDevice(m: *[16]f32, width: f32, height: f32, xmod: u32, ymod: u32) void {
    const xmargin = @intToFloat(f32, xmod) / width;
    const ymargin = @intToFloat(f32, ymod) / height;

    m[0] = 2.0 / width;
    m[5] = -(2.0 / height);
    m[12] = -1 + xmargin;
    m[13] = 1 - ymargin;
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

    pub fn new(allocator: std.mem.Allocator, font_size: u32) *Self {
        var shader = glo.Shader.load(allocator, VS, FS, GS) catch unreachable;
        var vbo = glo.Vbo.init();
        var vao = glo.Vao.init(vbo, shader.createVertexLayout(allocator), null);
        var ubo_global = glo.Ubo(ubo_buffer.Global).init();
        var ubo_glyphs = glo.Ubo(ubo_buffer.Glyphs).init();

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
    }

    fn getDocumentBuffer(self: Self) ?[]const u16 {
        return if (self.document) |document| document.buffer.items else null;
    }

    pub fn render(self: *Self, width: u32, height: u32) void {
        // clear
        gl.viewport(0, 0, @intCast(c_int, width), @intCast(c_int, height));
        gl.clearColor(0.3, 0.6, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // ubo_global
        self.ubo_global.buffer.cellSize = .{ @intToFloat(f32, self.cell_width), @intToFloat(f32, self.cell_height) };
        self.ubo_global.buffer.screenSize = .{ @intToFloat(f32, width), @intToFloat(f32, height) };
        self.ubo_global.buffer.projection = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };
        screenToDevice(&self.ubo_global.buffer.projection, @intToFloat(f32, width), @intToFloat(f32, height), width % self.cell_width, height % self.cell_height);
        self.ubo_global.upload();

        self.shader.use();
        defer self.shader.unuse();

        if (self.texture) |*texture| {
            gl.enable(gl.BLEND);
            gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
            texture.bind();
        }
        self.shader.setUbo("Global", 0, self.ubo_global.handle);
        self.shader.setUbo("Glyphs", 1, self.ubo_glyphs.handle);

        // layout cells
        const rows = height / self.cell_height;
        const cols = width / self.cell_width;
        if (self.layout.layout(rows, cols, self.gen, &self.cells, self.getDocumentBuffer(), self.atlas)) |draw_count| {
            self.draw_count = draw_count;
            self.vbo.update(self.cells, .{});
        }

        self.vao.draw(self.draw_count, .{ .topology = gl.POINTS });
    }
};
