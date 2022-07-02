const std = @import("std");
pub const Vec2 = std.meta.Tuple(&.{ f32, f32 });

fn fillCells(rows: u32, cols: u32, cells: []Vec2) u32 {
    var i: usize = 0;
    var y: i32 = 0;
    while (y < rows) : (y += 1) blk: {
        var x: i32 = 0;
        while (x < cols) : ({
            x += 1;
            i += 1;
        }) {
            if (i >= cells.len) {
                break :blk;
            }
            cells[i] = .{ @intToFloat(f32, x), @intToFloat(f32, y) };
        }
    }
    return @intCast(u32, i);
}

fn getLine(document: []const u16, current: usize) ?usize {
    if (current >= document.len) return null;
    var i: usize = current;
    while (i < document.len) : (i += 1) {
        if (document[i] == '\n') {
            break;
        }
    }
    i;
}

const LineReader = struct {
    const Self = @This();
    doc: []const u16,
    pos: usize = 0,

    fn init(doc: []const u16) Self {
        return Self{
            .doc = doc,
        };
    }

    fn getLine(self: *Self, cols: u32) ?[]const u16 {
        if (self.pos >= self.doc.len) {
            return null;
        }
        const start = self.pos;
        var i = start;
        var col: u32 = 0;
        while (i < self.doc.len and col < cols) : ({
            i += 1;
            col += 1;
        }) {
            if (self.doc[i] == '\n') {
                i += 1;
                break;
            }
        }
        self.pos = i;

        return self.doc[start..i];
    }
};

pub const LineLayout = struct {
    const Self = @This();

    rows: u32 = 0,
    cols: u32 = 0,
    gen: u32 = 0,

    pub fn layout(self: *Self, rows: u32, cols: u32, gen: u32, cells: []Vec2, document: ?[]const u16) ?u32 {
        if (rows == self.rows and cols == self.cols and gen == self.gen) {
            return null;
        }

        std.log.debug("[{}]{}, {}", .{ gen, rows, cols });
        self.rows = rows;
        self.cols = cols;
        self.gen = gen;
        if (document) |doc| {
            var r = LineReader.init(doc);
            var row: u32 = 0;
            var i: usize = 0;
            while (row < rows) : (row += 1) {
                var line = r.getLine(cols) orelse break;
                _ = line;
                for (line) |c, col| {
                    _ = c;
                    // set cell
                    cells[i] = .{ @intToFloat(f32, col), @intToFloat(f32, row) };
                    i += 1;
                }
            }
            return @intCast(u32, i);
        } else {
            return fillCells(rows, cols, cells);
        }
    }
};
