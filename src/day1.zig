const std = @import("std");

fn read_input(dataDir: std.fs.Dir, allocator: std.mem.Allocator) ![]const u8 {
    const inputDir = try dataDir.makeOpenPath("input", .{});
    const f = try inputDir.openFile("day1.txt", .{ .mode = .read_only });
    defer f.close();

    const f_stat = try f.stat();
    const result = try allocator.alloc(u8, f_stat.size);
    errdefer allocator.free(result);
    const read_result = try f.read(result);
    try std.testing.expect(read_result > 0);
    return result;
}

/// Iterator over the total calories present with one elf.
const ElfCaloriesIterator = struct {
    input: []const u8 = undefined,
    /// Iterator over the elves
    elfIter: std.mem.SplitIterator(u8) = undefined,
    /// Partial sum over current elf's calories
    elfCalories: u64 = 0,

    fn init(input: []const u8) ElfCaloriesIterator {
        var iter = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n\n");
        return ElfCaloriesIterator{
            .input = input,
            .elfIter = iter,
        };
    }

    fn next(self: *ElfCaloriesIterator) ?u64 {
        self.elfCalories = 0;
        var caloriesIter = blk: {
            if (self.elfIter.next()) |lines| {
                break :blk std.mem.split(u8, lines, "\n");
            } else {
                return null;
            }
        };
        while (caloriesIter.next()) |line| {
            const v = std.fmt.parseUnsigned(u64, line, 10) catch unreachable;
            self.elfCalories += v;
        } else {
            return self.elfCalories;
        }
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [16000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const result = try read_input(dataDir, allocator);

    var maxval: u64 = 0;
    var iter = ElfCaloriesIterator.init(result);
    while (iter.next()) |val| {
        maxval = std.math.max(maxval, val);
    }
    std.debug.print("maxval: {}\n", .{maxval});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [16000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const result = try read_input(dataDir, allocator);

    var iter = ElfCaloriesIterator.init(result);
    var maxval1: u64 = 0;
    var maxval2: u64 = 0;
    var maxval3: u64 = 0;
    while (iter.next()) |val| {
        if (val >= maxval1) {
            maxval3 = maxval2;
            maxval2 = maxval1;
            maxval1 = val;
        } else if (val >= maxval2) {
            maxval3 = maxval2;
            maxval2 = val;
        } else if (val > maxval3) {
            maxval3 = val;
        }
    }
    const summax3 = maxval1 + maxval2 + maxval3;
    std.debug.print("summax3: {}\n", .{summax3});
}
