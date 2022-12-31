const std = @import("std");
const read_input = @import("input.zig").read_input;

const Idx = struct {
    x: u32,
    y: u32,

    fn fromComma(str: []const u8) Idx {
        var parts = std.mem.split(u8, std.mem.trim(u8, str, " "), ",");
        const x = std.fmt.parseInt(u32, parts.next().?, 10) catch unreachable;
        const y = std.fmt.parseInt(u32, parts.next().?, 10) catch unreachable;
        return Idx{ .x = x, .y = y };
    }
};

const CellState = enum {
    rock,
    empty,
    sand,

    pub fn format(
        self: CellState,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(switch (self) {
            .rock => "#",
            .empty => ".",
            .sand => "o",
        });
    }
};

fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();
        vals: []T,
        numRows: u32,
        numCols: u32,
        minX: u32,
        minY: u32,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, numCols: u32, numRows: u32, minX: u32, minY: u32, default: T) !Self {
            var vals = try allocator.alloc(T, numRows * numCols);
            std.mem.set(T, vals, default);
            return Self{
                .numCols = numCols,
                .numRows = numRows,
                .vals = vals,
                .minX = minX,
                .minY = minY,
                .allocator = allocator,
            };
        }
        pub fn get(self: *Self, x: u32, y: u32) *T {
            return &self.vals[((y - self.minY) * self.numCols) + (x - self.minX)];
        }
        pub fn getIdx(self: *Self, idx: Idx) *T {
            return self.get(idx.x, idx.y);
        }
        pub fn getval(self: *const Self, x: u32, y: u32) T {
            return self.vals[((y - self.minY) * self.numCols) + (x - self.minX)];
        }
        pub fn getvalIdx(self: *const Self, idx: Idx) T {
            return self.getval(idx.x, idx.y);
        }
        pub fn format(
            self: Self,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            const m = self.numRows;
            const n = self.numCols;
            var y: u32 = self.minY;
            while (y < m + self.minY) : (y += 1) {
                var x: u32 = self.minX;
                while (x < n + self.minX) : (x += 1) {
                    switch (@typeInfo(T)) {
                        .Enum => try writer.print("{}", .{self.getval(x, y)}),
                        else => try writer.print("{} ", .{self.getval(x, y)}),
                    }
                    if (x - self.minX < n - 1) {} else {
                        try writer.writeAll("\n");
                    }
                }
            }
        }
    };
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day14_dummy.txt");
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    // we _know_ that sand drips from 500,0
    var minX: u32 = 500;
    var minY: u32 = 0;
    var maxX: u32 = 500;
    var maxY: u32 = 0;
    var rockLines = std.ArrayList([]Idx).init(allocator);
    while (lines.next()) |line| {
        var points = try allocator.alloc(Idx, std.mem.count(u8, line, "->") + 1);
        var rocklines = std.mem.split(u8, line, " -> ");
        points[0] = Idx.fromComma(rocklines.next().?);
        minX = std.math.min(minX, points[0].x);
        maxX = std.math.max(maxX, points[0].x);
        minY = std.math.min(minY, points[0].y);
        maxY = std.math.max(maxY, points[0].y);

        var i: usize = 1;
        while (rocklines.next()) |l| {
            const idx = Idx.fromComma(l);
            points[i] = idx;
            minX = std.math.min(minX, idx.x);
            maxX = std.math.max(maxX, idx.x);
            minY = std.math.min(minY, idx.y);
            maxY = std.math.max(maxY, idx.y);
            i += 1;
        }
        try rockLines.append(points);
    }
    std.debug.print("mixX, minY, maxX, maxY: {} {} {} {}\n", .{ minX, minY, maxX, maxY });
    const numRows = maxY - minY + 1;
    const numCols = maxX - minX + 1;
    std.debug.print("numRows, numCols: {} {}\n", .{ numRows, numCols });
    var rockGrid = try Grid(CellState).init(allocator, numCols, numRows, minX, minY, CellState.empty);
    for (rockLines.items) |points| {
        var start = points[0];
        for (points[1..]) |end| {
            if (start.x == end.x) {
                var p = std.math.min(start.y, end.y);
                while (p <= std.math.max(start.y, end.y)) : (p += 1) {
                    rockGrid.get(start.x, p).* = CellState.rock;
                }
            } else {
                var p = std.math.min(start.x, end.x);
                while (p <= std.math.max(start.x, end.x)) : (p += 1) {
                    rockGrid.get(p, start.y).* = CellState.rock;
                }
            }
            start = end;
        }
    }
    std.debug.print("rockGrid:\n{any}\n", .{rockGrid});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day14_dummy.txt");
    _ = input;
}
