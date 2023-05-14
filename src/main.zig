const std = @import("std");
const day17 = @import("day17.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day17.part1(dataDir);
    try day17.part2(dataDir);
}
