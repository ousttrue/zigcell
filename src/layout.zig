const std = @import("std");
const font = @import("./font.zig");
const CursorPosition = @import("./cursor_position.zig").CursorPosition;

pub const CellVertex = struct {
    col: f32,
    row: f32,
    glyph: f32,
};

fn fillCells(rows: u32, cols: u32, cells: []CellVertex) u32 {
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
            cells[i] = .{
                .col = @intToFloat(f32, x),
                .row = @intToFloat(f32, y),
                .glyph = 0,
            };
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

    fn getLine(self: *Self) ?[]const u16 {
        if (self.pos >= self.doc.len) {
            return null;
        }
        const start = self.pos;
        var i = start;
        while (i < self.doc.len) : ({
            i += 1;
        }) {
            if (self.doc[i] == '\n') {
                i += 1;
                break;
            }
        }
        self.pos = i;

        return self.doc[start..i];
    }

    fn getLineWithCols(self: *Self, cols: u32) ?[]const u16 {
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

    allocator: std.mem.Allocator,
    cells: [65536]CellVertex = undefined,
    cell_count: usize = 0,
    lines: std.ArrayList([]CellVertex),
    cursor_position: CursorPosition = .{},

    pub fn new(allocator: std.mem.Allocator) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .lines = std.ArrayList([]CellVertex).init(allocator),
        };
        return self;
    }

    pub fn delete(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn layout(self: *Self, document: ?[]const u16, atlas: *font.Atlas) u32 {
        self.lines.resize(0) catch unreachable;
        self.cell_count = 0;

        const doc = document orelse return 0;
        var r = LineReader.init(doc);
        var row: u32 = 0;
        // each line
        while (true) : (row += 1) {
            var line = r.getLine() orelse break;
            const head = self.cell_count;
            for (line) |c, col| {
                self.cells[self.cell_count] = .{
                    .col = @intToFloat(f32, col),
                    .row = @intToFloat(f32, row),
                    .glyph = @intToFloat(f32, atlas.glyphIndexFromCodePoint(c)),
                };
                self.cell_count += 1;
            }
            self.lines.append(self.cells[head..self.cell_count]) catch unreachable;
        }
        return @intCast(u32, self.cell_count);
    }

    pub fn moveCursor(self: *Self, move: CursorPosition) void {
        if (self.lines.items.len == 0) {
            self.cursor_position.row = 0;
            self.cursor_position.col = 0;
            return;
        }

        self.cursor_position.row += move.row;
        if (self.cursor_position.row >= self.lines.items.len) {
            self.cursor_position.row = @intCast(i32, self.lines.items.len - 1);
        }

        if (self.cursor_position.row < 0) {
            self.cursor_position.row = 0;
        } else if (self.cursor_position.row >= self.lines.items.len) {
            self.cursor_position.row = @intCast(i32, self.lines.items.len - 1);
        }

        // var line = self.lines.items[@intCast(usize, self.cursor_position.row)];
        self.cursor_position.col += move.col;
        if (self.cursor_position.col < 0) {
            self.cursor_position.col = 0;
        }
    }
};
