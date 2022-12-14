const std = @import("std");
const read_input = @import("input.zig").read_input;

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day6.txt");
    var prev3 = input[0]-'a';
    var prev2 = input[1]-'a';
    var prev1 = input[2]-'a';
    var freq = [_]u8{0} ** 26;
    freq[prev3] += 1;
    freq[prev2] += 1;
    freq[prev1] += 1;
    std.debug.print("input.len: {}\n", .{ input.len });
    for(input[3..]) |c, i| {
        freq[c-'a'] += 1;
        for(freq) |v| {
            if (v >= 2) {
                freq[prev3] -= 1;
                prev3 = prev2;
                prev2 = prev1;
                prev1 = c - 'a';
                break;
            }
        } else {
            std.debug.print("i: {}\n", .{ i + 4 });
            std.debug.print("freq: {any}\n", .{ freq });
            break;
        }
    }
}

pub fn part2(dataDir: std.fs.Dir) !void {
    _ = dataDir;
}