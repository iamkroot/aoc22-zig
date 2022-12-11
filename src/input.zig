const std = @import("std");

pub fn read_input(dataDir: std.fs.Dir, allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
    const inputDir = try dataDir.makeOpenPath("input", .{});
    const f = try inputDir.openFile(filename, .{ .mode = .read_only });
    defer f.close();

    const f_stat = try f.stat();
    const result = try allocator.alloc(u8, f_stat.size);
    errdefer allocator.free(result);
    const read_result = try f.read(result);
    try std.testing.expect(read_result > 0);
    return result;
}
