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

fn addUniq(arr: *std.ArrayList(Pos), val: Pos) !void {
    for (arr.items) |b| {
        if (b.x == val.x and b.y == val.y) {
            break;
        }
    } else {
        try arr.append(val);
    }
}

var sensors: []Pos = undefined;
var beacons: []Pos = undefined;
var manhattans: []u32 = undefined;

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !void {
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    const n = std.mem.count(u8, input, "\n");
    sensors = try allocator.alloc(Pos, n);
    beacons = try allocator.alloc(Pos, n);
    manhattans = try allocator.alloc(u32, n);
    var idx: u32 = 0;

    while (lines.next()) |line| {
        var i: usize = 12;
        const sensorPos = Pos.fromComma(line, &i);
        i += 25;
        const beaconPos = Pos.fromComma(line, &i);

        const manh = sensorPos.manhattan(beaconPos);
        sensors[idx] = sensorPos;
        beacons[idx] = beaconPos;
        manhattans[idx] = manh;
        idx += 1;
    }
}

var beaconsOnTarget: std.ArrayList(Pos) = undefined;
var segments: std.ArrayList(Pair) = undefined;

const MINPOS: i32 = 0;
// const MAXPOS: i32 = 20;
const MAXPOS: i32 = 4000000;

fn getSegments(allocator: std.mem.Allocator, targetY: i32, comptime ispart2: bool) !std.ArrayList(Pair) {
    beaconsOnTarget.shrinkRetainingCapacity(0);
    segments.shrinkRetainingCapacity(0);

    var idx: u32 = 0;
    var minX: i32 = MAXPOS;
    var maxX: i32 = MINPOS;
    while (idx < sensors.len) : (idx += 1) {
        const sensorPos = sensors[idx];
        const beaconPos = beacons[idx];
        const manh = manhattans[idx];
        if (std.math.absCast(sensorPos.y - targetY) >= manh) {
            continue;
        }
        const widthX = @intCast(i32, (manh - std.math.absCast(sensorPos.y - targetY)));
        var start = sensorPos.x - widthX;
        var end = sensorPos.x + widthX;
        if (ispart2) {
            start = std.math.clamp(start, MINPOS, MAXPOS);
            end = std.math.clamp(end, MINPOS, MAXPOS);
        }
        // std.debug.print("sensor: {} beacon: {} manh {} {} {}\n", .{ sensorPos, beaconPos, manh, start, end });
        minX = std.math.min(minX, start);
        maxX = std.math.max(maxX, end);
        if (beaconPos.y == targetY and beaconPos.x >= start and beaconPos.x <= end) {
            try addUniq(&beaconsOnTarget, beaconPos);
        }
        try segments.append(Pair{ start, end });
    }
    std.sort.sort(Pair, segments.items, {}, cmpPair);
    // std.debug.print("segments: {any} {} {}\n", .{ segments.items, minX, maxX });

    // coalesce all the segments
    var finalSegments = std.ArrayList(Pair).init(allocator);
    try finalSegments.append(segments.items[0]);

    var prevEnd = segments.items[0][1];
    for (segments.items[1..]) |segment| {
        const start = segment[0];
        const end = segment[1];
        if (start <= prevEnd + 1) {
            finalSegments.items[finalSegments.items.len - 1][1] = std.math.max(prevEnd, end);
        } else {
            try finalSegments.append(segment);
        }
        prevEnd = finalSegments.items[finalSegments.items.len - 1][1];
    }
    return finalSegments;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day15.txt");
    try parseInput(allocator, input);
    beaconsOnTarget = std.ArrayList(Pos).init(allocator);
    defer beaconsOnTarget.deinit();
    segments = std.ArrayList(Pair).init(allocator);
    defer segments.deinit();

    const finalSegments = try getSegments(allocator, 2000000, false);
    defer finalSegments.deinit();
    // std.debug.print("finalSegments: {any}\n", .{finalSegments});

    var count: u32 = 0;
    for (finalSegments.items) |segment| {
        const start = segment[0];
        const end = segment[1];
        count += @intCast(u32, end - start + 1);
    }

    // std.debug.print("count, beaconsOnTarget: {} {any}\n", .{ count, beaconsOnTarget.items });
    std.debug.print("val: {}\n", .{count - beaconsOnTarget.items.len});
}

fn cmpPair(_: void, l: Pair, r: Pair) bool {
    return if (l[0] == r[0]) (l[1] < r[1]) else (l[0] < r[0]);
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [140000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day15.txt");
    try parseInput(allocator, input);
    beaconsOnTarget = std.ArrayList(Pos).init(allocator);
    segments = std.ArrayList(Pair).init(allocator);
    var targetY: i32 = MINPOS;
    while (targetY <= MAXPOS) : (targetY += 1) {
        const finalSegments = try getSegments(allocator, targetY, true);
        // std.debug.print("finalSegments: {any}\n", .{finalSegments});
        if (finalSegments.items.len > 1) {
            const targetX = finalSegments.items[0][1] + 1;
            const freq = @intCast(u64, targetX) * 4000000 + @intCast(u64, targetY);
            std.debug.print("freq: {} {} {}\n", .{ targetX, targetY, freq });
            break;
        }
        finalSegments.deinit();
    }
}
