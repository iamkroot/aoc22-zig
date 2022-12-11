const std = @import("std");
const read_input = @import("input.zig").read_input;

const Pair = struct {
    start1: u8 = 0,
    end1: u8 = 0,
    start2: u8 = 0,
    end2: u8 = 0,
};

fn parseLine(line: []const u8) Pair {
    var curval: u8 = 0;
    var pair = Pair{};
    for (line) |c| {
        if (c < '0' or c > '9') {
            if (pair.start1 == 0) {
                pair.start1 = curval;
            } else if (pair.end1 == 0) {
                pair.end1 = curval;
            } else if (pair.start2 == 0) {
                pair.start2 = curval;
            } // end2 will be set later
            curval = 0;
        } else {
            curval *= 10;
            curval += c - '0';
        }
    }
    pair.end2 = curval;
    return pair;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [11382]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day4.txt");
    var lines = std.mem.split(u8, input, "\n");
    var overlapCount: u32 = 0;
    while (lines.next()) |line| {
        const pair = parseLine(line);
        if ((pair.start1 <= pair.start2 and pair.end1 >= pair.end2) or
            (pair.start1 >= pair.start2 and pair.end1 <= pair.end2))
        {
            overlapCount += 1;
        }
    }
    std.debug.print("overlapCount: {}\n", .{overlapCount});
}
