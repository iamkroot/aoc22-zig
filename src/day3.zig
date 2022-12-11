const std = @import("std");
const read_input = @import("input.zig").read_input;

fn priority(itemType: u8) u8 {
    return switch (itemType) {
        'a'...'z' => (itemType + 1) - 'a',
        'A'...'Z' => (itemType + 27) - 'A',
        else => unreachable,
    };
}

const ItemCount = struct {
    arr: [52]u2,
    fn init() ItemCount {
        return ItemCount{ .arr = [_]u2{0} ** 52 };
    }
    fn add(self: *@This(), val: u8) void {
        var arr = &self.arr;
        var v: *u2 = &arr[priority(val) - 1];
        v.* = 1;
    }
    fn getCommon(self: @This(), other: @This()) u8 {
        for (self.arr) |v, i| {
            if (v > 0 and other.arr[i] > 0) {
                return @intCast(u8, i) + 1;
            }
        }
        unreachable;
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [10100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day3.txt");
    var lines = std.mem.split(u8, input, "\n");
    var total: u64 = 0;
    while (lines.next()) |line| {
        var ic1 = ItemCount.init();
        var ic2 = ItemCount.init();
        const half = line.len / 2;
        for (line) |c, i| {
            if (i < half) {
                ic1.add(c);
            } else {
                ic2.add(c);
            }
        }
        const commonPriority = ic1.getCommon(ic2);
        total += commonPriority;
    }
    std.debug.print("total: {}\n", .{ total });
}
