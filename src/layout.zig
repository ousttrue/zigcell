const std = @import("std");
const font = @import("./font.zig");
const CursorPosition = @import("./cursor_position.zig").CursorPosition;
const Utf8Iterator = @import("./Utf8Iterator.zig");
const tag_color = @import("./tag_color.zig");
const getTokenColor = tag_color.getTokenColor;
const isInToken = tag_color.isInToken;

pub const CellVertex = struct {
    col: f32,
    row: f32,
    glyph: f32,
    color: [3]f32,
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

fn LineReader(comptime T: type) type {
    return struct {
        const Self = @This();
        doc: []const T,
        pos: usize = 0,

        fn init(doc: []const T) Self {
            return Self{
                .doc = doc,
            };
        }

        fn getLine(self: *Self) ?[]const T {
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

        fn getLineWithCols(self: *Self, cols: u32) ?[]const T {
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
}

pub const LineLayout = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    cells: [65536]CellVertex = undefined,
    cell_byte_positions: [65535]usize = undefined,
    cell_count: usize = 0,
    tokens: [65535]std.zig.Token = undefined,
    token_count: usize = 0,

    lines: std.ArrayList([]CellVertex),
    cursor_position: CursorPosition = .{},
    cursor_byte_pos: usize = 0,

    pub fn new(allocator: std.mem.Allocator) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .lines = std.ArrayList([]CellVertex).init(allocator),
        };
        return self;
    }

    pub fn delete(self: *Self) void {
        self.lines.deinit();
        self.allocator.destroy(self);
    }

    pub fn layout(self: *Self, doc: []const u16, atlas: *font.Atlas) u32 {
        self.lines.resize(0) catch unreachable;
        self.cell_count = 0;

        var r = LineReader(u16).init(doc);
        var row: u32 = 0;
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

    pub fn layoutTokens(self: *Self, doc: [:0]const u8, atlas: *font.Atlas) u32 {
        var tokenizer: std.zig.Tokenizer = .{
            .buffer = doc,
            .index = 0,
            .pending_invalid_token = null,
        };
        var i: usize = 0;
        while (true) : (i += 1) {
            const token = tokenizer.next();
            if (token.tag == .eof) {
                break;
            }
            self.tokens[i] = token;
        }
        self.token_count = i;

        var r = LineReader(u8).init(doc);
        var row: u32 = 0;
        var bytePos: usize = 0;
        i = 0;
        while (true) : (row += 1) {
            var line = r.getLine() orelse break;
            const head = self.cell_count;

            var it = Utf8Iterator.init(line);
            var col: u32 = 0;
            while (it.next()) |slice| : (col += 1) {
                while (i < self.token_count) : (i += 1) {
                    if (bytePos < self.tokens[i].loc.end) {
                        break;
                    }
                }

                const c = switch (slice.len) {
                    1 => std.unicode.utf8Decode(slice),
                    2 => std.unicode.utf8Decode2(slice),
                    3 => std.unicode.utf8Decode3(slice),
                    4 => std.unicode.utf8Decode4(slice),
                    else => unreachable,
                } catch unreachable;
                self.cells[self.cell_count] = .{
                    .col = @intToFloat(f32, col),
                    .row = @intToFloat(f32, row),
                    .glyph = @intToFloat(f32, atlas.glyphIndexFromCodePoint(@intCast(u16, c))),
                    .color = getTokenColor(bytePos, self.tokens[i]),
                };
                self.cell_byte_positions[self.cell_count] = bytePos;
                self.cell_count += 1;
                bytePos += slice.len;
            }

            self.lines.append(self.cells[head..self.cell_count]) catch unreachable;
        }
        return @intCast(u32, self.cell_count);
    }

    pub fn getCellIndex(self: Self, cursor: CursorPosition) ?usize {
        for (self.cells) |*cell, i| {
            if (i >= self.cell_count) {
                break;
            }
            if (@floatToInt(i32, cell.row) == cursor.row and @floatToInt(i32, cell.col) == cursor.col) {
                return i;
            }
        }
        return null;
    }

    pub fn moveCursor(self: *Self, move: CursorPosition) void {
        if (self.lines.items.len == 0) {
            self.cursor_position.row = 0;
            self.cursor_position.col = 0;
            return;
        }

        std.debug.print("[moveCursor]{}\n", .{move});
        self.cursor_position.row += move.row;
        if (self.cursor_position.row >= self.lines.items.len) {
            self.cursor_position.row = @intCast(i32, self.lines.items.len - 1);
        }

        if (self.cursor_position.row < 0) {
            self.cursor_position.row = 0;
        } else if (self.cursor_position.row >= self.lines.items.len) {
            self.cursor_position.row = @intCast(i32, self.lines.items.len - 1);
        }

        self.cursor_position.col += move.col;
        if (self.cursor_position.col < 0) {
            self.cursor_position.col = 0;
        }

        if (self.getCellIndex(self.cursor_position)) |i| {
            self.cursor_byte_pos = self.cell_byte_positions[i];
            std.debug.print("cursor: {} => cell index: {} => utf8 byte: {}\n", .{ self.cursor_position, i, self.cursor_byte_pos });
            var j: usize = 0;
            while (j < self.token_count) : (j += 1) {
                if (isInToken(self.cursor_byte_pos, self.tokens[j])) {
                    std.debug.print("token: {s}\n", .{@tagName(self.tokens[j].tag)});
                    return;
                }
            }
            std.debug.print("no token\n", .{});
        }
    }
};
