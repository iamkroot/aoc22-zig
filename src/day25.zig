const std = @import("std");
const read_input = @import("input.zig").read_input;

const Digit = enum(u8) {
    two = '2',
    one = '1',
    zero = '0',
    minus_one = '-',
    minus_two = '=',
    fn fromCh(ch: u8) Digit {
        return @intToEnum(Digit, ch);
    }
    fn fromInt(i: i32) Digit {
        return switch (i) {
            2 => .two,
            1 => .one,
            0 => .zero,
            -1 => .minus_one,
            -2 => .minus_two,
            else => unreachable,
        };
    }
    fn toInt(self: Digit) i32 {
        return switch (self) {
            .two => 2,
            .one => 1,
            .zero => 0,
            .minus_one => -1,
            .minus_two => -2,
        };
    }
    fn chToInt(ch: u8) i32 {
        return Digit.toInt(Digit.fromCh(ch));
    }
    fn add(l: Digit, r: Digit, carry: *Digit) Digit {
        // can range from [-5,5]
        std.debug.assert(carry.* != .two and carry.* != .minus_two);
        var res = l.toInt() + r.toInt() + carry.toInt();
        switch (res) {
            3...5 => {
                carry.* = .one;
                return Digit.fromInt(res - 5);
            },
            -2...2 => {
                carry.* = .zero;
                return Digit.fromInt(res);
            },
            -5...-3 => {
                carry.* = .minus_one;
                return Digit.fromInt(res + 5);
            },
            else => {
                unreachable();
            },
        }
    }
};

const Base5 = struct {
    digs: []Digit,
    pub fn format(
        self: Base5,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        for (self.digs) |d| {
            try writer.print("{c}", .{@enumToInt(d)});
        }
    }
};

fn toBase10(input: []const u8) i32 {
    var num: i32 = 0;
    var pow: i32 = @intCast(i32, input.len) - 1;
    for (input) |c| {
        num += Digit.chToInt(c) * (std.math.powi(i32, 5, pow) catch unreachable);
        pow -= 1;
    }
    return num;
}

fn add(left: Base5, right: Base5, allocator: std.mem.Allocator) !std.ArrayList(Digit) {
    std.debug.print("adding {} and {}\n", .{ left, right });
    var res = try std.ArrayList(Digit).initCapacity(allocator, @max(left.digs.len, right.digs.len));
    const minlen = @min(left.digs.len, right.digs.len);
    std.mem.reverse(Digit, left.digs);
    std.mem.reverse(Digit, right.digs);
    var carry: Digit = .zero;
    for (left.digs[0..minlen], right.digs[0..minlen]) |l, r| {
        const n = Digit.add(l, r, &carry);
        std.debug.print("n, carry: {} {}\n", .{ n, carry });
        try res.append(n);
    }
    if (left.digs.len > minlen) {
        for (left.digs[minlen..]) |d| {
            const n = Digit.add(d, .zero, &carry);
            std.debug.print("l n, carry: {} {}\n", .{ n, carry });
            try res.append(n);
        }
    } else if (right.digs.len > minlen) {
        for (right.digs[minlen..]) |d| {
            const n = Digit.add(d, .zero, &carry);
            std.debug.print("r n, carry: {} {}\n", .{ n, carry });
            try res.append(n);
        }
    }
    if (carry != .zero) {
        try res.append(carry);
    }
    std.mem.reverse(Digit, res.items);
    std.debug.print("res: {any}\n", .{Base5{ .digs = res.items }});
    return res;
}

fn addWrapper(left: []const u8, right: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var l = try allocator.alloc(Digit, left.len);
    defer allocator.free(l);
    var r = try allocator.alloc(Digit, right.len);
    defer allocator.free(r);
    for (left, l) |ch, *d| {
        d.* = Digit.fromCh(ch);
    }
    for (right, r) |ch, *d| {
        d.* = Digit.fromCh(ch);
    }
    const res = try add(Base5{ .digs = l }, Base5{ .digs = r }, allocator);
    defer res.deinit();
    var result = try allocator.alloc(u8, res.items.len);
    for (res.items, result) |d, *ch| {
        ch.* = @enumToInt(d);
    }
    return result;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day25.txt");
    defer allocator.free(input);
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    var res: []u8 = try allocator.alloc(u8, 1);
    res[0] = '0';
    while (lines.next()) |line| {
        const newres = try addWrapper(line, res, allocator);
        allocator.free(res);
        res = newres;
    }
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day25_dummy.txt");
    defer allocator.free(input);
}
