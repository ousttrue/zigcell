const std = @import("std");
const gl = @import("gl");
const glo = @import("glo");

const Cell = struct {
    row: f32,
    col: f32,
};

const VS = @embedFile("./simple.vs");
const FS = @embedFile("./simple.fs");

const Vec2 = std.meta.Tuple(&.{ f32, f32 });
const vertices = [_]Vec2{
    .{ -1, -1 },
    .{ 1, -1 },
    .{ 0, 1 },
};

pub const Screen = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    cell_width: u32,
    cell_height: u32,
    cells: std.ArrayList(Cell),
    shader: glo.Shader,
    vbo: glo.Vbo,
    vao: glo.Vao,

    pub fn new(allocator: std.mem.Allocator, font_size: u32) *Self {
        var shader = glo.Shader.load(allocator, VS, FS) catch unreachable;
        var vbo = glo.Vbo.init();
        vbo.setVertices(Vec2, &vertices, false);
        var vao = glo.Vao.init(vbo, shader.createVertexLayout(allocator), null);

        var self = allocator.create(Self) catch unreachable;
        self.* = .{
            .allocator = allocator,
            .cell_width = font_size / 2,
            .cell_height = font_size,
            .cells = std.ArrayList(Cell).init(allocator),
            .shader = shader,
            .vbo = vbo,
            .vao = vao,
        };
        return self;
    }
    pub fn delete(self: *Self) void {
        self.shader.deinit();
        self.cells.deinit();
        self.allocator.destroy(self);
    }

    pub fn render(self: Self, width: u32, height: u32) void {
        const rows = height / self.cell_height;
        const cols = width / self.cell_width;

        _ = rows;
        _ = cols;

        gl.viewport(0, 0, @intCast(c_int, width), @intCast(c_int, height));
        gl.clearColor(0.3, 0.6, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        self.shader.use();
        defer self.shader.unuse();

        self.vao.draw(3, .{});
    }
};
