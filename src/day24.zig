const std = @import("std");
const read_input = @import("input.zig").read_input;

const Dir = enum(u8) {
    n = '^',
    e = '>',
    s = 'v',
    w = '<',
    const all = [4]Dir{ .n, .e, .s, .w };
    fn opp(self: Dir) Dir {
        switch (self) {
            .n => .s,
            .s => .n,
            .e => .w,
            .w => .e,
        }
    }
    pub fn format(
        self: Dir,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{c}", .{@enumToInt(self)});
    }
};

const BST = std.bit_set.IntegerBitSet(4);
const Cell = packed struct(u4) {
    const Self = @This();
    n: bool,
    e: bool,
    s: bool,
    w: bool,

    fn count(self: Self) u3 {
        return @intCast(u3, @boolToInt(self.n)) + @intCast(u3, @boolToInt(self.e)) + @intCast(u3, @boolToInt(self.s)) + @intCast(u3, @boolToInt(self.w));
    }
    fn empty() Self {
        return Self{ .n = false, .e = false, .s = false, .w = false };
    }
    fn or_(self: *Self, other: Self) void {
        self.n |= other.n;
        self.e |= other.e;
        self.s |= other.s;
        self.w |= other.w;
    }
    fn contains(self: Self, dir: Dir) bool {
        return switch (dir) {
            .n => self.n,
            .e => self.e,
            .s => self.s,
            .w => self.w,
        };
    }
    fn set(self: *Self, dir: Dir) void {
        switch (dir) {
            .n => self.n = true,
            .e => self.e = true,
            .s => self.s = true,
            .w => self.w = true,
        }
    }
    fn fromDir(dir: Dir) Self {
        var cell = Self.empty();
        switch (dir) {
            .n => cell.n = true,
            .s => cell.s = true,
            .e => cell.e = true,
            .w => cell.w = true,
        }
        return cell;
    }
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        const n = self.count();
        if (n == 1) {
            try writer.print("{c}", .{if (self.n) Dir.n else if (self.e) Dir.e else if (self.w) Dir.w else Dir.s});
        } else if (n > 1) {
            try writer.print("{d}", .{n});
        } else {
            try writer.writeAll(".");
        }
    }
};

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
    fn neigh(self: Idx, dir: Dir) ?Idx {
        return switch (dir) {
            .n => self.add(-1, 0),
            .s => self.add(1, 0),
            .w => self.add(0, -1),
            .e => self.add(0, 1),
        };
    }
    pub fn format(
        self: Idx,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("({d},{d})", .{ self.i, self.j });
    }
};

