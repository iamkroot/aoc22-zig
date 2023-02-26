const std = @import("std");
const read_input = @import("input.zig").read_input;
const Allocator = std.mem.Allocator;

const I = i64;

const Idx = struct {
    i: I,
    j: I,

    fn add(self: Idx, i: I, j: I) Idx {
        return Idx{
            .i = self.i + i,
            .j = self.j + j,
        };
    }

    fn move(self: Idx, dir: MoveDir) Idx {
        return switch (dir) {
            .n => Idx{ .i = self.i - 1, .j = self.j },
            .e => Idx{ .i = self.i, .j = self.j + 1 },
            .s => Idx{ .i = self.i + 1, .j = self.j },
            .w => Idx{ .i = self.i, .j = self.j - 1 },
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

    const NeighIter = struct {
        center: Idx,
        pos: u4 = 0,
        fn next(self: *NeighIter) ?std.meta.Tuple(&[_]type{ Idx, Dir }) {
            self.pos += if (self.pos < 9) 1 else 0;
            return switch (self.pos) {
                1 => .{ self.center.add(-1, -1), .nw },
                2 => .{ self.center.add(-1, 0), .n },
                3 => .{ self.center.add(-1, 1), .ne },
                4 => .{ self.center.add(0, 1), .e },
                5 => .{ self.center.add(1, 1), .se },
                6 => .{ self.center.add(1, 0), .s },
                7 => .{ self.center.add(1, -1), .sw },
                8 => .{ self.center.add(0, -1), .w },
                else => null,
            };
        }
    };
    fn neighs(self: Idx) NeighIter {
        return NeighIter{ .center = self };
    }
};

const Dir = enum(u3) {
    nw = 0,
    n,
    ne,
    e,
    se,
    s,
    sw,
    w,
};

const MoveDir = enum(u3) {
    n = 1,
    e = 3,
    s = 5,
    w = 7,

    // The next direction it should try to move in.
    fn next(self: MoveDir) MoveDir {
        return switch (self) {
            .n => .s,
            .e => .n,
            .s => .w,
            .w => .e,
        };
    }
    // check if we can move in the dir
    fn checkOpen(self: MoveDir, open_neighs: [8]bool) bool {
        const v = @enumToInt(self);
        const vp = v - 1;
        const vn = if (v < 7) (v + 1) else 0;
        return open_neighs[v] and open_neighs[vp] and open_neighs[vn];
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
    /// Calculate the next pos for the given elf (phase 1)
    fn nextIdx(self: *Self, pos: Idx, start_move_dir: MoveDir) ?Idx {
        var valid_dirs = [_]bool{true} ** 8;
        var no_neigh = true;
        var neighs = pos.neighs();
        if (pos.i == 5 and pos.j == 4) {
            std.debug.print("locs: {any}", .{self});
        }
        while (neighs.next()) |n| {
            if (self.locs.contains(n[0])) {
                valid_dirs[@enumToInt(n[1])] = false;
                no_neigh = false;
            }
        }
        if (no_neigh) {
            // doesn't need to move
            std.debug.print("no neigh\n", .{});
            return null;
        }
        std.debug.print("valid_dirs: {any}\n", .{valid_dirs});
        var move_dir = start_move_dir;
        for (0..4) |_| {
            if (move_dir.checkOpen(valid_dirs)) {
                std.debug.print("can move to: {any}\n", .{move_dir});
                return pos.move(move_dir);
            }
            move_dir = move_dir.next();
        }

        return null;
    }
    fn step(self: *Self, move_dir: MoveDir) !bool {
        std.debug.print("movedir: {any} locs: {any}", .{ move_dir, self });
        var it = self.locs.keyIterator();
        var new_locs = std.AutoHashMap(Idx, void).init(self.locs.allocator);
        try new_locs.ensureTotalCapacity(self.locs.count());
        // map from new_pos -> old_pos, to detect conflicts
        var moved = std.AutoHashMap(Idx, ?Idx).init(self.locs.allocator);
        try moved.ensureTotalCapacity(self.locs.count());
        var any_elf_moved = false;
        while (it.next()) |elf_pos_ptr| {
            const elf_pos = elf_pos_ptr.*;
            std.debug.print("Moving elf at {}\n", .{elf_pos});
            if (self.nextIdx(elf_pos, move_dir)) |next_pos| {
                // even if we don't move due to conflict, some other elf will move
                var gop = moved.getOrPutAssumeCapacity(next_pos);
                if (!gop.found_existing) {
                    // first time we are putting an elf at next_pos
                    // update both the hash tables
                    new_locs.putAssumeCapacity(next_pos, {});
                    gop.value_ptr.* = elf_pos;
                } else {
                    // conflict!
                    // current elf remains in current pos
                    new_locs.putAssumeCapacity(elf_pos, {});
                    // nobody can move to this pos now
                    _ = new_locs.remove(next_pos);
                    // move the prev elf back if we haven't already done so
                    if (gop.value_ptr.*) |prev_elf_old_pos| {
                        new_locs.putAssumeCapacity(prev_elf_old_pos, {});
                        gop.value_ptr.* = null;
                    } else {
                        // this is the THIRD/FOURTH elf trying to move here
                        // we have already undone moved[next_pos]
                    }
                }
                any_elf_moved = true;
            } else {
                // no movement
                new_locs.putAssumeCapacity(elf_pos, {});
            }
        }
        self.locs.deinit();
        moved.deinit();
        self.locs = new_locs;
        return any_elf_moved;
    }
    fn printGrid(self: *Self) u64 {
        // TODO
        var minX: I = std.math.maxInt(I);
        var minY: I = std.math.maxInt(I);
        var maxX: I = std.math.minInt(I);
        var maxY: I = std.math.minInt(I);
        var it = self.locs.keyIterator();
        while (it.next()) |pos| {
            minX = std.math.min(minX, pos.j);
            minY = std.math.min(minY, pos.i);
            maxX = std.math.max(maxX, pos.j);
            maxY = std.math.max(maxY, pos.i);
        }
        std.debug.print("start: {}\n", .{Idx{ .i = minY, .j = minX }});
        var empty: u64 = 0;
        var i = minY;
        while (i <= maxY) : (i += 1) {
            var j = minX;
            while (j <= maxX) : (j += 1) {
                if (self.locs.contains(Idx{ .i = i, .j = j })) {
                    std.debug.print("#", .{});
                } else {
                    empty += 1;
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
        return empty;
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [1400000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day23.txt");
    defer allocator.free(input);
    var map = try Map.parse(allocator, input);
    std.debug.print("map.locs: {any}\n", .{map});
    var move_dir = MoveDir.n;
    for (0..10) |i| {
        std.debug.print("Round {}\n", .{i});
        _ = map.printGrid();
        if (!try map.step(move_dir)) {
            break;
        }
        move_dir = move_dir.next();
    }
    const empty = map.printGrid();
    std.debug.print("empty: {}", .{empty});

    // _ = map.nextIdx(Idx{ .i = 2, .j = 2 }, .n);
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day23_dummy.txt");
    defer allocator.free(input);
}
