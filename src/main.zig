const std = @import("std");
const day18 = @import("day18.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day18.part1(dataDir);
    try day18.part2(dataDir);
}
