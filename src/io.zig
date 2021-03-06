const std = @import("std");

pub fn readAllBytesAllocate(allocator: std.mem.Allocator, path: []const u8) ![:0]const u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const file_size = try file.getEndPos();

    var buffer = try allocator.allocSentinel(u8, file_size, 0);
    errdefer allocator.free(buffer);

    const bytes_read = try file.read(buffer);
    std.debug.assert(bytes_read == file_size);
    return buffer;
}
