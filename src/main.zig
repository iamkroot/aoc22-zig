const std = @import("std");
const day13 = @import("day13.zig");

/// Get path relative to root dir
fn rootPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("relToPath requires an absolute path!");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file).? ++ "/..";
        break :blk root_dir ++ suffix;
    };
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dataDirPath = try std.fs.realpathAlloc(allocator, rootPath("/data"));
    const dataDir = try std.fs.openDirAbsolute(dataDirPath, .{});
    try day13.part1(dataDir);
    try day13.part2(dataDir);
}
