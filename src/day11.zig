const std = @import("std");
const read_input = @import("input.zig").read_input;

fn splitLine(line: []const u8, chars: []const u8) std.mem.SplitIterator(u8) {
    return std.mem.split(u8, std.mem.trim(u8, line, "\n"), chars);
}

const Op = union(enum) { add: i32, mul: i32, sq };

const Monke = struct {
    items: Queue(u64),
    op: Op,
    divBy: u32,
    trueMonke: u32,
    falseMonke: u32,

    pub fn format(
        self: Monke,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{any} {} div:{} t:{} f:{}", .{ self.items, self.op, self.divBy, self.trueMonke, self.falseMonke });
    }
};

pub fn Queue(comptime Child: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        gpa: std.mem.Allocator,
        start: ?*Node,
        end: ?*Node,

        pub fn init(gpa: std.mem.Allocator) This {
            return This{
                .gpa = gpa,
                .start = null,
                .end = null,
            };
        }
        pub fn enqueue(this: *This, value: Child) !void {
            const node = try this.gpa.create(Node);
            node.* = .{ .data = value, .next = null };
            if (this.end) |end| end.next = node //
            else this.start = node;
            this.end = node;
        }
        pub fn dequeue(this: *This) ?Child {
            const start = this.start orelse return null;
            defer this.gpa.destroy(start);
            if (start.next) |next|
                this.start = next
            else {
                this.start = null;
                this.end = null;
            }
            return start.data;
        }
        pub fn format(
            self: Queue(Child),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            var start = self.start orelse null;
            try writer.writeAll("{ ");
            while (start) |node| {
                try writer.print("{} ", .{node.data});
                start = node.next;
            }
            try writer.writeAll("}");
        }
    };
}

fn parse(allocator: std.mem.Allocator, input: []const u8) ![]Monke {
    const numMonke = std.mem.count(u8, input, "Monkey ");
    var monkeyS = splitLine(input, "Monkey ");
    var monkeys = try allocator.alloc(Monke, numMonke);
    while (monkeyS.next()) |monke| {
        if (monke.len == 0) {
            continue;
        }
        var lines = splitLine(monke, "\n");
        var firstLine = splitLine(lines.next().?, ":");
        const monkeNum = try std.fmt.parseInt(u8, firstLine.next().?, 10);

        var startItems = Queue(u64).init(allocator);
        {
            var line2 = splitLine(lines.next().?, ":");
            _ = line2.next().?;
            var nums = splitLine(line2.next().?, ",");
            while (nums.next()) |n| {
                try startItems.enqueue(try std.fmt.parseInt(u64, n[1..], 10));
            }
        }
        var op: Op = undefined;
        {
            var line3 = splitLine(lines.next().?, ":");
            _ = line3.next().?;
            const opS = std.mem.trim(u8, line3.next().?, " ");
            if (std.mem.eql(u8, opS, "new = old * old")) {
                op = .sq;
            } else if (std.mem.eql(u8, opS[0..12], "new = old * ")) {
                op = Op{ .mul = try std.fmt.parseInt(i32, opS[12..], 10) };
            } else if (std.mem.eql(u8, opS[0..12], "new = old + ")) {
                op = Op{ .add = try std.fmt.parseInt(i32, opS[12..], 10) };
            }
        }
        const divBy = try std.fmt.parseInt(u32, lines.next().?[21..], 10);
        const trueMonke = try std.fmt.parseInt(u32, lines.next().?[29..], 10);
        const falseMonke = try std.fmt.parseInt(u32, lines.next().?[30..], 10);
        monkeys[monkeNum] = Monke{
            .items = startItems,
            .op = op,
            .divBy = divBy,
            .trueMonke = trueMonke,
            .falseMonke = falseMonke,
        };
    }
    return monkeys;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day11_dummy.txt");
    var monkeys = try parse(allocator, input);
    std.debug.print("monkeys: {any}\n", .{monkeys});
    const ROUNDS: u32 = 20;
    var i: u32 = 0;
    while (i < ROUNDS) : (i += 1) {
        for (monkeys) |*monke, n| {
            _ = monke;
            _ = n;
        }
    }
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day11_dummy.txt");
    _ = input;
}
