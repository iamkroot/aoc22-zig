const std = @import("std");
const day24 = @import("day24.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day24.part1(dataDir);
    try day24.part2(dataDir);
}
