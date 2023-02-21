const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;
const Allocator = std.mem.Allocator;

const Idx = struct {
    i: u32,
    j: u32,

    fn add(self: Idx, i: i32, j: i32) ?Idx {
        return Idx{
            .i = if (i < 0 and self.i < std.math.absCast(i))
                return null
            else
                @intCast(u32, @intCast(i32, self.i) + i),
            .j = if (j < 0 and self.j < std.math.absCast(j))
                return null
            else
                @intCast(u32, @intCast(i32, self.j) + j),
        };
    }
};

const Cell = enum(u8) {
    const Self = @This();
    /// Cannot land on it
    vacuum = ' ',
    /// empty cell
    empty = '.',
    /// Obstacle
    rock = '#',
    left = '<',
    right = '>',
    up = '^',
    down = 'v',

    fn fromCh(ch: u8) Self {
        return @intToEnum(Self, ch);
    }
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{c}", .{@enumToInt(self)});
    }
    fn facing(self: Self) Facing {
        return @intToEnum(Facing, @enumToInt(self));
    }
};

pub fn Grid(comptime T: type, comptime fmtEl: []const u8) type {
    return struct {
        const Self = @This();
        numRows: u32,
        numCols: u32,
        nums: []T,
        start: Idx,
        // end: Idx,
        allocator: std.mem.Allocator,

        pub fn parse(allocator: std.mem.Allocator, numCols: u32, numRows: u32, input: []const u8) !Self {
            var nums = try allocator.alloc(T, numRows * numCols);
            var j: u32 = 0;
            var i: u32 = 0;
            var start: ?Idx = null;
            for (input) |c| {
                if (c != '\n') {
                    const cell = Cell.fromCh(c);
                    nums[i * numCols + j] = cell;
                    if (start == null and cell == .empty) {
                        start = Idx{ .i = i, .j = j };
                        // we will implicitly do a cw turn at the start
                        nums[i * numCols + j] = Cell.up;
                    }
                    j += 1;
                } else {
                    while (j < numCols) : (j += 1) {
                        nums[i * numCols + j] = .vacuum;
                    }
                    j = 0;
                    i += 1;
                }
            }
            return Self{
                .numCols = numCols,
                .numRows = numRows,
                .nums = nums,
                .start = start.?,
                .allocator = allocator,
            };
        }

        pub fn get(self: *Self, i: u32, j: u32) *T {
            return &self.nums[(i * self.numCols) + j];
        }
        pub fn getIdx(self: *Self, idx: Idx) *T {
            return self.get(idx.i, idx.j);
        }
        pub fn getval(self: *const Self, i: u32, j: u32) T {
            return self.nums[(i * self.numCols) + j];
        }
        pub fn getvalIdx(self: *const Self, idx: Idx) T {
            return self.getval(idx.i, idx.j);
        }

        pub fn format(
            self: Self,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try writer.print("start: {}\n", .{self.start});
            const m = self.numRows;
            const n = self.numCols;
            var i: u32 = 0;
            while (i < m) : (i += 1) {
                var j: u32 = 0;
                while (j < n) : (j += 1) {
                    try writer.print(fmtEl, .{self.getval(i, j)});
                    if (j < n - 1) {} else {
                        try writer.writeAll("\n");
                    }
                }
            }
        }

        fn getNext(self: *Self, facing: Facing, idx: Idx) Idx {
            var i = idx.i;
            var j = idx.j;
            var newi = i;
            var newj = j;
            switch (facing) {
                .down => newi = if (i + 1 == self.numRows) 0 else i + 1,
                .up => newi = if (i == 0) self.numRows - 1 else i - 1,
                .right => newj = if (j + 1 == self.numCols) 0 else j + 1,
                .left => newj = if (j == 0) self.numCols - 1 else j - 1,
            }
            return Idx{ .i = newi, .j = newj };
        }

        fn getNext2(self: *Self, facing: Facing) Idx {
            if (T == Cell) {
                var nextIdx = self.getNext(facing, self.start);
                var nextVal = self.getvalIdx(nextIdx);
                while (nextVal == .vacuum) {
                    nextIdx = self.getNext(facing, nextIdx);
                    nextVal = self.getvalIdx(nextIdx);
                }
                return nextIdx;
            }
        }

        fn makeMove(self: *Self, move: Move) void {
            var amt: i32 = @intCast(i32, move.forward);
            var curCell = self.getIdx(self.start);
            // std.debug.print("start : {any} {any}\n", .{ self.start, curCell.* });

            var curFacing = @intToEnum(Facing, @enumToInt(curCell.*));
            const facing = curFacing.makeTurn(move.dir);
            // std.debug.print("facings: {any} {any}\n", .{ curFacing, facing });

            curCell.* = @intToEnum(T, @enumToInt(facing));
            var i: i32 = 0;
            while (i < amt) : (i += 1) {
                const nextIdx = self.getNext2(facing);
                var nextCell = self.getIdx(nextIdx);
                // std.debug.print("step : {any} {any}\n", .{ nextIdx, nextCell.* });

                if (nextCell.* == .rock) {
                    break;
                }
                self.start.i = nextIdx.i;
                self.start.j = nextIdx.j;
                nextCell.* = @intToEnum(T, @enumToInt(facing));
            }
            // std.debug.print("final idx: {any}\n", .{ self.start });
        }
    };
}

