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
    x: i32,
    y: i32,

    fn fromComma(str: []const u8, i: *usize) Pos {
        const x = parseIntChomp(str, i);
        i.* += 4;
        const y = parseIntChomp(str, i);
        return Pos{ .x = x, .y = y };
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day15_dummy.txt");
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    while (lines.next()) |line| {
        var i: usize = 12;
        const sensorPos = Pos.fromComma(line, &i);
        i += 25;
        const beaconPos = Pos.fromComma(line, &i);
        std.debug.print("sensor: {} beacon: {}\n", .{ sensorPos, beaconPos });
    }
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day15_dummy.txt");
    _ = input;
}
