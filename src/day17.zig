const std = @import("std");
const read_input = @import("input.zig").read_input;

const WindDir = enum(u8) {
    Left = '<',
    Right = '>',
};

const WIDTH: u32 = 7;

const RockSprite = struct {
    const W: u8 = 4;
    grid: [W * W]bool = undefined,
    /// For each column, distance of the lowest rock from grid floor (max=4 units).
    bottomRidge: [W]u8 = undefined,
    leftRidge: [W]u8 = undefined,
    rightRidge: [W]u8 = undefined,

    fn fromAscii(input: []const u8) !RockSprite {
        var grid = [_]bool{false} ** (W * W);
        var bottomRidge = [_]u8{W} ** W;
        var leftRidge = [_]u8{W} ** W;
        var rightRidge = [_]u8{W} ** W;
        var lines = std.mem.split(u8, input, "\n");
        var i: u8 = 0;
        while (lines.next()) |line| {
            var j: u8 = 0;
            for (line) |c| {
                const present = c == '#';
                grid[W * i + j] = present;
                if (present) {
                    bottomRidge[j] = W - i - 1;
                    leftRidge[i] = std.math.min(leftRidge[i], j);
                    rightRidge[i] = std.math.min(rightRidge[i], W - j - 1);
                }
                j += 1;
            }
            i += 1;
        }
        return RockSprite{ .grid = grid, .bottomRidge = bottomRidge, .leftRidge = leftRidge, .rightRidge = rightRidge };
    }
    fn parseMultiple(comptime num: u8, input: []const u8) ![num]RockSprite {
        var rocks = [_]RockSprite{.{}} ** num;
        var rocksiter = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n\n");
        var i: u8 = 0;
        while (rocksiter.next()) |inp| {
            rocks[i] = try RockSprite.fromAscii(std.mem.trim(u8, inp, "\n"));
            i += 1;
        }
        return rocks;
    }
};

const ROCKS_ASCII =
    \\####
    \\
    \\.#.
    \\###
    \\.#.
    \\
    \\..#
    \\..#
    \\###
    \\
    \\#
    \\#
    \\#
    \\#
    \\
    \\##
    \\##
;

const ROCKS = RockSprite.parseMultiple(std.mem.count(u8, ROCKS_ASCII, "\n\n") + 1, ROCKS_ASCII);

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day17_dummy.txt");
    defer allocator.free(input);
    const inp = @ptrCast([*]const WindDir, input.ptr)[0..input.len];
    std.debug.print("inp: {any}\n", .{inp});

    std.debug.print("ROCKS: {any}\n", .{ROCKS});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day17_dummy.txt");
    defer allocator.free(input);
}
