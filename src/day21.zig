const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;

const Op = enum {
    direct,
    add,
    mul,
    sub,
    div,
    fn fromCh(ch: u8) Op {
        return switch (ch) {
            '+' => .add,
            '*' => .mul,
            '-' => .sub,
            '/' => .div,
            else => unreachable,
        };
    }
    fn toCh(self: Op) u8 {
        return switch (self) {
            .add => '+',
            .mul => '*',
            .sub => '-',
            .div => '/',
            else => unreachable,
        };
    }
    fn interp(self: Op, val1: i64, val2: i64) i64 {
        return switch (self) {
            .direct => val1,
            .add => val1 + val2,
            .mul => val1 * val2,
            .sub => val1 - val2,
            .div => @divExact(val1, val2),
        };
    }
    // calculate x s.t. "(x binop other) == target" OR "(other binop x) == target", depending on pos
    fn invert(self: Op, pos: HumanPos, other: i64, target: i64) i64 {
        return switch (self) {
            .direct => target,
            .add => target - other,
            .mul => @divExact(target, other),
            .sub => switch (pos) {
                .left => other + target,
                .right => other - target,
                else => unreachable,
            },
            .div => switch (pos) {
                .left => other * target,
                .right => @divExact(target, other),
                else => unreachable,
            },
        };
    }
};

const Pair = std.meta.Tuple(&[_]type{ u32, u32 });

const Node = struct {
    val: i64 = 0,
    op: Op,
    deps: ?Pair = null,
    parent: ?u32 = null,
    // Store the direction to humn node for each subtree
    human_pos: HumanPos = .none,

    fn calc(self: *Node, graph: *const Graph) void {
        if (self.val != 0) {
            return;
        }
        const ds = self.deps.?;
        self.val = self.op.interp(graph.graph.get(ds[0]).?.val, graph.graph.get(ds[1]).?.val);
    }
};

const HumanPos = enum {
    // left child
    left,
    // right child
    right,
    // cur node is humn
    cur,
    // human node is not in the current node's subtree
    none,
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
        var humanId: u32 = undefined;
        while (lines.next()) |line| {
            const name = line[0..4];
            const id = try internTable.insert(name);
            if (std.mem.eql(u8, name, "root")) {
                rootId = id;
            } else if (std.mem.eql(u8, name, "humn")) {
                humanId = id;
            }
            var node: Node = undefined;
            if (std.ascii.isDigit(line[6])) {
                var d: usize = 0;
                const val = parseIntChomp(line[6..], &d);
                node = Node{ .val = val, .op = .direct };
            } else {
                const op = Op.fromCh(line[11]);
                const firstDep = try internTable.insert(line[6..10]);
                const secondDep = try internTable.insert(line[13..17]);
                node = Node{ .val = 0, .op = op, .deps = Pair{ firstDep, secondDep } };
            }
            try graph.put(id, node);
        }

        // populate parents
        var iter = graph.iterator();
        while (iter.next()) |e| {
            if (e.value_ptr.deps) |deps| {
                graph.getPtr(deps[0]).?.parent = e.key_ptr.*;
                graph.getPtr(deps[1]).?.parent = e.key_ptr.*;
            }
        }

        // populate human_pos
        {
            var curNodeId = humanId;
            var dir = HumanPos.cur;
            while (true) {
                var cur = graph.getPtr(curNodeId).?;
                cur.human_pos = dir;
                if (cur.parent) |parentId| {
                    const parentNode = graph.getPtr(parentId).?;
                    dir = if (parentNode.deps.?[0] == curNodeId) HumanPos.left else HumanPos.right;
                    curNodeId = parentId;
                } else {
                    // std.debug.print("reached root!\n", .{});
                    break;
                }
            }
        }
        return Graph{ .graph = graph, .interner = internTable, .rootId = rootId };
    }

    fn print(self: *const Graph) void {
        var iter = self.graph.iterator();
        while (iter.next()) |entry| {
            const name = self.interner.lookup(entry.key_ptr.*).?;
            std.debug.print("{s}: ", .{name});
            switch (entry.value_ptr.op) {
                .direct => std.debug.print("{d}", .{entry.value_ptr.val}),
                else => std.debug.print("{s} {c} {s}", .{ self.interner.lookup(entry.value_ptr.deps.?[0]).?, entry.value_ptr.op.toCh(), self.interner.lookup(entry.value_ptr.deps.?[1]).? }),
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
            if (e.value_ptr.op == .direct) {
                try q.enqueue(e.key_ptr.*);
            }
        }
    }
    while (q.dequeue()) |n| {
        const nodeId = n;
        const node = graph.graph.getPtr(nodeId).?;
        if (node.parent) |parentId| {
            const parentNode = graph.graph.getPtr(parentId).?;
            const otherDepId: u32 = if (parentNode.deps.?[0] == nodeId) parentNode.deps.?[1] else parentNode.deps.?[0];
            const otherDepNode = graph.graph.getPtr(otherDepId).?;
            if (otherDepNode.val != 0) {
                parentNode.calc(graph);
                try q.enqueue(parentId);
            }
        } else {
            break;
        }
    }
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [400000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day21.txt");
    defer allocator.free(input);
    var graph = try Graph.parse(allocator, input);
    try toposort(&graph, allocator);
    std.debug.print("root: {}\n", .{graph.graph.get(graph.rootId).?.val});
    // ideally we should free the graph, but buffer will be dropped anyway...
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [400000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day21.txt");
    defer allocator.free(input);
    var graph = try Graph.parse(allocator, input);
    // graph.print();
    try toposort(&graph, allocator);
    {
        var target: i64 = 0;
        var curNodeId = graph.rootId;
        while (true) {
            const curNode = graph.graph.getPtr(curNodeId).?;
            switch (curNode.human_pos) {
                .right, .left => {
                    const d = curNode.deps.?;
                    const otherId = if (curNode.human_pos == .left) d[1] else d[0];
                    const otherNode = graph.graph.getPtr(otherId).?;
                    target = if (curNodeId == graph.rootId)
                        otherNode.val
                    else
                        curNode.op.invert(curNode.human_pos, otherNode.val, target);
                    curNodeId = if (curNode.human_pos == .left) d[0] else d[1];
                },
                .cur => {
                    std.debug.print("target: {}\n", .{target});
                    break;
                },
                .none => unreachable,
            }
        }
    }
}
