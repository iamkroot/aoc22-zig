const std = @import("std");
const Import = struct {
    name: []const u8,
    import: type,
};
const imports = [_]Import{
    .{ .name = "day1", .import = @import("day1.zig") },
    .{ .name = "day2", .import = @import("day2.zig") },
    .{ .name = "day3", .import = @import("day3.zig") },
    .{ .name = "day4", .import = @import("day4.zig") },
    .{ .name = "day5", .import = @import("day5.zig") },
    .{ .name = "day6", .import = @import("day6.zig") },
    .{ .name = "day7", .import = @import("day7.zig") },
    .{ .name = "day8", .import = @import("day8.zig") },
    .{ .name = "day9", .import = @import("day9.zig") },
    .{ .name = "day10", .import = @import("day10.zig") },
    .{ .name = "day11", .import = @import("day11.zig") },
    .{ .name = "day12", .import = @import("day12.zig") },
    .{ .name = "day13", .import = @import("day13.zig") },
    .{ .name = "day14", .import = @import("day14.zig") },
    .{ .name = "day15", .import = @import("day15.zig") },
    .{ .name = "day16", .import = @import("day16.zig") },
    .{ .name = "day17", .import = @import("day17.zig") },
    .{ .name = "day18", .import = @import("day18.zig") },
    .{ .name = "day19", .import = @import("day19.zig") },
    .{ .name = "day20", .import = @import("day20.zig") },
    .{ .name = "day21", .import = @import("day21.zig") },
    .{ .name = "day22", .import = @import("day22.zig") },
    .{ .name = "day23", .import = @import("day23.zig") },
    .{ .name = "day24", .import = @import("day24.zig") },
    .{ .name = "day25", .import = @import("day25.zig") },
};
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, "data");
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});

    inline for (imports) |imp| {
        std.debug.print("DAY {s}\n", .{imp.name});
        try imp.import.part1(dataDir);
        try imp.import.part2(dataDir);
    }
}
