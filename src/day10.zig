const std = @import("std");
const read_input = @import("input.zig").read_input;

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day10.txt");
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    var cycle: u32 = 1;
    var val: i64 = 1;
    var nextTargetCycle: u32 = 20;
    var strength: i64 = 0;
    const NUM_CYCLES: u32 = 221;
    var nextInstrCycle: u32 = 1;
    var line: []const u8 = undefined;
    var nextValAdd: i64 = 0;
    while (cycle < NUM_CYCLES) : (cycle += 1) {
        if (cycle == nextInstrCycle) {
            val += nextValAdd;
        }
        if (cycle == nextTargetCycle) {
            strength += val * cycle;
            // std.debug.print("n: val, cycle: {} {}\n", .{ val, cycle });
            nextTargetCycle += 40;
        }
        if (cycle == nextInstrCycle) {
            line = lines.next().?;
            if (line[0] == 'n') {
                nextInstrCycle = cycle + 1;
                nextValAdd = 0;
            } else {
                nextInstrCycle = cycle + 2;
                nextValAdd = try std.fmt.parseInt(i64, line[5..], 10);
            }
        }
        // std.debug.print("cycle: {} {s}\n", .{ cycle, line });
    }
    std.debug.print("strength: {}\n", .{strength});
}

fn printGrid(grid: []const u8) void {
    for (grid) |c, i| {
        std.debug.print("{c}", .{c});
        if (i % 40 == 39) {
            std.debug.print("\n", .{});
        }
    }
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day10.txt");
    var grid = [_]u8{'.'} ** 240;
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    var cycle: u32 = 1;
    var val: i64 = 1;
    const NUM_CYCLES: u32 = 241;
    var nextInstrCycle: u32 = 1;
    var line: []const u8 = undefined;
    var nextValAdd: i64 = 0;
    while (cycle < NUM_CYCLES) : (cycle += 1) {
        if (cycle == nextInstrCycle) {
            val += nextValAdd;
            line = lines.next().?;
            if (line[0] == 'n') {
                nextInstrCycle = cycle + 1;
                nextValAdd = 0;
            } else {
                nextInstrCycle = cycle + 2;
                nextValAdd = try std.fmt.parseInt(i64, line[5..], 10);
            }
        }
        // std.debug.print("cycle: {} {s}\t{}\n", .{ cycle, line, val });
        const cursor = (cycle - 1) % 40;
        if (val - 1 <= cursor and cursor <= val + 1) {
            grid[cycle - 1] = '#';
        }
    }
    printGrid(&grid);
}
