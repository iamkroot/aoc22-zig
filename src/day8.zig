const std = @import("std");
const read_input = @import("input.zig").read_input;

fn Grid(comptime T: type) type {
    return struct {
        n: u32,
        nums: []T,
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator, n: u32, input: []const u8) !Grid(T) {
            var nums = try allocator.alloc(T, n * n);
            var i: u32 = 0;
            var j: u32 = 0;
            for (input) |c| {
                if (c == '\n') {
                    i += 1;
                    j = 0;
                    continue;
                }
                nums[i * n + j] = @intCast(T, c - '0');
                j += 1;
            }
            return Grid(T){
                .n = n,
                .nums = nums,
                .allocator = allocator,
            };
        }
        fn initSingle(allocator: std.mem.Allocator, n: u32, val: T) !Grid(T) {
            var nums = try allocator.alloc(T, n * n);
            std.mem.set(T, nums, val);
            return Grid(T){
                .n = n,
                .nums = nums,
                .allocator = allocator,
            };
        }

        fn get(self: *Grid(T), i: u32, j: u32) *T {
            return &self.nums[(i * self.n) + j];
        }
        fn getval(self: *const Grid(T), i: u32, j: u32) T {
            return self.nums[(i * self.n) + j];
        }

        pub fn format(
            self: Grid(T),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            const n = self.n;
            var i: u32 = 0;
            while (i < n) : (i += 1) {
                var j: u32 = 0;
                while (j < n) : (j += 1) {
                    switch (@typeInfo(T)) {
                        .Int => |info| if (info.bits > 4) {
                            try writer.print("{d: >2}", .{self.getval(i, j)});
                        } else {
                            try writer.print("{d}", .{self.getval(i, j)});
                        },
                        else => unreachable,
                    }
                    if (j < n - 1) {
                        switch (@typeInfo(T)) {
                            .Int => |info| if (info.bits > 4) {
                                try writer.writeAll(" ");
                            },
                            else => unreachable,
                        }
                    } else {
                        try writer.writeAll("\n");
                    }
                }
            }
        }
    };
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [240000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day8.txt");
    const n = @intCast(u32, std.mem.indexOf(u8, input, "\n").?);
    std.debug.print("n: {}\n", .{n});

    var inputGrid = try Grid(u4).init(allocator, n, input);
    var upGrid = try Grid(u4).initSingle(allocator, n, 0);
    var downGrid = try Grid(u4).initSingle(allocator, n, 0);
    var leftGrid = try Grid(u4).initSingle(allocator, n, 0);
    var rightGrid = try Grid(u4).initSingle(allocator, n, 0);

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
    var buffer: [40000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day8.txt");
    const n = @intCast(u32, std.mem.indexOf(u8, input, "\n").?);
    std.debug.print("n: {}\n", .{n});

    var inputGrid = try Grid(u4).init(allocator, n, input);
    var i: u32 = 1;
    var maxScore: u32 = 0;
    while (i < n - 1) : (i += 1) {
        var j: u32 = 1;
        while (j < n - 1) : (j += 1) {
            const val = inputGrid.getval(i, j);
            var sceneScore: u32 = 1;
            {
                var a = i + 1;
                var treeCount: u32 = 0;
                while (a < n) : (a += 1) {
                    treeCount += 1;
                    if (inputGrid.getval(a, j) >= val) {
                        break;
                    }
                }
                sceneScore *= treeCount;
            }
            {
                var a = j + 1;
                var treeCount: u32 = 0;
                while (a < n) : (a += 1) {
                    treeCount += 1;
                    if (inputGrid.getval(i, a) >= val) {
                        break;
                    }
                }
                sceneScore *= treeCount;
            }
            {
                var a: i32 = @intCast(i32, i - 1);
                var treeCount: u32 = 0;
                while (a >= 0) : (a -= 1) {
                    treeCount += 1;
                    if (inputGrid.getval(@intCast(u32, a), j) >= val) {
                        break;
                    }
                }
                sceneScore *= treeCount;
            }
            {
                var a: i32 = @intCast(i32, j - 1);
                var treeCount: u32 = 0;
                while (a >= 0) : (a -= 1) {
                    treeCount += 1;
                    if (inputGrid.getval(i, @intCast(u32, a)) >= val) {
                        break;
                    }
                }
                sceneScore *= treeCount;
            }
            if (sceneScore > maxScore) {
                maxScore = sceneScore;
            }
        }
    }
    std.debug.print("maxScore: {}\n", .{maxScore});
}