const InputGrid = Grid(Cell, "{any}");

const Turn = enum(u8) {
    const Self = @This();
    cw = 'R',
    ccw = 'L',

    fn fromCh(ch: u8) Self {
        return @intToEnum(Self, ch);
    }
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{c}", .{@enumToInt(self)});
    }
};

const Facing = enum(u8) {
    const Self = @This();
    left = '<',
    right = '>',
    up = '^',
    down = 'v',

    fn fromCh(ch: u8) Self {
        return @intToEnum(Self, ch);
    }
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{c}", .{@enumToInt(self)});
    }
    fn makeTurn(self: Self, turn: Turn) Self {
        return switch (turn) {
            .cw => switch (self) {
                .down => @as(Self, .left),
                .up => .right,
                .left => .up,
                .right => .down,
            },
            .ccw => switch (self) {
                .up => .left,
                .down => .right,
                .right => .up,
                .left => .down,
            },
        };
    }
    fn score(self: Self) u32 {
        return switch (self) {
            .right => 0,
            .down => 1,
            .left => 2,
            .up => 3,
        };
    }
};

const MoveT = enum { forward, turn };

const Move = struct {
    const Self = @This();
    forward: u32,
    dir: Turn,
    fn parse(allocator: Allocator, input: []const u8) ![]Move {
        var d: usize = 0;
        // first count the number of moves
        var n: usize = 0;
        while (true) {
            n += 1;
            _ = parseIntChomp(input, &d);
            if (d >= input.len) {
                break;
            }
            d += 1;
        }
        var moves = try allocator.alloc(Move, n);
        var i: usize = 0;
        d = 0;
        moves[0] = Move{ .dir = .cw, .forward = @intCast(u32, parseIntChomp(input, &d)) };
        i += 1;
        while (i < n) : (i += 1) {
            const turn = Turn.fromCh(input[d]);
            d += 1;
            moves[i] = Move{ .dir = turn, .forward = @intCast(u32, parseIntChomp(input, &d)) };
        }
        return moves;
    }

    pub fn format(
        self: Move,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{c}{d}", .{ self.dir, self.forward });
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !std.meta.Tuple(&[_]type{ InputGrid, []const Move }) {
    var parts = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n\n");
    var gridInp = parts.next().?;
    var numRows = std.mem.count(u8, std.mem.trim(u8, gridInp, "\n"), "\n") + 1;
    var numCols = brk: {
        var numCols: u32 = 0;
        var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        while (lines.next()) |line| {
            numCols = @max(numCols, @intCast(u32, line.len));
        }
        break :brk numCols;
    };
    var grid = try InputGrid.parse(allocator, @intCast(u32, numCols), @intCast(u32, numRows), gridInp);
    var moveInp = parts.next().?;
    const moves = try Move.parse(allocator, moveInp);
    return .{ grid, moves };
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [1400000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day22.txt");
    defer allocator.free(input);
    var inp = try parseInput(allocator, input);
    var grid = inp[0];
    var moves = inp[1];
    // std.debug.print("moves: {any}\n", .{moves});
    for (moves) |move| {
        grid.makeMove(move);
        // std.debug.print("grid:\n{any}\n", .{grid});
    } 
    const score = (grid.start.i + 1) * 1000 + (grid.start.j + 1) * 4 + grid.getvalIdx(grid.start).facing().score();
    std.debug.print("score: {}\n", .{ score });
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day22_dummy.txt");
    defer allocator.free(input);
}
