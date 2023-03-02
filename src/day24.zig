const std = @import("std");
const read_input = @import("input.zig").read_input;

const Dir = enum(u8) {
    n = '^',
    e = '>',
    s = 'v',
    w = '<',
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
            try writer.print("{any}", .{if (self.n) Dir.n else if (self.e) Dir.e else if (self.w) Dir.w else Dir.s});
        } else if (n > 1) {
            try writer.print("{}", .{n});
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
};

const Grid = struct {
    const This = @This();
    numRows: u32,
    numCols: u32,
    cells: []Cell,
    start: Idx,
    end: Idx,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !This {
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
        return This{
            .numCols = numCols,
            .numRows = numRows,
            .cells = cells,
            .start = start,
            .end = end,
            .allocator = allocator,
        };
    }

    pub fn get(self: *This, i: u32, j: u32) *Cell {
        return &self.cells[(i * self.numCols) + j];
    }
    pub fn getIdx(self: *This, idx: Idx) *Cell {
        return self.get(idx.i, idx.j);
    }
    pub fn getval(self: *const This, i: u32, j: u32) Cell {
        return self.cells[(i * self.numCols) + j];
    }
    pub fn getvalIdx(self: *const This, idx: Idx) Cell {
        return self.getval(idx.i, idx.j);
    }

    pub fn format(
        self: This,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        for (0..self.numRows) |i_| {
            var i = @intCast(u32, i_);
            for (0..self.numCols) |j_| {
                var j = @intCast(u32, j_);
                if ((i == self.start.i and j == self.start.j) or (i == self.end.i and j == self.end.j)) {
                    try writer.writeAll(".");
                } else if (i == 0 or i == self.numRows - 1 or j == 0 or j == self.numCols - 1) {
                    try writer.writeAll("#");
                } else {
                    try writer.print("{c}", .{self.getval(i, j)});
                }
                if (j < self.numCols - 1) {} else {
                    try writer.writeAll("\n");
                }
            }
        }
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day24_dummy.txt");
    defer allocator.free(input);
    var grid = try Grid.init(allocator, input);
    std.debug.print("grid:\n{}\n", .{grid});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day24_dummy.txt");
    defer allocator.free(input);
}
