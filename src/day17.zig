const std = @import("std");
const read_input = @import("input.zig").read_input;

const Dir = enum(u8) {
    Left = '<',
    Right = '>',
    Down = 'v',
};

const WIDTH: u32 = 7;

const RockSprite = struct {
    const W: u8 = 4;
    grid: [W * W]bool = undefined,
    /// For each column, distance of the lowest rock from grid floor (max=4 units).
    bottomRidge: [W]u8 = undefined,
    leftRidge: [W]u8 = undefined,
    rightRidge: [W]u8 = undefined,
    height: u8 = undefined,

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
        return RockSprite{ .grid = grid, .bottomRidge = bottomRidge, .leftRidge = leftRidge, .rightRidge = rightRidge, .height = i };
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
    const RocksIter = struct {
        i: usize = 0,
        j: usize = 0,
        rock: *const RockSprite,
        pos: Pos,

        fn init(rock: *const RockSprite, pos: Pos) RocksIter {
            return RocksIter{ .rock = rock, .pos = pos };
        }

        fn next(self: *RocksIter) ?Pos {
            var i = self.i;
            var j = self.j;
            while (i < W) : (i += 1) {
                while (j < W) : (j += 1) {
                    if (self.rock.grid[i * W + j]) {
                        // store the state
                        self.i = i;
                        self.j = j + 1;
                        return Pos{ .row = self.pos.row - i, .col = self.pos.col + j };
                    }
                }
                j = 0;
            }
            return null;
        }
    };
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

const ROCKS = RockSprite.parseMultiple(std.mem.count(u8, ROCKS_ASCII, "\n\n") + 1, ROCKS_ASCII) catch unreachable;

/// 1-indexed position on grid
const Pos = struct {
    row: usize,
    col: usize,

    fn shift(self: Pos, dir: Dir) ?Pos {
        return switch (dir) {
            .Down => if (self.row == 1) null else Pos{ .row = self.row - 1, .col = self.col },
            .Left => if (self.col == 1) null else Pos{ .col = self.col - 1, .row = self.row },
            .Right => if (self.col == WIDTH) null else Pos{ .col = self.col + 1, .row = self.row },
        };
    }
};

const Grid = struct {
    const Self = @This();
    const Row = std.bit_set.IntegerBitSet(WIDTH);
    grid: std.ArrayList(Row),

    fn new(allocator: std.mem.Allocator) !Self {
        var grid = try std.ArrayList(Row).initCapacity(allocator, 4096);
        return Self{ .grid = grid };
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        var i: usize = self.grid.items.len;
        while (i > 0) {
            i -= 1;
            const row: Row = self.grid.items[i];
            try writer.print("{d:2}:", .{i});

            try writer.writeAll("|");
            var j: usize = 0;
            while (j < WIDTH) : (j += 1) {
                const c: u8 = if (row.isSet(j)) '#' else '.';
                try writer.print("{c}", .{c});
            }
            try writer.writeAll("|\n");
        }
        try writer.writeAll("   +");
        const lines = [_]u8{'-'} ** WIDTH;
        try writer.print("{s}", .{lines});
        try writer.writeAll("+\n");
    }
    fn extendIfNeeded(self: *Self, maxRow: usize) !void {
        if (maxRow >= self.grid.items.len) {
            try self.grid.appendNTimes(Row.initEmpty(), maxRow - self.grid.items.len + 1);
        }
    }

    /// Place the rock on the grid given its top-left coordinates (1-indexed)
    fn put(self: *Self, rock: RockSprite, pos: Pos) !void {
        try self.extendIfNeeded(pos.row - 1);
        var i: u32 = 0;
        while (i < rock.height) : (i += 1) {
            var j: u32 = 0;
            while (j < RockSprite.W) : (j += 1) {
                std.debug.assert(pos.row - 1 >= i);
                var r: *Row = &self.grid.items[pos.row - 1 - i];
                if (rock.grid[i * RockSprite.W + j]) {
                    const index = j + pos.col - 1;
                    std.debug.assert(index < WIDTH);
                    std.debug.assert(!r.isSet(index));
                    r.set(index);
                }
            }
        }
    }
    fn isRockOrBoundary(self: Self, pos: Pos) bool {
        if (pos.row == 0 or pos.col == 0 or pos.col == WIDTH + 1) {
            return true;
        } else if (self.grid.items[pos.row - 1].isSet(pos.col - 1)) {
            return true;
        }
        return false;
    }
    fn canPut(self: *const Self, rock: *const RockSprite, pos: Pos) bool {
        var iter = RockSprite.RocksIter.init(rock, pos);
        while (iter.next()) |p| {
            // std.debug.print("p: {}\n", .{ p });
            if (self.isRockOrBoundary(p)) {
                return false;
            }
        }
        return true;
    }
    /// Assumes rock's pos is non-overlapping with anything in grid.
    fn canMove(self: *const Self, rock: *const RockSprite, pos: Pos, dir: Dir) ?Pos {
        if (pos.shift(dir)) |newPos| {
            if (self.canPut(rock, newPos)) {
                return newPos;
            }
        }
        return null;
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [24000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day17.txt");
    defer allocator.free(input);
    const inp = std.mem.trim(u8, input, "\n");
    const winds: []const Dir = @ptrCast([*]const Dir, inp.ptr)[0..inp.len];

    var grid = try Grid.new(allocator);

    const NUM_ROCKS: u32 = 2022;
    var numRocks: u32 = 0;
    var spriteIdx: usize = 0;
    var windIdx: usize = 0;
    var maxHeight: usize = 0;
    while (numRocks < NUM_ROCKS) : (numRocks += 1) {
        const rock = &ROCKS[spriteIdx];
        const nextRockRow = maxHeight + 3 + rock.height;
        const startPos = Pos{ .row = nextRockRow, .col = 3 };
        // std.debug.print("startPos: {}, spriteIdx {}\n", .{ startPos, spriteIdx });
        try grid.extendIfNeeded(nextRockRow);
        var pos = startPos;
        while (true) {
            var dir = winds[windIdx];
            windIdx += 1;
            windIdx %= winds.len;
            // std.debug.print("dir: {}\n", .{ dir });
            if (grid.canMove(rock, pos, dir)) |newPos| {
                pos = newPos;
                // std.debug.print("moved to: {}\n", .{pos});
            } else {
                // std.debug.print("could not move {}\n", .{ dir });
            }
            // fall down
            if (grid.canMove(rock, pos, Dir.Down)) |newPos| {
                pos = newPos;
                // std.debug.print("moved down to: {}\n", .{pos});
            } else {
                // std.debug.print("stopped at: {}\n", .{pos});
                maxHeight = std.math.max(maxHeight, pos.row);
                try grid.put(rock.*, pos);
                // std.debug.print("grid:\n{}\n", .{grid});
                break;
            }
        }
        spriteIdx += 1;
        spriteIdx %= ROCKS.len;
    }
    std.debug.print("height: {}\n", .{maxHeight});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day17_dummy.txt");
    defer allocator.free(input);
}
