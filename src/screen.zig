const std = @import("std");
const gl = @import("gl");

const Cell = struct {
    row: f32,
    col: f32,
};

pub const Screen = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    cell_width: u32,
    cell_height: u32,
    cells: std.ArrayList(Cell),

    pub fn new(allocator: std.mem.Allocator, font_size: u32) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = .{
            .allocator = allocator,
            .cell_width = font_size / 2,
            .cell_height = font_size,
            .cells = std.ArrayList(Cell).init(allocator),
        };
        return self;
    }
    pub fn delete(self: *Self) void {
        self.cells.deinit();
        self.allocator.destroy(self);
    }

    pub fn render(self: Self, width: u32, height: u32) void {
        const rows = height / self.cell_height;
        const cols = width / self.cell_width;

        _ = rows;
        _ = cols;

        gl.clearColor(0.3, 0.6, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);
    }
};
