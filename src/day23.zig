const std = @import("std");
const read_input = @import("input.zig").read_input;
const Allocator = std.mem.Allocator;

const I = i128;

const Idx = struct {
    i: I,
    j: I,

    fn add(self: Idx, i: I, j: I) Idx {
        return Idx{
            .i = self.i + i,
            .j = self.j + j,
        };
    }

    pub fn format(
        self: Idx,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("({},{})", .{ self.i, self.j });
    }
};

const Map = struct {
    const Self = @This();
    // locations of all the elves
    locs: std.AutoHashMap(Idx, void),
    fn parse(allocator: Allocator, input: []const u8) !Self {
        var count = std.mem.count(u8, input, "#");
        var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        var locs = std.AutoHashMap(Idx, void).init(allocator);
        try locs.ensureTotalCapacity(@truncate(u32, count));
        {
            var i: usize = 0;
            while (lines.next()) |line| {
                for (line, 0..) |ch, j| {
                    if (ch == '#') {
                        locs.putAssumeCapacity(Idx{ .i = @intCast(i32, i), .j = @intCast(i32, j) }, {});
                    }
                }
                i += 1;
            }
        }
        return Self{ .locs = locs };
    }
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        var it = self.locs.iterator();
        try writer.writeAll("locs: ");
        while (it.next()) |entry| {
            try writer.print("{any} ", .{entry.key_ptr.*});
        }
        try writer.writeAll("\n");
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day23_dummy.txt");
    defer allocator.free(input);
    var map = try Map.parse(allocator, input);
    std.debug.print("map.locs: {any}\n", .{map});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day23_dummy.txt");
    defer allocator.free(input);
}
