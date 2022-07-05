const std = @import("std");
const gl = @import("gl");
const glo = @import("glo");

const CURSOR_VS = @embedFile("./shaders/cursor.vs");
const CURSOR_FS = @embedFile("./shaders/cursor.fs");
const CURSOR_GS = @embedFile("./shaders/cursor.gs");

const Vec3 = std.meta.Tuple(&.{ f32, f32, f32 });

pub const Cursor = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    shader: glo.Shader,
    vbo: glo.Vbo,
    vao: glo.Vao,
    row: i32 = 0,
    col: i32 = 0,

    pub fn new(allocator: std.mem.Allocator) *Self {
        var shader = glo.Shader.load(allocator, CURSOR_VS, CURSOR_FS, CURSOR_GS) catch unreachable;
        var vbo = glo.Vbo.init();
        var vertices: [1]Vec3 = undefined;
        vbo.setVertices(Vec3, &vertices, true);
        var vao = glo.Vao.init(vbo, shader.createVertexLayout(allocator), null);

        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .shader = shader,
            .vbo = vbo,
            .vao = vao,
        };
        return self;
    }

    pub fn delete(self: *Self) void {
        self.shader.deinit();
        self.vao.deinit();
        self.vbo.deinit();
        self.allocator.destroy(self);
    }

    // -1+1 +1+1
    //  0+----+2
    //   |   /|
    //   |  / |
    //   | /  |
    //   |/   |
    //  1+----+3
    // -1-1 +1-1
    pub fn draw(self: *Self, rows: u32, cols: u32, ubo_handle: gl.GLuint) void {
        self.shader.use();
        defer self.shader.unuse();

        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE_MINUS_DST_COLOR, gl.ZERO);

        self.shader.setUbo("Global", 0, ubo_handle);

        if (self.col < 0) {
            self.col = 0;
        }
        if (self.col >= cols and cols > 0) {
            self.col = @intCast(i32, cols - 1);
        }
        if (self.row < 0) {
            self.row = 0;
        }
        if (self.row >= rows and rows > 0) {
            self.row = @intCast(i32, rows - 1);
        }

        self.vbo.update([1]Vec3{
            .{
                @intToFloat(f32, self.col),
                @intToFloat(f32, self.row),
            },
        }, .{});
        self.vao.draw(1, .{ .topology = gl.POINTS });
    }
};