const Grid = struct {
    const Self = @This();
    numRows: u32,
    numCols: u32,
    cells: []Cell,
    start: Idx,
    end: Idx,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !Self {
        const numCols = @intCast(u32, std.mem.indexOf(u8, input, "\n").?);
        const numRows = @intCast(u32, std.mem.count(u8, std.mem.trim(u8, input, "\n"), "\n") + 1);
        var cells = try allocator.alloc(Cell, numRows * numCols);
        std.mem.set(Cell, cells, Cell.empty());
        var start = Idx{ .i = 0, .j = 1 };
        var end = Idx{ .i = numRows - 1, .j = numCols - 2 };
        var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        var i: u32 = 0;
        while (lines.next()) |line| {
            for (line, 0..) |c, j| {
                switch (c) {
                    '.', '#' => continue,
                    else => cells[i * numCols + j] = Cell.fromDir(@intToEnum(Dir, c)),
                }
            }
            i += 1;
        }
        return Self{
            .numCols = numCols,
            .numRows = numRows,
            .cells = cells,
            .start = start,
            .end = end,
            .allocator = allocator,
        };
    }

    pub fn get(self: *Self, i: u32, j: u32) *Cell {
        return &self.cells[(i * self.numCols) + j];
    }
    pub fn getIdx(self: *Self, idx: Idx) *Cell {
        return self.get(idx.i, idx.j);
    }
    pub fn getval(self: *const Self, i: u32, j: u32) Cell {
        return self.cells[(i * self.numCols) + j];
    }
    pub fn getvalIdx(self: *const Self, idx: Idx) Cell {
        return self.getval(idx.i, idx.j);
    }

    fn getNextIdx(self: *const Self, idx: Idx, dir: Dir) Idx {
        var next = idx.neigh(dir).?;
        if (next.i == 0) {
            next.i == self.numRows - 2;
        } else if (next.i == self.numRows - 1) {
            next.i = 1;
        } else if (next.j == 0) {
            next.j == self.numCols - 2;
        } else if (next.j == self.numCols - 1) {
            next.j = 1;
        }
        return next;
    }

    fn isBoundary(self: *const Self, idx: Idx) bool {
        const i = idx.i;
        const j = idx.j;
        return i == 0 or i >= self.numRows - 1 or j == 0 or j >= self.numCols - 1;
    }

    /// Find the idx of cell approaching from `dir` that will be present at given `idx` after `time` turns.
    fn idxAfter(self: *const Self, idx: Idx, dir: Dir, time: u32) Idx {
        if (time == 0) {
            return idx;
        }
        var i = idx.i;
        var j = idx.j;
        const m = self.numCols - 2;
        const n = self.numRows - 2;
        std.debug.assert(i >= 1);
        std.debug.assert(j >= 1);
        std.debug.assert(m > 0);
        std.debug.assert(n > 0);
        switch (dir) {
            .n => {
                // -1, +1 are needed to account for the walls
                return Idx{ .i = (i - 1 + (time % n)) % n + 1, .j = j };
            },
            .w => {
                return Idx{ .j = (j - 1 + (time % m)) % m + 1, .i = i };
            },
            .s => {
                // there is probably a simpler way to do this...
                if (i > time) {
                    return Idx{ .i = i - time, .j = j };
                } else if (i == time) {
                    return Idx{ .i = n, .j = j };
                }
                var t = -@intCast(i32, time - (i - 1));
                // +1 to account for the top wall
                return Idx{ .i = @intCast(u32, @mod(t, @intCast(i32, n))) + 1, .j = j };
            },
            .e => {
                if (j > time) {
                    return Idx{ .i = i, .j = j - time };
                } else if (j == time) {
                    return Idx{ .i = i, .j = m };
                }
                var t = -@intCast(i32, time - (j - 1));
                return Idx{ .i = i, .j = @intCast(u32, @mod(t, @intCast(i32, m))) + 1 };
            },
        }
    }
    /// Get the cell contents at `idx` after `time` turns.
    fn valAfter(self: *const Self, idx: Idx, time: u32) Cell {
        if (time == 0) {
            return self.getvalIdx(idx);
        }
        var cell = Cell.empty();
        inline for (Dir.all) |dir| {
            const skipIdx = self.idxAfter(idx, dir, time);
            const v = self.getvalIdx(skipIdx);
            if (v.contains(dir)) {
                cell.set(dir);
            }
        }
        return cell;
    }

    /// Returns true if `idx` does not have any blizzards in the next turn.
    fn nextSafe(self: *const Self, idx: Idx) bool {
        inline for (Dir.all) |dir| {
            var nextIdx = self.getNextIdx(idx, dir);
            if (!self.getvalIdx(nextIdx).contains(dir.opp())) {
                return false;
            }
        }
        return true;
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        // HACK: We interpret the precision field as the time value
        const time = if (options.precision) |t| @intCast(u32, t) else 0;
        for (0..self.numRows) |i_| {
            var i = @intCast(u32, i_);
            for (0..self.numCols) |j_| {
                var j = @intCast(u32, j_);
                if ((i == self.start.i and j == self.start.j) or (i == self.end.i and j == self.end.j)) {
                    try writer.writeAll(".");
                } else if (self.isBoundary(Idx{ .i = i, .j = j })) {
                    try writer.writeAll("#");
                } else {
                    try writer.print("{c}", .{self.valAfter(Idx{ .i = i, .j = j }, time)});
                }
                if (j < self.numCols - 1) {} else {
                    try writer.writeAll("\n");
                }
            }
        }
    }
    fn addNextPos(self: *const Self, pos: Pos, nextPos: *PosSet, goal: Idx) !void {
        // std.debug.print("Adding next poses for {any}\n", .{pos});
        for (Dir.all) |dir| {
            const nextIdx = if (pos.idx.neigh(dir)) |n| n else continue;
            // std.debug.print("\tTesting nextIdx {}\n", .{nextIdx});
            if (nextIdx.i == goal.i and nextIdx.j == goal.j) {
                std.debug.print("Goal {} in time {}\n", .{ goal, pos.time + 1 });
                try nextPos.put(nextIdx, {});
                return;
            }
            if (self.isBoundary(nextIdx)) {
                continue;
            }
            const nextVal = self.valAfter(nextIdx, pos.time + 1);
            // std.debug.print("\t\tnot boundary, val {}\n", .{nextVal});
            if (nextVal.count() == 0) {
                try nextPos.put(nextIdx, {});
            }
        }
    }
};
const Pos = struct {
    time: u32,
    idx: Idx,
    // comptime compareFn: fn(context:Context, a:T, b:T)Order
    fn compareFn(context: void, a: Pos, b: Pos) std.math.Order {
        _ = context;
        return std.math.order(a.time, b.time);
    }
};
const PosSet = std.AutoHashMap(Idx, void);

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day24.txt");
    defer allocator.free(input);
    var grid = try Grid.init(allocator, input);
    std.debug.print("grid at t=0:\n{}\n", .{grid});
    std.debug.print("grid at t=1:\n{:.1}\n", .{grid});
    std.debug.print("grid at t=2:\n{:.2}\n", .{grid});

    // Do BFS
    var curPos = PosSet.init(allocator);
    try curPos.put(grid.start, {});
    var nextPos = std.AutoHashMap(Idx, void).init(allocator);
    var time: u32 = 0;
    while (true) {
        var it = curPos.keyIterator();
        while (it.next()) |idx| {
            if (idx.i == grid.end.i) {
                // Reached!
                std.debug.print("Time taken {}\n", .{time});
                return;
            }
            try grid.addNextPos(Pos{ .idx = idx.*, .time = time }, &nextPos, grid.end);
            if (idx.i == 0 or grid.valAfter(idx.*, time + 1).count() == 0) {
                // if we can stay here, add it
                try nextPos.put(idx.*, {});
            }
        }
        curPos.clearRetainingCapacity();
        std.mem.swap(PosSet, &curPos, &nextPos);
        time += 1;
    }
    // std.debug.print("END {}!\n", .{maxTime});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day24.txt");
    defer allocator.free(input);
    var grid = try Grid.init(allocator, input);
    std.debug.print("grid at t=0:\n{}\n", .{grid});

    // Do BFS
    var curPos = PosSet.init(allocator);
    try curPos.put(grid.start, {});
    var nextPos = std.AutoHashMap(Idx, void).init(allocator);
    var time: u32 = 0;
    var goals = [_]Idx{ grid.end, grid.start, grid.end };
    var curGoalIdx: usize = 0;
    var curGoal = goals[curGoalIdx];
    while (true) {
        var it = curPos.keyIterator();
        while (it.next()) |idx| {
            if (idx.i == curGoal.i) {
                // Reached!
                std.debug.print("Time taken {}\n", .{time});
                if (curGoalIdx < 2) {
                    curGoalIdx += 1;
                    curGoal = goals[curGoalIdx];
                    // nextPos will be swapped with curPos
                    // when we break
                    nextPos.clearRetainingCapacity();
                    try nextPos.put(idx.*, {});
                    // undo the time += 1 that is done later
                    time -= 1;
                    break;
                } else {
                    return;
                }
            }
            try grid.addNextPos(Pos{ .idx = idx.*, .time = time }, &nextPos, curGoal);
            if (idx.i == 0 or idx.i == grid.end.i or grid.valAfter(idx.*, time + 1).count() == 0) {
                // if we can stay here, add it
                try nextPos.put(idx.*, {});
            }
        }
        curPos.clearRetainingCapacity();
        std.mem.swap(PosSet, &curPos, &nextPos);
        time += 1;
    }
}
