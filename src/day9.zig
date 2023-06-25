const std = @import("std");
const read_input = @import("input.zig").read_input;

const Dir = enum {
    n,
    ne,
    e,
    se,
    s,
    sw,
    w,
    nw,
    none,

    fn from_str(c: u8) Dir {
        return switch (c) {
            'U' => Dir.n,
            'D' => Dir.s,
            'R' => Dir.e,
            'L' => Dir.w,
            else => unreachable,
        };
    }
};

const Pos = struct {
    x: i32,
    y: i32,

    fn moven(self: Pos, dir: Dir, numSteps: u32) Pos {
        const steps = @intCast(i32, numSteps);
        return switch (dir) {
            .n => Pos{ .x = self.x, .y = self.y + steps },
            .s => Pos{ .x = self.x, .y = self.y - steps },
            .e => Pos{ .x = self.x + steps, .y = self.y },
            .w => Pos{ .x = self.x - steps, .y = self.y },
            .ne => Pos{ .x = self.x + steps, .y = self.y + steps },
            .se => Pos{ .x = self.x + steps, .y = self.y - steps },
            .nw => Pos{ .x = self.x - steps, .y = self.y + steps },
            .sw => Pos{ .x = self.x - steps, .y = self.y - steps },
            .none => self,
        };
    }
    fn move(self: Pos, dir: Dir) Pos {
        return self.moven(dir, 1);
    }
    fn sameRowOrCol(self: Pos, other: Pos) bool {
        return self.x == other.x or self.y == other.y;
    }
    fn adjacent(self: Pos, other: Pos) bool {
        return std.math.absCast(self.x - other.x) <= 1 and std.math.absCast(self.y - other.y) <= 1;
    }
    fn getDir(self: Pos, target: Pos) Dir {
        if (self.x == target.x and self.y == target.y) {
            // already minimized
            return Dir.none;
        } else if (self.x == target.x) {
            if (self.y < target.y) {
                return Dir.n;
            } else {
                return Dir.s;
            }
        } else if (self.y == target.y) {
            if (self.x < target.x) {
                return Dir.e;
            } else {
                return Dir.w;
            }
        } else if (self.x < target.x) {
            if (self.y < target.y) {
                return Dir.ne;
            } else {
                return Dir.se;
            }
        } else {
            if (self.y < target.y) {
                return Dir.nw;
            } else {
                return Dir.sw;
            }
        }
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [300000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day9.txt");
    var iter = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    var curHeadPos = Pos{ .x = 0, .y = 0 };
    var curTailPos = Pos{ .x = 0, .y = 0 };

    var hist = std.AutoHashMap(Pos, void).init(allocator);
    try hist.put(curTailPos, {});
    while (iter.next()) |line| {
        const headDir = Dir.from_str(line[0]);
        const numSteps = try std.fmt.parseInt(u32, line[2..], 10);
        var step: u32 = 1;
        while (step <= numSteps) : (step += 1) {
            const newHeadPos = curHeadPos.move(headDir);
            curHeadPos = newHeadPos;
            if (curTailPos.adjacent(newHeadPos)) {
                continue;
            }
            const dir = curTailPos.getDir(newHeadPos);
            const newTailPos = curTailPos.move(dir);
            curTailPos = newTailPos;
            try hist.put(curTailPos, {});
        }
    }
    std.debug.print("uniqPositions {}\n", .{hist.count()});
    return;
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = try read_input(dataDir, allocator, "day9.txt");
    var iter = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    var curHeadPos = Pos{ .x = 0, .y = 0 };
    var knots = [_]Pos{.{ .x = 0, .y = 0 }} ** 9;

    var hist = std.AutoHashMap(Pos, void).init(allocator);
    try hist.put(.{ .x = 0, .y = 0 }, {});
    while (iter.next()) |line| {
        const headDir = Dir.from_str(line[0]);
        const numSteps = try std.fmt.parseInt(u32, line[2..], 10);
        var step: u32 = 1;
        while (step <= numSteps) : (step += 1) {
            const newHeadPos = curHeadPos.move(headDir);
            curHeadPos = newHeadPos;
            for (&knots, 0..) |*knot, i| {
                const target = blk: {
                    if (i == 0) {
                        break :blk newHeadPos;
                    } else {
                        break :blk knots[i - 1];
                    }
                };
                if (knot.adjacent(target)) {
                    break;
                } else {
                    const dir = knot.getDir(target);
                    const newPos = knot.move(dir);
                    knot.* = newPos;
                    if (i == 8) {
                        try hist.put(newPos, {});
                    }
                }
            }
        }
    }
    std.debug.print("uniqPositions {}\n", .{hist.count()});
}
