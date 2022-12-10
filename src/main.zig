const std = @import("std");
const day1 = @import("day1.zig");

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
    try day1.day1(dataDir);
}
