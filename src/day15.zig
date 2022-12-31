const std = @import("std");
const read_input = @import("input.zig").read_input;

/// `d` will point to the last valid digit
fn parseIntChomp(inp: []const u8, d: *usize) i32 {
    var n: i32 = 0;
    var neg: bool = false;
    while (d.* < inp.len) : (d.* += 1) {
        const c = inp[d.*];
        if (c == '-') {
            neg = true;
        } else if (std.ascii.isDigit(c)) {
            n *= 10;
            n += c - '0';
        } else {
            break;
        }
    }
    if (neg) {
        n *= -1;
    }
    return n;
}

const Pos = struct {
    const Self = @This();
    x: i32,
    y: i32,

    fn fromComma(str: []const u8, i: *usize) Self {
        const x = parseIntChomp(str, i);
        i.* += 4;
        const y = parseIntChomp(str, i);
        return Self{ .x = x, .y = y };
    }

    fn manhattan(self: Self, other: Self) u32 {
        return std.math.absCast(self.x - other.x) + std.math.absCast(self.y - other.y);
    }
};
const Pair = [2]i32;

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day15.txt");
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    // const TARGET_Y: i32 = 10;
    const TARGET_Y: i32 = 2000000;
    var beaconsOnTarget = std.ArrayList(Pos).init(allocator);
    var segments = std.ArrayList(Pair).init(allocator);
    var minX: i32 = std.math.maxInt(i32);
    var maxX: i32 = std.math.minInt(i32);
    while (lines.next()) |line| {
        var i: usize = 12;
        const sensorPos = Pos.fromComma(line, &i);
        i += 25;
        const beaconPos = Pos.fromComma(line, &i);

        const manh = sensorPos.manhattan(beaconPos);
        if (std.math.absCast(sensorPos.y - TARGET_Y) >= manh) {
            continue;
        }
        const widthX = @intCast(i32, (manh - std.math.absCast(sensorPos.y - TARGET_Y)));
        const start = sensorPos.x - widthX;
        const end = sensorPos.x + widthX;
        std.debug.print("sensor: {} beacon: {} manh {} {} {}\n", .{ sensorPos, beaconPos, manh, start, end });
        minX = std.math.min(minX, start);
        maxX = std.math.max(maxX, end);
        if (beaconPos.y == TARGET_Y and beaconPos.x >= start and beaconPos.x <= end) {
            std.debug.print("beaconPos: {}\n", .{beaconPos});
            for (beaconsOnTarget.items) |b| {
                if (b.x == beaconPos.x and b.y == beaconPos.y) {
                    break;
                }
            } else {
                try beaconsOnTarget.append(beaconPos);
            }
        }
        try segments.append(Pair{ start, end });
    }

    std.sort.sort(Pair, segments.items, {}, cmpPair);
    std.debug.print("segments: {any} {} {}\n", .{ segments.items, minX, maxX });
    var x = minX;
    var count: u32 = 0;
    while (x <= maxX) : (x += 1) {
        for (segments.items) |segment| {
            const start = segment[0];
            const end = segment[1];
            if (x >= start and x <= end) {
                count += 1;
                break;
            }
        }
    }
    std.debug.print("count, beaconsOnTarget: {} {any}\n", .{ count, beaconsOnTarget.items });
    std.debug.print("val: {}\n", .{count - beaconsOnTarget.items.len});
}

fn cmpPair(_: void, l: Pair, r: Pair) bool {
    return if (l[0] == r[0]) (l[1] < r[1]) else (l[0] < r[0]);
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day15_dummy.txt");
    _ = input;
}
