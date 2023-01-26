const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;

const Point = struct {
    x: i32,
    y: i32,
    z: i32,

    fn new(x: i32, y: i32, z: i32) Point {
        return Point{ .x = x, .y = y, .z = z };
    }

    fn touches(self: Point, other: Point) bool {
        return (self.x == other.x and ((self.y == other.y and std.math.absCast(self.z - other.z) <= 1) or
            (self.z == other.z and std.math.absCast(self.y - other.y) <= 1))) or (self.y == other.y and ((self.x == other.x and std.math.absCast(self.z - other.z) <= 1) or
            (self.z == other.z and std.math.absCast(self.x - other.x) <= 1))) or (self.z == other.z and ((self.x == other.x and std.math.absCast(self.y - other.y) <= 1) or
            (self.y == other.y and std.math.absCast(self.x - other.x) <= 1)));
    }
};

fn parsePoints(allocator: std.mem.Allocator, input: []const u8) ![]Point {
    const numPoints = std.mem.count(u8, std.mem.trim(u8, input, "\n"), "\n") + 1;
    var points = try allocator.alloc(Point, numPoints);
    var n: usize = 0;
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    while (lines.next()) |line| {
        var i: usize = 0;
        const x = parseIntChomp(line, &i);
        i += 1;
        const y = parseIntChomp(line, &i);
        i += 1;
        const z = parseIntChomp(line, &i);
        const p = Point.new(x, y, z);
        points[n] = p;
        n += 1;
    }
    return points;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [65536]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day18.txt");
    defer allocator.free(input);

    const points = try parsePoints(allocator, input);
    defer allocator.free(points);

    var openFaces: u32 = 0;
    for (points) |p, i| {
        var numNeigh: u8 = 0;
        for (points) |otherp, j| {
            if (i != j and p.touches(otherp)) {
                numNeigh += 1;
            }
        }
        openFaces += 6 - numNeigh;
    }
    std.debug.print("openFaces: {}\n", .{openFaces});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day18_dummy.txt");
    defer allocator.free(input);
}
