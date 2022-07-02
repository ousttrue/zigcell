const std = @import("std");
const gl = @import("gl");
const glo = @import("glo");
const Document = @import("./document.zig").Document;
const layout = @import("./layout.zig");
const font = @import("./font.zig");
const Vec2 = layout.Vec2;

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

const UboBuffer = extern struct {
    projection: [16]f32,
    screenSize: [2]f32,
    cellSize: [2]f32,
};

pub const Screen = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    cell_width: u32,
    cell_height: u32,
    cells: [65536]Vec2 = undefined,
    shader: glo.Shader,
    vbo: glo.Vbo,
    vao: glo.Vao,
    ubo: glo.Ubo(UboBuffer),
    document: ?Document = null,
    gen: u32 = 0,
    layout: layout.LineLayout = .{},
    draw_count: u32 = 0,
    atlas: font.Atlas,
    texture: ?glo.Texture = null,

    pub fn new(allocator: std.mem.Allocator, font_size: u32) *Self {
        var shader = glo.Shader.load(allocator, VS, FS, GS) catch unreachable;
        var vbo = glo.Vbo.init();
        var vao = glo.Vao.init(vbo, shader.createVertexLayout(allocator), null);
        var ubo = glo.Ubo(UboBuffer).init();

        var self = allocator.create(Self) catch unreachable;
        self.* = .{
            .allocator = allocator,
            .cell_width = font_size / 2,
            .cell_height = font_size,
            .shader = shader,
            .vbo = vbo,
            .vao = vao,
            .ubo = ubo,
            .atlas = font.Atlas.init(allocator),
        };

        vbo.setVertices(Vec2, &self.cells, true);

        return self;
    }

    pub fn delete(self: *Self) void {
        if (self.texture) |*texture| {
            texture.deinit();
        }
        self.shader.deinit();
        self.allocator.destroy(self);
    }

    pub fn open(self: *Self, path: []const u8) !void {
        self.document = Document.open(self.allocator, path);
        self.gen += 1;
    }

    pub fn loadFont(self: *Self, path: []const u8) !void {
        self.texture = try self.atlas.loadFont(path, 30);
    }

    fn getDocumentBuffer(self: Self) ?[]const u16 {
        return if (self.document) |document| document.buffer.items else null;
    }

    pub fn render(self: *Self, width: u32, height: u32) void {
        // clear
        gl.viewport(0, 0, @intCast(c_int, width), @intCast(c_int, height));
        gl.clearColor(0.3, 0.6, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        self.ubo.buffer.cellSize = .{@intToFloat(f32, self.cell_width), @intToFloat(f32, self.cell_height)};
        self.ubo.buffer.screenSize = .{@intToFloat(f32, width), @intToFloat(f32, height)};
        // const resolutionCellSize = [_]f32{
        //     @intToFloat(f32, width), @intToFloat(f32, height), @intToFloat(f32, self.cell_width), @intToFloat(f32, self.cell_height),
        // };
        // self.shader.setVec4("ResolutionCellSize", &resolutionCellSize);

        self.ubo.buffer.projection = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };
        screenToDevice(&self.ubo.buffer.projection, @intToFloat(f32, width), @intToFloat(f32, height), width % self.cell_width, height % self.cell_height);
        // self.shader.setMat4("Projection", &projection);

        self.ubo.upload();

        self.shader.use();
        defer self.shader.unuse();

        if (self.texture) |*texture| {
            texture.bind();
        }
        self.shader.setUbo("Font", 0, self.ubo.handle);

        // layout cells
        const rows = height / self.cell_height;
        const cols = width / self.cell_width;
        if (self.layout.layout(rows, cols, self.gen, &self.cells, self.getDocumentBuffer())) |draw_count| {
            self.draw_count = draw_count;
            self.vbo.update(self.cells, .{});
        }

        self.vao.draw(self.draw_count, .{ .topology = gl.POINTS });
    }
};
