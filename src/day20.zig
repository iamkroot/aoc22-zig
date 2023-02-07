const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;

const Node = struct {
    const Self = @This();
    val: i32 = undefined,
    next: *Self = undefined,
    prev: *Self = undefined,
    orig_next: *Self = undefined,
};

const Nums = struct {
    const Self = @This();
    head: *Node,
    zero: *Node,
    n: usize,
    fn parse_input(input: []const u8, allocator: std.mem.Allocator) !Self {
        var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        var nlines = std.mem.count(u8, std.mem.trim(u8, input, "\n"), "\n") + 1;
        var nodePtrs = try allocator.alloc(Node, nlines);
        var prev = &nodePtrs[0];
        var nums = Self{ .head = prev, .zero = undefined, .n = nlines };
        {
            const first = lines.next().?;
            prev.val = try std.fmt.parseInt(i32, first, 10);
            if (prev.val == 0) nums.zero = prev;
        }
        var i: usize = 1;
        while (lines.next()) |line| {
            var cur = &nodePtrs[i];
            cur.prev = prev;
            prev.next = cur;
            prev.orig_next = cur;
            cur.val = try std.fmt.parseInt(i32, line, 10);
            if (cur.val == 0) nums.zero = cur;
            prev = cur;
            i += 1;
        }
        prev.next = nums.head;
        prev.orig_next = nums.head;
        nums.head.prev = prev;
        std.debug.assert(nums.zero.val == 0);
        return nums;
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        var i: usize = 0;
        var cur = self.head;
        while (i < self.n) : (i += 1) {
            try writer.print("{s}{d}{s}", .{ if (cur == self.zero) "_" else "", cur.val, if (i < self.n - 1) "," else "" });
            cur = cur.next;
        }
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [256000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day20.txt");
    var nums = try Nums.parse_input(input, allocator);
    allocator.free(input);
    // std.debug.print("nums: {any}\n", .{nums});

    var i: usize = 0;
    var cur = nums.head;
    while (i < nums.n) : (i += 1) {
        var j: i32 = 0;
        const x = cur.val;
        switch (x) {
            0 => {},
            1...std.math.maxInt(i32) => {
                while (j < x) : (j += 1) {
                    if (nums.head == cur) {
                        nums.head = cur.next;
                    }
                    cur.prev.next = cur.next;
                    cur.next.prev = cur.prev;
                    cur.next.next.prev = cur;
                    cur.prev = cur.next;
                    cur.next = cur.next.next;
                    cur.prev.next = cur;
                }
            },
            std.math.minInt(i32)...-1 => {
                while (j < -x) : (j += 1) {
                    if (nums.head == cur) {
                        nums.head = cur.prev;
                    }
                    cur.prev.next = cur.next;
                    cur.next.prev = cur.prev;
                    cur.prev.prev.next = cur;
                    cur.next = cur.prev;
                    cur.prev = cur.prev.prev;
                    cur.next.prev = cur;
                }
            },
        }
        // std.debug.print("nums {:02}: {any}\n", .{ x, nums });
        cur = cur.orig_next;
    }
    i = 0;
    var sum: i32 = 0;
    cur = nums.zero;
    while (i < 3001) : (i += 1) {
        switch (i) {
            1000, 2000, 3000 => {
                sum += cur.val;
            },
            else => {},
        }
        cur = cur.next;
    }
    std.debug.print("sum: {}\n", .{sum});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day20_dummy.txt");
    defer allocator.free(input);
}
