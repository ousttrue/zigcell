const std = @import("std");
const imutil = @import("imutil");
const Self = @This();
const Transport = @import("./Transport.zig");
const Input = @import("./Input.zig");

running: bool = true,
allocator: std.mem.Allocator,
transport: *Transport,
thread: std.Thread,
last_input: ?Input = null,
last_err: ?anyerror = null,

pub fn new(allocator: std.mem.Allocator, transport: *Transport) !*Self {
    var self = try allocator.create(Self);
    self.* = Self{
        .allocator = allocator,
        .transport = transport,
        .thread = try std.Thread.spawn(.{}, startReader, .{self}),
    };

    return self;
}

pub fn delete(self: *Self) void {
    self.running = false;
    if (self.last_input) |*input| {
        input.deinit();
    }
    // self.thread.join();
    self.allocator.destroy(self);
}

fn dispatch(self: *Self, input: Input) void {
    if (self.last_input) |*last_input| {
        last_input.deinit();
    }
    self.last_err = null;
    self.last_input = input;
}

fn startReader(self: *Self) void {
    var json_parser = std.json.Parser.init(self.allocator, false);
    defer json_parser.deinit();

    while (self.running) {
        json_parser.reset();
        if (Input.init(self.allocator, self.transport, &json_parser)) |input| {
            self.dispatch(input);
        } else |err| {
            // shutdown
            self.last_input = null;
            self.last_err = err;
            break;
        }
    }
}
