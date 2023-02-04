const std = @import("std");
const day19 = @import("day19.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day19.part1(dataDir);
    try day19.part2(dataDir);
}
