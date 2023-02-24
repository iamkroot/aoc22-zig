const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;
const Queue = @import("utils.zig").Queue;
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

const Cube = struct {
    const Self = @This();
    const Neighs = std.AutoArrayHashMap(Facing, usize);
    const Face = struct {
        id: usize,
        neighs: Neighs,
        top_left: Idx,
        side: u32,
        fn contains(self: *const Face, idx: Idx) bool {
            return self.top_left.i <= idx.i and self.top_left.j <= idx.j and idx.i < (self.top_left.i + self.side) and idx.j < (self.top_left.j + self.side);
        }
        /// Given the id of a neighbour, find the boundary of self at which it is connected.
        /// it should be possible to store this value inside neighs field instead of computing it here
        fn reverseLookup(self: *const Face, id: usize) Facing {
            for (Facing.allDirsCCW) |d| {
                if (self.neighs.get(d)) |f| {
                    if (f == id) {
                        return d;
                    }
                }
            }
            unreachable();
        }
        pub fn format(
            self: Face,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try writer.print("face {}: {any}\n", .{ self.id + 1, self.top_left });
            for (Facing.allDirsCCW) |dir| {
                try writer.print("\t{any}: ", .{dir});
                if (self.neighs.get(dir)) |n| {
                    try writer.print("{}\n", .{n + 1});
                } else {
                    try writer.writeAll("none\n");
                }
            }
        }
    };
    side: u32,
    faces: [6]Face,
    fn fromgrid(allocator: Allocator, side: u32, grid: *const InputGrid) !Self {
        var faces: [6]Face = .{};
        for (faces) |*face, i| {
            face.* = Face{ .id = i, .neighs = Neighs.init(allocator), .top_left = undefined, .side = side };
            try face.neighs.ensureTotalCapacity(4);
        }
        // var curFace: ?*Face = null;
        var faceId: usize = 0;
        var i: u32 = 0;
        // we assume that the input grid is "tight" - it is the smallest bounding box of the 2D faces
        // the faces can thus only start at cells that are at multiples of `side`
        while (i < grid.numRows) : (i += side) {
            var j: u32 = 0;
            while (j < grid.numCols) : (j += side) {
                const pos = Idx{ .i = i, .j = j };
                if (grid.getvalIdx(pos) != .vacuum) {
                    // start new face
                    faces[faceId].top_left = pos;
                    if (pos.add(-1, 0)) |neighPos| {
                        for (faces[0..faceId]) |*neighFace| {
                            if (neighFace.contains(neighPos)) {
                                // found a neighbour!
                                faces[faceId].neighs.putAssumeCapacity(Facing.up, neighFace.id);
                                neighFace.neighs.putAssumeCapacity(Facing.down, faceId);
                                break;
                            }
                        }
                    }
                    if (pos.add(0, -1)) |neighPos| {
                        for (faces[0..faceId]) |*neighFace| {
                            if (neighFace.contains(neighPos)) {
                                // found a neighbour!
                                faces[faceId].neighs.putAssumeCapacity(Facing.left, neighFace.id);
                                neighFace.neighs.putAssumeCapacity(Facing.right, faceId);
                                break;
                            }
                        }
                    }
                    faceId += 1;
                }
            }
        }
        var cube = Self{ .faces = faces, .side = side };
        std.debug.print("initial cube: {any}\n", .{cube});
        try cube.fillAllNeighs(allocator);
        return cube;
    }
    // fill the remaining slots in "neighs" field for each face.
    // In essence, reconstruct the 3D cube from the 2D layout.
    fn fillAllNeighs(self: *Self, allocator: Allocator) !void {
        var q = Queue(usize).init(allocator);
        for (self.faces) |face| {
            if (face.neighs.count() < 2) {
                // too little info, skip this for now
                continue;
            }
            try q.enqueue(face.id);
        }
        var processed = std.AutoHashMap([3]usize, void).init(allocator);
        while (q.dequeue()) |faceId| {
            var face = &self.faces[faceId];
            var maybeNeighs: [4]?*Face = .{};
            for (Facing.allDirsCCW) |dir, i| {
                maybeNeighs[i] = if (face.neighs.get(dir)) |id| &self.faces[id] else null;
            }
            var i: usize = 0;
            while (i < 4) : (i += 1) {
                if (maybeNeighs[i]) |n1| {
                    if (maybeNeighs[(i + 1) % 4]) |n2| {
                        const key = [3]usize{ faceId, n1.id, n2.id };
                        var gp = try processed.getOrPut(key);
                        if (gp.found_existing) {
                            continue;
                        }
                        std.debug.print("processing: {any}\n", .{key});
                        // find the borders of n1 and n2 that are connected to face
                        const revDir1 = n1.reverseLookup(faceId);
                        const revDir2 = n2.reverseLookup(faceId);
                        const border1 = revDir1.makeTurn(.cw);
                        const border2 = revDir2.makeTurn(.ccw);
                        n1.neighs.putAssumeCapacity(border1, n2.id);
                        n2.neighs.putAssumeCapacity(border2, n1.id);
                        try q.enqueue(n1.id);
                    }
                }
            }
        }
    }
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Side: {}\n", .{self.side});
        for (self.faces) |face| {
            try writer.print("{any}\n", .{face});
        }
    }
};

