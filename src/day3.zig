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
    fn addLine(self: *@This(), line: []const u8) void {
        for (line) |val| {
            self.add(val);
        }
    }
    fn getCommon(self: @This(), other: @This()) u8 {
        for (self.arr, 0..) |v, i| {
            if (v > 0 and other.arr[i] > 0) {
                return @intCast(u8, i) + 1;
            }
        }
        unreachable;
    }
    fn getCommon3(self: @This(), other: @This(), other2: @This()) u8 {
        for (self.arr, 0..) |v, i| {
            if (v > 0 and other.arr[i] > 0 and other2.arr[i] > 0) {
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
        ic1.addLine(line[0..half]);
        ic2.addLine(line[half..]);
        const commonPriority = ic1.getCommon(ic2);
        total += commonPriority;
    }
    std.debug.print("total: {}\n", .{total});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [10100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day3.txt");
    var lines = std.mem.split(u8, input, "\n");
    var total: u64 = 0;
    while (lines.next()) |line1| {
        const line2 = lines.next().?;
        const line3 = lines.next().?;
        var ic1 = ItemCount.init();
        var ic2 = ItemCount.init();
        var ic3 = ItemCount.init();
        ic1.addLine(line1);
        ic2.addLine(line2);
        ic3.addLine(line3);
        const commonPriority = ic1.getCommon3(ic2, ic3);
        total += commonPriority;
    }
    std.debug.print("total: {}\n", .{total});
}
