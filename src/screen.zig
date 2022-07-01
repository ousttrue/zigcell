const std = @import("std");
const gl = @import("gl");
const glo = @import("glo");

const VS = @embedFile("./simple.vs");
const FS = @embedFile("./simple.fs");
const GS = @embedFile("./simple.gs");

const Vec2 = std.meta.Tuple(&.{ f32, f32 });

pub fn screenToDevice(m: *[16]f32, width: f32, height: f32) void {
    m[0] = 2.0 / width;
    m[5] = -(2.0 / height);
    m[12] = -1;
    m[13] = 1;
}

pub const Screen = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    cell_width: u32,
    cell_height: u32,
    cells: [65536]Vec2 = undefined,
    shader: glo.Shader,
    vbo: glo.Vbo,
    vao: glo.Vao,

    pub fn new(allocator: std.mem.Allocator, font_size: u32) *Self {
        var shader = glo.Shader.load(allocator, VS, FS, GS) catch unreachable;
        var vbo = glo.Vbo.init();
        var vao = glo.Vao.init(vbo, shader.createVertexLayout(allocator), null);

        var self = allocator.create(Self) catch unreachable;
        self.* = .{
            .allocator = allocator,
            .cell_width = font_size / 2,
            .cell_height = font_size,
            .shader = shader,
            .vbo = vbo,
            .vao = vao,
        };

        vbo.setVertices(Vec2, &self.cells, true);

        return self;
    }
    pub fn delete(self: *Self) void {
        self.shader.deinit();
        self.allocator.destroy(self);
    }

    pub fn render(self: *Self, width: u32, height: u32) void {
        // clear
        gl.viewport(0, 0, @intCast(c_int, width), @intCast(c_int, height));
        gl.clearColor(0.3, 0.6, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        self.shader.use();
        defer self.shader.unuse();

        const resolutionCellSize = [_]f32{
            @intToFloat(f32, width), @intToFloat(f32, height), @intToFloat(f32, self.cell_width), @intToFloat(f32, self.cell_height),
        };
        self.shader.setVec4("ResolutionCellSize", &resolutionCellSize);

        var projection: [16]f32 = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };
        screenToDevice(&projection, @intToFloat(f32, width), @intToFloat(f32, height));
        self.shader.setMat4("Projection", &projection);

        const rows = height / self.cell_height;
        const cols = width / self.cell_width;
        var i: usize = 0;
        var y: i32 = 0;
        while (y < rows) : (y += 1) {
            var x: i32 = 0;
            while (x < cols) : ({
                x += 1;
                i += 1;
            }) {
                self.cells[i] = .{ @intToFloat(f32, x), @intToFloat(f32, y) };
            }
        }
        self.vbo.update(self.cells, .{});

        self.vao.draw(@intCast(u32, i), .{ .topology = gl.POINTS });
    }
};