const State = struct {
    facing: Facing,
    idx: Idx,
    fn score(self: State) u32 {
        return (self.idx.i + 1) * 1000 + (self.idx.j + 1) * 4 + self.facing.score();
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
    // will be used for drawing the traversed path
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
        cur: State,
        curFace: usize = 0,
        allocator: std.mem.Allocator,
        cube: ?Cube,

        pub fn parse(allocator: std.mem.Allocator, numCols: u32, numRows: u32, input: []const u8, ispart2: bool) !Self {
            var nums = try allocator.alloc(T, numRows * numCols);
            var j: u32 = 0;
            var i: u32 = 0;
            var start: ?Idx = null;
            // used to calculate the cubeSide
            var surfaceArea: u32 = 0;
            for (input) |c| {
                if (c != '\n') {
                    const cell = Cell.fromCh(c);
                    if (cell != .vacuum) {
                        surfaceArea += 1;
                    }
                    nums[i * numCols + j] = cell;
                    if (start == null and cell == .empty) {
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
            while (j < numCols) : (j += 1) {
                nums[i * numCols + j] = .vacuum;
            }
            var grid = Self{
                .numCols = numCols,
                .numRows = numRows,
                .nums = nums,
                .cur = State{ .idx = start.?, .facing = Facing.up },
                .allocator = allocator,
                .cube = null,
            };
            if (ispart2) {
                grid.cube = try Cube.fromgrid(allocator, std.math.sqrt(surfaceArea / 6), &grid);
            }
            return grid;
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
            try writer.print("cur: {any}\n", .{self.cur});
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

        fn getNextStraight(self: *const Self, facing: Facing, idx: Idx) Idx {
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
        fn getNextNoWarpStraight(self: *const Self, facing: Facing, idx: Idx) ?Idx {
            var i = idx.i;
            var j = idx.j;
            var newi = i;
            var newj = j;
            switch (facing) {
                .down => newi = if (i + 1 == self.numRows) return null else i + 1,
                .up => newi = if (i == 0) return null else i - 1,
                .right => newj = if (j + 1 == self.numCols) return null else j + 1,
                .left => newj = if (j == 0) return null else j - 1,
            }
            return Idx{ .i = newi, .j = newj };
        }
        fn getNextOnCube(self: *Self, cur: State) State {
            const cube = &self.cube.?;
            const curFace = &cube.faces[self.curFace];
            if (self.getNextNoWarpStraight(cur.facing, cur.idx)) |nextIdx| {
                if (curFace.contains(nextIdx)) {
                    return State{ .idx = nextIdx, .facing = cur.facing };
                }
            }
            // change face
            const nextFaceId = curFace.neighs.get(cur.facing).?;
            // std.debug.print("{} nextFaceId: {}\n", .{ curFace.id + 1,  nextFaceId + 1 });
            const nextFace = &cube.faces[nextFaceId];
            self.curFace = nextFaceId;
            const i = cur.idx.i;
            const j = cur.idx.j;
            const cubeX = j % cube.side;
            const cubeY = i % cube.side;
            // if on the vertical borders, use i, else use j
            const cubeDelta = if (cur.facing == .left or cur.facing == .right) cubeY else cubeX;
            const newBorder = nextFace.reverseLookup(curFace.id);
            // These are the only cases when the cubeDelta needs to be negated
            const isFlipped = (newBorder == cur.facing) or (newBorder == .left and cur.facing == .down) or (newBorder == .down and cur.facing == .left) or (newBorder == .right and cur.facing == .up) or (newBorder == .up and cur.facing == .right);
            const newFacing = newBorder.makeTurn(.cw).makeTurn(.cw);
            var newi = nextFace.top_left.i;
            var newj = nextFace.top_left.j;
            // std.debug.print("newi, newj: {} {} {}\n", .{ newi, newj, cubeDelta });
            if (newBorder == .right or newBorder == .left) {
                if (newBorder == .right) {
                    newj += cube.side - 1;
                }
                newi += if (isFlipped) (cube.side - cubeDelta) - 1 else cubeDelta;
            }
            if (newBorder == .down or newBorder == .up) {
                if (newBorder == .down) {
                    newi += cube.side - 1;
                }
                newj += if (isFlipped) (cube.side - cubeDelta) - 1 else cubeDelta;
            }
            return State{ .facing = newFacing, .idx = Idx{ .i = newi, .j = newj } };
        }

        fn getNext2(self: *Self, cur: State) State {
            if (self.cube != null) {
                return self.getNextOnCube(cur);
            } else {
                var nextIdx = self.getNextStraight(cur.facing, cur.idx);
                if (self.getvalIdx(nextIdx) != .vacuum) {
                    return State{ .idx = nextIdx, .facing = cur.facing };
                }
                while (self.getvalIdx(nextIdx) == .vacuum) {
                    nextIdx = self.getNextStraight(cur.facing, nextIdx);
                }
                return State{ .idx = nextIdx, .facing = cur.facing };
            }
        }

        fn makeMove(self: *Self, move: Move) void {
            var amt: i32 = @intCast(i32, move.amount);
            std.debug.print("amt: {}\n", .{amt});
            var facing = self.cur.facing.makeTurn(move.dir);
            self.cur.facing = facing; // update the facing
            var curCell = self.getIdx(self.cur.idx);
            // update the path
            curCell.* = @intToEnum(T, @enumToInt(facing));
            var i: i32 = 0;
            while (i < amt) : (i += 1) {
                const curFaceId = self.curFace;
                const nextState = self.getNext2(self.cur);
                var nextCell = self.getIdx(nextState.idx);
                // std.debug.print("step : {any} {any}\n", .{ nextIdx, nextCell.* });

                if (nextCell.* == .rock) {
                    // We _really_ ought to store curFace inside State...
                    self.curFace = curFaceId;
                    break;
                }
                self.cur = nextState;
                nextCell.* = @intToEnum(T, @enumToInt(self.cur.facing));
            }
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
    const allDirsCCW = [4]Facing{ .up, .left, .down, .right };

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

const MoveT = enum { amount, turn };

const Move = struct {
    const Self = @This();
    amount: u32,
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
        moves[0] = Move{ .dir = .cw, .amount = @intCast(u32, parseIntChomp(input, &d)) };
        i += 1;
        while (i < n) : (i += 1) {
            const turn = Turn.fromCh(input[d]);
            d += 1;
            moves[i] = Move{ .dir = turn, .amount = @intCast(u32, parseIntChomp(input, &d)) };
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
        try writer.print("{c}{d}", .{ self.dir, self.amount });
    }
};

fn parseInput(allocator: Allocator, input: []const u8, ispart2: bool) !std.meta.Tuple(&[_]type{ InputGrid, []const Move }) {
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
    var grid = try InputGrid.parse(allocator, @intCast(u32, numCols), @intCast(u32, numRows), gridInp, ispart2);
    var moveInp = parts.next().?;
    const moves = try Move.parse(allocator, moveInp);
    return .{ grid, moves };
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [1400000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day22_dummy.txt");
    defer allocator.free(input);
    var inp = try parseInput(allocator, input, false);
    var grid = inp[0];
    var moves = inp[1];
    // std.debug.print("moves: {any}\n", .{moves});
    for (moves) |move| {
        grid.makeMove(move);
        // std.debug.print("grid:\n{any}\n", .{grid});
    }
    const score = grid.cur.score();
    std.debug.print("score: {}\n", .{score});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [1400000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day22.txt");
    defer allocator.free(input);
    var inp = try parseInput(allocator, input, true);
    var grid = inp[0];
    std.debug.print("grid:\n{any}\n", .{grid});
    std.debug.print("cube:\n{any}\n", .{grid.cube.?});
    // std.debug.print("warped: {any}\n", .{ grid.getNextWarped2(State{.facing=.right, .idx =Idx{.i = 2, .j = 11}})});
    var moves = inp[1];
    // std.debug.print("moves: {any}\n", .{moves});
    for (moves) |move| {
        grid.makeMove(move);
        // std.debug.print("grid:\n{any}\n", .{grid});
    }

    const score = grid.cur.score();

    std.debug.print("score: {}\n", .{score});
}
