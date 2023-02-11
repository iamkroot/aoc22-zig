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
    fn interp(self: CalcTy, val1: i64, val2: i64) i64 {
        return switch (self) {
            .direct => val1,
            .add => val1 + val2,
            .mul => val1 * val2,
            .sub => val1 - val2,
            .div => @divExact(val1, val2),
        };
    }
};

const Pair = std.meta.Tuple(&[_]type{ u32, u32 });

const Node = struct {
    val: i64 = 0,
    calc_ty: CalcTy,
    deps: ?Pair = null,
    rev_deps: std.ArrayList(u32),

    fn calc(self: *Node, graph: *const Graph) void {
        if (self.val != 0) {
            return;
        }
        const ds = self.deps.?;
        self.val = self.calc_ty.interp(graph.graph.get(ds[0]).?.val, graph.graph.get(ds[1]).?.val);
    }
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
    rootId: u32,

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Graph {
        var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        const nlines = std.mem.count(u8, std.mem.trim(u8, input, "\n"), "\n") + 1;
        const n = @intCast(u32, nlines);
        var internTable = try StringInterner.init(allocator);
        var graph = std.AutoArrayHashMap(u32, Node).init(allocator);
        try internTable.table.ensureTotalCapacity(n);
        try graph.ensureTotalCapacity(n);
        var rootId: u32 = undefined;
        while (lines.next()) |line| {
            const name = line[0..4];
            const id = try internTable.insert(name);
            if (std.mem.eql(u8, name, "root")) {
                rootId = id;
            }
            var node: Node = undefined;
            if (std.ascii.isDigit(line[6])) {
                var d: usize = 0;
                const val = parseIntChomp(line[6..], &d);
                node = Node{ .val = val, .calc_ty = .direct, .rev_deps = std.ArrayList(u32).init(allocator) };
            } else {
                const calc_ty = CalcTy.fromOpCh(line[11]);
                const firstDep = try internTable.insert(line[6..10]);
                const secondDep = try internTable.insert(line[13..17]);
                node = Node{ .val = 0, .calc_ty = calc_ty, .deps = Pair{ firstDep, secondDep }, .rev_deps = std.ArrayList(u32).init(allocator) };
            }
            try graph.put(id, node);
        }

        // populate rev_deps
        var iter = graph.iterator();
        while (iter.next()) |e| {
            if (e.value_ptr.deps) |deps| {
                try graph.getPtr(deps[0]).?.rev_deps.append(e.key_ptr.*);
                try graph.getPtr(deps[1]).?.rev_deps.append(e.key_ptr.*);
            }
        }
        return Graph{ .graph = graph, .interner = internTable, .rootId = rootId };
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

pub fn Queue(comptime Child: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: Child,
            next: ?*This.Node,
        };
        gpa: std.mem.Allocator,
        start: ?*This.Node,
        end: ?*This.Node,

        pub fn init(gpa: std.mem.Allocator) This {
            return This{
                .gpa = gpa,
                .start = null,
                .end = null,
            };
        }
        pub fn enqueue(this: *This, value: Child) !void {
            const node = try this.gpa.create(This.Node);
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

fn toposort(graph: *Graph, allocator: std.mem.Allocator) !void {

    var q = Queue(u32).init(allocator);
    {
        var iter = graph.graph.iterator();
        while (iter.next()) |e| {
            if (e.value_ptr.calc_ty == .direct) {
                try q.enqueue(e.key_ptr.*);
            }
        }
    }
    while (q.dequeue()) |n| {
        const nodeId = n;
        const node = graph.graph.getPtr(nodeId).?;
        for (node.rev_deps.items) |childId| {
            const childNode = graph.graph.getPtr(childId).?;
            const otherDepId: u32 = if (childNode.deps.?[0] == nodeId) childNode.deps.?[1] else childNode.deps.?[0];
            const otherDepNode = graph.graph.getPtr(otherDepId).?;
            if (otherDepNode.val != 0) {
                childNode.calc(graph);
                try q.enqueue(childId);
            }
        }
    }
    std.debug.print("root {}\n", .{graph.graph.get(graph.rootId).?.val});
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [1400000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day21.txt");
    defer allocator.free(input);
    var graph = try Graph.parse(allocator, input);
    graph.print();
    try toposort(&graph, allocator);
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day21_dummy.txt");
    defer allocator.free(input);
}
