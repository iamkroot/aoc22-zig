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
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day6.txt");
    var prev = [_]u8{0} ** 13;
    var freq = [_]u8{0} ** 26;
    for (input[0..13]) |c, i| {
        prev[12-i] = c-'a';
        freq[c-'a'] += 1;
    }

    for(input[13..]) |c, i| {
        freq[c-'a'] += 1;
        var numDistinct: u8 = 0;
        for(freq) |v| {
            if (v == 1) {
                numDistinct += 1;
            }
        }
        if (numDistinct < 14) {
            freq[prev[12]] -= 1;
            var pi:u8 = 12;
            while (pi > 0) : (pi -= 1) {
                prev[pi] = prev[pi-1];
            }
            prev[0] = c - 'a';            
        } else {
            std.debug.print("i: {} {c}\n", .{ i + 14, c });
            break;
        }
    }
}