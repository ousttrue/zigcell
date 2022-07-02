const gl = @import("gl");

pub fn Ubo(comptime T: type) type {
    return struct {
        const Self = @This();

        handle: gl.GLuint,
        buffer: T = undefined,

        pub fn init() Self {
            var handle: gl.GLuint = undefined;
            gl.genBuffers(1, &handle);

            return Self{
                .handle = handle,
            };
        }

        pub fn deinit(self: *Self) void {
            gl.deleteBuffers(1, &self.handle);
        }

        pub fn upload(self: Self) void {
            gl.bindBuffer(gl.UNIFORM_BUFFER, self.handle);
            gl.bufferData(gl.UNIFORM_BUFFER, @sizeOf(T), &self.buffer, gl.DYNAMIC_DRAW);
            gl.bindBuffer(gl.UNIFORM_BUFFER, 0);
        }
    };
}
