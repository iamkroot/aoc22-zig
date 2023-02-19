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

const Cell = enum {
    /// Cannot land on it
    vacuum,
    /// empty cell
    empty,
    /// Obstacle
    rock,

    fn fromCh(ch: u8) Cell {
        return switch (ch) {
            ' ' => .vacuum,
            '.' => .empty,
            '#' => .rock,
            else => unreachable,
        };
    }
    pub fn format(
        self: Cell,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{c}", .{switch (self) {
            .vacuum => @as(u8, ' '),
            .empty => '.',
            .rock => '#',
        }});
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
                    if (start == null and cell != .vacuum) {
                        start = Idx{ .i = i, .j = j };
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
                // .end = end,
                .allocator = allocator,
            };
        }

        fn initSingle(allocator: std.mem.Allocator, mainGrid: anytype, val: T) !Self {
            var nums = try allocator.alloc(T, mainGrid.numRows * mainGrid.numCols);
            std.mem.set(T, nums, val);
            return Self{
                .numRows = mainGrid.numRows,
                .numCols = mainGrid.numCols,
                .start = mainGrid.start,
                .end = mainGrid.end,
                .nums = nums,
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
    };
}

const InputGrid = Grid(Cell, "{any}");

const Turn = enum {
    cw,
    ccw,
    fn fromCh(ch: u8) Turn {
        return switch (ch) {
            'R' => .cw,
            'L' => .ccw,
            else => unreachable,
        };
    }
    pub fn format(
        self: Turn,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{c}", .{switch (self) {
            .cw => @as(u8, 'R'),
            .ccw => 'L',
        }});
    }
};

const Facing = enum {
    left,
    right,
    up,
    down,
    fn fromCh(ch: u8) Facing {
        return switch (ch) {
            '<' => .left,
            '>' => .right,
            '^' => .up,
            'v' => .down,
            else => unreachable,
        };
    }
    pub fn format(
        self: Facing,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{c}", .{switch (self) {
            .left => '<',
            .right => '>',
            .up => '^',
            .down => 'v',
        }});
    }
};

const MoveT = enum { forward, turn };

const Move = union(MoveT) {
    forward: u32,
    turn: Turn,
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
        var moves = try allocator.alloc(Move, 2 * n - 1);
        var i: usize = 0;
        d = 0;
        moves[i] = Move{ .forward = @intCast(u32, parseIntChomp(input, &d)) };
        i += 1;
        while (i < 2 * n - 1) {
            moves[i] = Move{ .turn = Turn.fromCh(input[d]) };
            d += 1;
            moves[i + 1] = Move{ .forward = @intCast(u32, parseIntChomp(input, &d)) };
            i += 2;
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
        switch (self) {
            .forward => |val| try writer.print("{d}", .{val}),
            .turn => |val| try writer.print("{any}", .{val}),
        }
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day22_dummy.txt");
    defer allocator.free(input);
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
    std.debug.print("numCols, numRows: {} {}\n", .{ numCols, numRows });
    var grid = try InputGrid.parse(allocator, @intCast(u32, numCols), @intCast(u32, numRows), gridInp);
    std.debug.print("grid:\n{any}\n", .{grid});
    var moveInp = parts.next().?;
    const moves = try Move.parse(allocator, moveInp);
    std.debug.print("moves: {any}\n", .{moves});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day22_dummy.txt");
    defer allocator.free(input);
}
