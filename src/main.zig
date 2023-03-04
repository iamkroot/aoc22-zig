const std = @import("std");
const day25 = @import("day25.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day25.part1(dataDir);
    try day25.part2(dataDir);
}
