const std = @import("std");
const day20 = @import("day20.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day20.part1(dataDir);
    try day20.part2(dataDir);
}
