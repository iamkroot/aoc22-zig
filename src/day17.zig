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
    grid: std.AutoHashMap(usize, Row),
    baseRowIdx: usize = 0,
    /// current height of each column
    ceiling: [WIDTH]usize = [_]usize{0} ** WIDTH,

    fn new(allocator: std.mem.Allocator) !Self {
        var grid = std.AutoHashMap(usize, Row).init(allocator);
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
        _ = self;
        try writer.writeAll("   +");
        const lines = [_]u8{'-'} ** WIDTH;
        try writer.print("{s}", .{lines});
        try writer.writeAll("+\n");
    }

    const MAX_NUM_ROWS: usize = 102400;

    /// Place the rock on the grid given its top-left coordinates (1-indexed)
    fn put(self: *Self, rock: RockSprite, pos: Pos) !void {
        var i: u32 = 0;
        while (i < rock.height) : (i += 1) {
            var j: u32 = 0;
            while (j < RockSprite.W) : (j += 1) {
                std.debug.assert(pos.row - 1 >= i);
                const rowIdx = pos.row - 1 - i;
                var r: *Row = (try self.grid.getOrPutValue(rowIdx, Row.initEmpty())).value_ptr;
                if (rock.grid[i * RockSprite.W + j]) {
                    const index = j + pos.col - 1;
                    std.debug.assert(index < WIDTH);
                    std.debug.assert(!r.isSet(index));
                    r.set(index);
                    self.ceiling[index] = std.math.max(self.ceiling[index], rowIdx + 1);
                }
            }
        }
    }
    fn isRockOrBoundary(self: Self, pos: Pos) bool {
        if (pos.row == 0 or pos.col == 0 or pos.col == WIDTH + 1) {
            return true;
        } 
        if (self.grid.get(pos.row - 1))|row| {
            return row.isSet(pos.col - 1);
        }
        return false;
    }
    fn canPut(self: *const Self, rock: *const RockSprite, pos: Pos) bool {
        var iter = RockSprite.RocksIter.init(rock, pos);
        while (iter.next()) |p| {
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
    fn ceilNorm(self: Self) [WIDTH]usize {
        var ceilMin = self.ceiling[0];
        for (self.ceiling[1..]) |v| {
            ceilMin = std.math.min(ceilMin, v);
        }
        var minCeil = self.ceiling;
        for (&minCeil) |*v| {
            v.* -= ceilMin;
        }
        return minCeil;
    }
};

fn rocksFall(allocator: std.mem.Allocator, winds: []const Dir, target_num_rocks: usize) !void {
    var grid = try Grid.new(allocator);

    var numRocks: usize = 0;
    var windIdx: usize = 0;
    var curHeight: usize = 0;
    const Key = struct {
        ceiling: [WIDTH]usize,
        spriteIdx: usize,
        windIdx: usize,
    };
    const Val = struct { rocks: usize, height: usize };

    var memo = std.AutoHashMap(Key, Val).init(allocator);
    var found: bool = false;
    defer memo.deinit();
    var ceils = std.AutoHashMap([WIDTH]usize, [WIDTH]usize).init(allocator);
    defer ceils.deinit();
    while (numRocks < target_num_rocks) : (numRocks += 1) {
        const spriteIdx = numRocks % ROCKS.len;
        const rock = &ROCKS[spriteIdx];
        const nextRockRow = curHeight + 3 + rock.height;
        const startPos = Pos{ .row = nextRockRow, .col = 3 };
        var pos = startPos;
        while (true) {
            var dir = winds[windIdx];
            windIdx += 1;
            windIdx %= winds.len;

            if (grid.canMove(rock, pos, dir)) |newPos| {
                pos = newPos;
            }
            // fall down
            if (grid.canMove(rock, pos, Dir.Down)) |newPos| {
                pos = newPos;
            } else {
                curHeight = std.math.max(curHeight, pos.row);
                try grid.put(rock.*, pos);
                if (!found and spriteIdx == 0) {
                    const minCeil = grid.ceilNorm();
                    {
                        const r = try memo.getOrPut(Key{ .ceiling = minCeil, .spriteIdx = 0, .windIdx = windIdx });
                        if (r.found_existing) {
                            found = true;
                            const cycleRepeat = numRocks - r.value_ptr.rocks;
                            const cycleHeight = curHeight - r.value_ptr.height;
                            const numRemainingRocks = target_num_rocks - numRocks;
                            const numRemainingCycles = numRemainingRocks / cycleRepeat;
                            const jumpHeight = numRemainingCycles * cycleHeight;
                            const jumpRocks = numRemainingCycles * cycleRepeat;
                            numRocks += jumpRocks;
                            const oldHeight = curHeight;
                            curHeight += jumpHeight;
                            // copy over the last few rows
                            for (0..31) |i| {
                                try grid.grid.put(curHeight - 30 + i, if (grid.grid.get(oldHeight - 30 + i)) |row| row else Grid.Row.initEmpty());
                            }
                            r.value_ptr.rocks = numRocks;
                            r.value_ptr.height = curHeight;
                        } else {
                            r.value_ptr.rocks = numRocks;
                            r.value_ptr.height = curHeight;
                        }
                    }
                }

                break;
            }
        }
    }
    std.debug.print("target: {} height: {}\n", .{ target_num_rocks, curHeight });
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [240000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day17.txt");
    defer allocator.free(input);
    const inp = std.mem.trim(u8, input, "\n");
    const winds: []const Dir = @ptrCast([*]const Dir, inp.ptr)[0..inp.len];
    try rocksFall(allocator, winds, 2022);
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [2400000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day17.txt");
    defer allocator.free(input);
    const inp = std.mem.trim(u8, input, "\n");
    const winds: []const Dir = @ptrCast([*]const Dir, inp.ptr)[0..inp.len];

    try rocksFall(allocator, winds, 1_000_000_000_000);
}
