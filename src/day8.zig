const std = @import("std");
const read_input = @import("input.zig").read_input;

const Grid = struct {
    n: u32,
    nums: []u4,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, n: u32, input: []const u8) !Grid {
        var nums = try allocator.alloc(u4, n * n);
        var i: u32 = 0;
        var j: u32 = 0;
        for (input) |c| {
            if (c == '\n') {
                i += 1;
                j = 0;
                continue;
            }
            nums[i * n + j] = @intCast(u4, c - '0');
            j += 1;
        }
        return Grid{
            .n = n,
            .nums = nums,
            .allocator = allocator,
        };
    }
    fn initSingle(allocator: std.mem.Allocator, n: u32, val: u4) !Grid {
        var nums = try allocator.alloc(u4, n * n);
        std.mem.set(u4, nums, val);
        return Grid{
            .n = n,
            .nums = nums,
            .allocator = allocator,
        };
    }

    fn get(self: *Grid, i: u32, j: u32) *u4 {
        return &self.nums[(i * self.n) + j];
    }

    pub fn format(
        self: Grid,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        const n = self.n;
        var line = self.allocator.alloc(u8, n) catch unreachable;
        var i: u32 = 0;
        while (i < n) : (i += 1) {
            for (self.nums[i * n .. (i + 1) * n]) |c, x| {
                line[x] = '0' + @intCast(u8, c);
            }
            try writer.print("{s}\n", .{line});
        }
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [240000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day8.txt");
    const n = @intCast(u32, std.mem.indexOf(u8, input, "\n").?);
    std.debug.print("n: {}\n", .{n});

    var inputGrid = try Grid.init(allocator, n, input);
    var upGrid = try Grid.initSingle(allocator, n, 0);
    var downGrid = try Grid.initSingle(allocator, n, 0);
    var leftGrid = try Grid.initSingle(allocator, n, 0);
    var rightGrid = try Grid.initSingle(allocator, n, 0);

    // std.debug.print("inputGrid:\n{}\n", .{ inputGrid });

    var i: u32 = 1;
    var j: u32 = 1;
    while (i < n - 1) : (i += 1) {
        while (j < n - 1) : (j += 1) {
            upGrid.get(i, j).* = std.math.max(upGrid.get(i - 1, j).*, inputGrid.get(i - 1, j).*);
        }
        j = 1;
    }
    // std.debug.print("upGrid:\n{}\n", .{ upGrid });

    i = 1;
    j = 1;
    while (i < n - 1) : (i += 1) {
        while (j < n - 1) : (j += 1) {
            leftGrid.get(i, j).* = std.math.max(leftGrid.get(i, j - 1).*, inputGrid.get(i, j - 1).*);
        }
        j = 1;
    }
    // std.debug.print("leftGrid:\n{}\n", .{ leftGrid });

    i = 1;
    j = n - 2;
    while (i < n - 1) : (i += 1) {
        while (j > 0) : (j -= 1) {
            rightGrid.get(i, j).* = std.math.max(rightGrid.get(i, j + 1).*, inputGrid.get(i, j + 1).*);
        }
        j = n - 2;
    }
    // std.debug.print("rightGrid:\n{}\n", .{ rightGrid });

    i = n - 2;
    j = 1;
    while (i > 0) : (i -= 1) {
        while (j < n - 1) : (j += 1) {
            downGrid.get(i, j).* = std.math.max(downGrid.get(i + 1, j).*, inputGrid.get(i + 1, j).*);
        }
        j = 1;
    }
    // std.debug.print("downGrid:\n{}\n", .{downGrid});

    i = 1;
    j = 1;
    var visCount: u32 = 4 * (n - 1);
    while (i < n - 1) : (i += 1) {
        while (j < n - 1) : (j += 1) {
            const neighMin = std.math.min(std.math.min3(upGrid.get(i, j).*, downGrid.get(i, j).*, leftGrid.get(i, j).*), rightGrid.get(i, j).*);
            if (inputGrid.get(i, j).* > neighMin) {
                visCount += 1;
            }
        }
        j = 1;
    }
    std.debug.print("visCount: {}\n", .{visCount});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day8_dummy.txt");
    _ = input;
}
