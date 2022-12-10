const std = @import("std");

fn read_input(dataDir: std.fs.Dir, allocator: std.mem.Allocator) ![]const u8 {
    const inputDir = try dataDir.makeOpenPath("input", .{});
    const f = try inputDir.openFile("day1.txt", .{ .mode = .read_only });
    defer f.close();

    const f_stat = try f.stat();
    const result = try allocator.alloc(u8, f_stat.size);
    errdefer allocator.free(result);
    const read_result = try f.read(result);
    try std.testing.expect(read_result > 0);
    return result;
}

pub fn day1(dataDir: std.fs.Dir) !void {
    var buffer: [16000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const result = try read_input(dataDir, allocator);

    var iter = std.mem.split(u8, std.mem.trim(u8, result, "\n"), "\n\n");
    var maxval: u64 = 0;
    while (iter.next()) |value| {
        var lineIter = std.mem.split(u8, value, "\n");
        var val: u64 = 0;
        while (lineIter.next()) |innervalue| {
            const v = try std.fmt.parseUnsigned(u64, innervalue, 10);
            val += v;
        }

        maxval = std.math.max(maxval, val);
    }
    std.debug.print("maxval: {}\n", .{ maxval });
}
