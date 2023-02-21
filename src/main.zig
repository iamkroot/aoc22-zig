const std = @import("std");
const day22 = @import("day22.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day22.part1(dataDir);
    try day22.part2(dataDir);
}
