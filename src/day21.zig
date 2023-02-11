const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;

const CalcTy = enum {
    direct,
    add,
    mul,
    sub,
    div,
    fn fromOpCh(ch: u8) CalcTy {
        return switch (ch) {
            '+' => .add,
            '*' => .mul,
            '-' => .sub,
            '/' => .div,
            else => unreachable,
        };
    }
    fn toCh(self: CalcTy) u8 {
        return switch (self) {
            .direct => ' ',
            .add => '+',
            .mul => '*',
            .sub => '-',
            .div => '/',
        };
    }
};

const Pair = std.meta.Tuple(&[_]type{ u32, u32 });

const Node = struct {
    val: i32 = 0,
    calc_ty: CalcTy,
    deps: ?Pair = null,
};

const StringInterner = struct {
    const Self = @This();
    table: std.StringHashMap(u32),
    nextIdx: u32 = 0,

    fn init(allocator: std.mem.Allocator) !Self {
        return Self{ .table = std.StringHashMap(u32).init(allocator) };
    }
    fn insert(self: *Self, val: []const u8) !u32 {
        var e = try self.table.getOrPut(val);
        if (!e.found_existing) {
            e.value_ptr.* = self.nextIdx;
            self.nextIdx += 1;
        }
        return e.value_ptr.*;
    }
    fn lookup(self: *const Self, idx: u32) ?[]const u8 {
        var iter = self.table.iterator();
        while (iter.next()) |e| {
            if (e.value_ptr.* == idx) {
                return e.key_ptr.*;
            }
        }
        return null;
    }
};

const Graph = struct {
    interner: StringInterner,
    graph: std.AutoArrayHashMap(u32, Node),

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Graph {
        var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        const nlines = std.mem.count(u8, std.mem.trim(u8, input, "\n"), "\n") + 1;
        const n = @intCast(u32, nlines);
        var internTable = try StringInterner.init(allocator);
        var graph = std.AutoArrayHashMap(u32, Node).init(allocator);
        try internTable.table.ensureTotalCapacity(n);
        try graph.ensureTotalCapacity(n);
        while (lines.next()) |line| {
            const name = line[0..4];
            const id = try internTable.insert(name);
            var node: Node = undefined;
            if (std.ascii.isDigit(line[6])) {
                var d: usize = 0;
                const val = parseIntChomp(line[6..], &d);
                node = Node{ .val = val, .calc_ty = .direct };
            } else {
                const calc_ty = CalcTy.fromOpCh(line[11]);
                const firstDep = try internTable.insert(line[6..10]);
                const secondDep = try internTable.insert(line[13..17]);
                node = Node{ .val = 0, .calc_ty = calc_ty, .deps = Pair{ firstDep, secondDep } };
            }
            try graph.put(id, node);
        }
        return Graph{ .graph = graph, .interner = internTable };
    }

    fn print(self: *const Graph) void {
        var iter = self.graph.iterator();
        while (iter.next()) |entry| {
            const name = self.interner.lookup(entry.key_ptr.*).?;
            std.debug.print("{s}: ", .{name});
            switch (entry.value_ptr.calc_ty) {
                .direct => std.debug.print("{d}", .{entry.value_ptr.val}),
                else => std.debug.print("{s} {c} {s}", .{ self.interner.lookup(entry.value_ptr.deps.?[0]).?, entry.value_ptr.calc_ty.toCh(), self.interner.lookup(entry.value_ptr.deps.?[1]).? }),
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day21_dummy.txt");
    defer allocator.free(input);
    var graph = try Graph.parse(allocator, input);
    graph.print();
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day21_dummy.txt");
    defer allocator.free(input);
}
