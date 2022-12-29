const std = @import("std");
const read_input = @import("input.zig").read_input;

const el = union(enum) {
    const Self = @This();
    val: u32,
    list: []const el,

    fn parse(allocator: std.mem.Allocator, line: []const u8, i: *usize) !el {
        if (line[i.*] == '[') {
            var arr = std.ArrayList(el).init(allocator);
            i.* += 1;
            while (line[i.*] != ']') {
                const child = try el.parse(allocator, line, i);
                try arr.append(child);
                if (line[i.*] == ',') {
                    i.* += 1;
                }
            }
            i.* += 1;
            return el{ .list = arr.items };
        } else {
            var num: u32 = 0;
            while (std.ascii.isDigit(line[i.*])) {
                num *= 10;
                num += line[i.*] - '0';
                i.* += 1;
            }
            return el{ .val = num };
        }
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .val => |v| try writer.print("{d}", .{v}),
            .list => |els| {
                try writer.writeAll("[");
                for (els) |e| {
                    try writer.print("{} ", .{e});
                }
                try writer.writeAll("]");
            },
        }
    }

    fn cmp(allocator: std.mem.Allocator, left: Self, right: Self) !?bool {
        return switch (left) {
            .val => |l| switch (right) {
                .val => |r| if (l == r) null else l < r,
                .list => |r| {
                    _ = r;
                    var a = try std.ArrayList(el).initCapacity(allocator, 1);
                    try a.append(el{ .val = l });
                    return try cmp(allocator, el{ .list = a.items }, right);
                },
            },
            .list => |l| switch (right) {
                .val => |r| {
                    var a = try std.ArrayList(el).initCapacity(allocator, 1);
                    defer a.deinit();
                    try a.append(el{ .val = r });
                    return try cmp(allocator, left, el{ .list = a.items });
                },
                .list => |r| {
                    var i: u32 = 0;
                    while (i < l.len and i < r.len) : (i += 1) {
                        const eq = try el.cmp(allocator, l[i], r[i]);
                        if (eq) |v| {
                            return v;
                        }
                    }
                    return if (l.len < r.len) true else if (l.len > r.len) false else null;
                },
            },
        };
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [140000]u8 = undefined;
    var pairBuffer: [14000]u8 = undefined;
    var pairAlloc = std.heap.FixedBufferAllocator.init(&pairBuffer);
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day13.txt");
    var inputs = std.mem.split(u8, input, "\n\n");
    var idx: u32 = 0;
    var idxCount: u32 = 0;
    while (inputs.next()) |pair| {
        idx += 1;
        var lines = std.mem.split(u8, std.mem.trim(u8, pair, "\n"), "\n");
        const line1 = lines.next().?;
        const line2 = lines.next().?;
        var i: usize = 0;
        var e1 = try el.parse(pairAlloc.allocator(), line1, &i);
        i = 0;
        var e2 = try el.parse(pairAlloc.allocator(), line2, &i);
        // std.debug.print("e1: {}\n", .{e1});
        // std.debug.print("e2: {}\n", .{e2});
        const eq = (try el.cmp(allocator, e1, e2)).?;
        if (eq) {
            idxCount += idx;
        }
        // std.debug.print("eq: {}\n", .{eq});
        pairAlloc.reset();
    }
    std.debug.print("idxCount: {}\n", .{idxCount});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day13_dummy.txt");
    _ = input;
}
