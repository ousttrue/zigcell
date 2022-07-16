const std = @import("std");
const imutil = @import("imutil");
const Self = @This();
const Transport = @import("./Transport.zig");
const Message = @import("./Message.zig");

running: bool = true,
allocator: std.mem.Allocator,
transport: *Transport,
thread: std.Thread,
last_message: ?Message = null,
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
    if (self.last_message) |*message| {
        message.deinit();
    }
    // self.thread.join();
    self.allocator.destroy(self);
}

fn dispatch(self: *Self, message: Message) void {
    if (self.last_message) |*last_message| {
        last_message.deinit();
    }
    self.last_err = null;
    self.last_message = message;
}

fn startReader(self: *Self) void {
    var json_parser = std.json.Parser.init(self.allocator, false);
    defer json_parser.deinit();

    while (self.running) {
        json_parser.reset();
        if (Message.init(self.allocator, self.transport, &json_parser)) |message| {
            self.dispatch(message);
        } else |err| {
            // shutdown
            self.last_message = null;
            self.last_err = err;
            break;
        }
    }
}
