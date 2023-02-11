const std = @import("std");
const day21 = @import("day21.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day21.part1(dataDir);
    try day21.part2(dataDir);
}
