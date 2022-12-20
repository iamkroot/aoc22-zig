const std = @import("std");
const read_input = @import("input.zig").read_input;

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

pub fn Grid(comptime T: type, comptime fmtEl: []const u8) type {
    return struct {
        const This = @This();
        numRows: u32,
        numCols: u32,
        nums: []T,
        start: Idx,
        end: Idx,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, numCols: u32, numRows: u32, input: []const u8) !This {
            var nums = try allocator.alloc(T, numRows * numCols);
            var i: u32 = 0;
            var j: u32 = 0;
            var start: Idx = undefined;
            var end: Idx = undefined;
            for (input) |c| {
                if (c == '\n') {
                    i += 1;
                    j = 0;
                    continue;
                } else if (c == 'S') {
                    start = .{ .i = i, .j = j };
                    nums[i * numCols + j] = 'a';
                } else if (c == 'E') {
                    end = .{ .i = i, .j = j };
                    nums[i * numCols + j] = 'z';
                } else {
                    nums[i * numCols + j] = c;
                }
                j += 1;
            }
            return This{
                .numCols = numCols,
                .numRows = numRows,
                .nums = nums,
                .start = start,
                .end = end,
                .allocator = allocator,
            };
        }

        fn initSingle(allocator: std.mem.Allocator, mainGrid: anytype, val: T) !This {
            var nums = try allocator.alloc(T, mainGrid.numRows * mainGrid.numCols);
            std.mem.set(T, nums, val);
            return This{
                .numRows = mainGrid.numRows,
                .numCols = mainGrid.numCols,
                .start = mainGrid.start,
                .end = mainGrid.end,
                .nums = nums,
                .allocator = allocator,
            };
        }

        pub fn get(self: *This, i: u32, j: u32) *T {
            return &self.nums[(i * self.numCols) + j];
        }
        pub fn getIdx(self: *This, idx: Idx) *T {
            return self.get(idx.i, idx.j);
        }
        pub fn getval(self: *const This, i: u32, j: u32) T {
            return self.nums[(i * self.numCols) + j];
        }
        pub fn getvalIdx(self: *const This, idx: Idx) T {
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
const Delta = struct { i: i32, j: i32 };

const InputGrid = Grid(u8, "{c}");
const VisitedGrid = Grid(bool, "{} ");

fn parseGrid(allocator: std.mem.Allocator, input: []const u8) !InputGrid {
    const numCols = @intCast(u32, std.mem.indexOf(u8, input, "\n").?);
    const numRows = @intCast(u32, std.mem.count(u8, std.mem.trim(u8, input, "\n"), "\n") + 1);
    // std.debug.print("numRows: {} numCols: {}\n", .{ numRows, numCols });

    return Grid(u8, "{c}").init(allocator, numCols, numRows, input);
}

pub fn Queue(comptime Child: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        gpa: std.mem.Allocator,
        start: ?*Node,
        end: ?*Node,

        pub fn init(gpa: std.mem.Allocator) This {
            return This{
                .gpa = gpa,
                .start = null,
                .end = null,
            };
        }
        pub fn enqueue(this: *This, value: Child) !void {
            const node = try this.gpa.create(Node);
            node.* = .{ .data = value, .next = null };
            if (this.end) |end| end.next = node //
            else this.start = node;
            this.end = node;
        }
        pub fn dequeue(this: *This) ?Child {
            const start = this.start orelse return null;
            defer this.gpa.destroy(start);
            if (start.next) |next|
                this.start = next
            else {
                this.start = null;
                this.end = null;
            }
            return start.data;
        }
        pub fn format(
            self: Queue(Child),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            var start = self.start orelse null;
            try writer.writeAll("{ ");
            while (start) |node| {
                try writer.print("{} ", .{node.data});
                start = node.next;
            }
            try writer.writeAll("}");
        }
    };
}

fn minPath(allocator: std.mem.Allocator, inputGrid: InputGrid) !u32 {
    var visited = try Grid(bool, "{} ").initSingle(allocator, inputGrid, false);
    // std.debug.print("visited: start: {}, end: {}\n{}\n", .{ visited.start, visited.end, visited });

    const Node = struct {
        idx: Idx,
        pathLen: u32,
    };

    var queue = Queue(Node).init(allocator);
    try queue.enqueue(.{ .idx = inputGrid.start, .pathLen = 0 });
    while (queue.dequeue()) |node| {
        if (node.idx.i == inputGrid.end.i and node.idx.j == inputGrid.end.j) {
            return node.pathLen;
        }
        var dirs = [_]Delta{ .{ .i = 0, .j = -1 }, .{ .i = 0, .j = 1 }, .{ .i = -1, .j = 0 }, .{ .i = 1, .j = 0 } };
        const elevation = inputGrid.getvalIdx(node.idx);
        var didVisit = visited.getIdx(node.idx);
        if (didVisit.*) {
            continue;
        }
        didVisit.* = true;
        for (dirs) |dir| {
            const nextIdx = node.idx.add(dir.i, dir.j) orelse continue;
            if (nextIdx.i >= inputGrid.numRows or nextIdx.j >= inputGrid.numCols) {
                continue;
            }
            const nextElev = inputGrid.getvalIdx(nextIdx);
            if (nextElev > elevation + 1) {
                continue;
            }
            try queue.enqueue(.{ .idx = nextIdx, .pathLen = node.pathLen + 1 });
        }
    }
    return 1e9;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [1444000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day12.txt");
    const inputGrid = try parseGrid(allocator, input);
    // std.debug.print("inputGrid: start: {}, end: {}\n{}\n", .{ inputGrid.start, inputGrid.end, inputGrid });
    const minLen = try minPath(allocator, inputGrid);
    std.debug.print("minLen: {}\n", .{minLen});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    const allocator = std.heap.page_allocator;
    const input = try read_input(dataDir, allocator, "day12.txt");
    var inputGrid = try parseGrid(allocator, input);

    var i: u32 = 0;
    var j: u32 = 0;
    var minLen: u32 = 1e9;
    for (inputGrid.nums) |c| {
        if (c == 'a') {
            inputGrid.start = .{ .i = i, .j = j };
            const pathLen = try minPath(allocator, inputGrid);
            if (minLen > pathLen) {
                minLen = pathLen;
            }
        }
        j += 1;
        if (j == inputGrid.numCols) {
            j = 0;
            i += 1;
        }
    }
    std.debug.print("minLen: {}\n", .{minLen});
}
