const std = @import("std");
const day23 = @import("day23.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day23.part1(dataDir);
    try day23.part2(dataDir);
}
