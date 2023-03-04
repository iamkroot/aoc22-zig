const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;

fn absDiff(a: u32, b: u32) u32 {
    return if (a > b) (a - b) else (b - a);
}

const Point = struct {
    x: u32,
    y: u32,
    z: u32,

    fn new(x: u32, y: u32, z: u32) Point {
        return Point{ .x = x, .y = y, .z = z };
    }

    fn touches(self: Point, other: Point) bool {
        return (self.x == other.x and ((self.y == other.y and absDiff(self.z, other.z) <= 1) or
            (self.z == other.z and absDiff(self.y, other.y) <= 1))) or (self.y == other.y and ((self.x == other.x and absDiff(self.z, other.z) <= 1) or
            (self.z == other.z and absDiff(self.x, other.x) <= 1))) or (self.z == other.z and ((self.x == other.x and absDiff(self.y, other.y) <= 1) or
            (self.y == other.y and absDiff(self.x, other.x) <= 1)));
    }
};

fn parsePoints(allocator: std.mem.Allocator, input: []const u8) ![]Point {
    const numPoints = std.mem.count(u8, std.mem.trim(u8, input, "\n"), "\n") + 1;
    var points = try allocator.alloc(Point, numPoints);
    var n: usize = 0;
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    while (lines.next()) |line| {
        var i: usize = 0;
        const x = parseIntChomp(line, &i) + 1;
        i += 1;
        const y = parseIntChomp(line, &i) + 1;
        i += 1;
        const z = parseIntChomp(line, &i) + 1;
        const p = Point.new(std.math.absCast(x), std.math.absCast(y), std.math.absCast(z));
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
    for (points, 0..) |p, i| {
        var numNeigh: u8 = 0;
        for (points, 0..) |otherp, j| {
            if (i != j and p.touches(otherp)) {
                numNeigh += 1;
            }
        }
        openFaces += 6 - numNeigh;
    }
    std.debug.print("openFaces: {}\n", .{openFaces});
}

const State = enum {
    /// Unexplored
    Unknown,
    Rock,
    /// Accesible from outside the formation
    Open,
    /// Not a rock, but inside an air pocket - inaccessible from outside
    Pocket,
};

const Grid = struct {
    grid: [][][]State,

    fn init(allocator: std.mem.Allocator, rocks: []Point) !Grid {
        var maxx: u32 = 0;
        var maxy: u32 = 0;
        var maxz: u32 = 0;
        for (rocks) |rock| {
            maxx = std.math.max(maxx, rock.x);
            maxy = std.math.max(maxy, rock.y);
            maxz = std.math.max(maxz, rock.z);
        }
        var a = try allocator.alloc([][]State, maxx + 2);
        for (a) |*x| {
            x.* = try allocator.alloc([]State, maxy + 2);
            for (x.*) |*y| {
                y.* = try allocator.alloc(State, maxz + 2);
                std.mem.set(State, y.*, State.Unknown);
            }
        }
        for (rocks) |r| {
            a[r.x][r.y][r.z] = State.Rock;
        }
        return Grid{ .grid = a };
    }

    fn set(self: *Grid, point: Point, state: State) void {
        self.grid[point.x][point.y][point.z] = state;
    }
    fn get(self: *const Grid, point: Point) State {
        return self.grid[point.x][point.y][point.z];
    }
    fn getMut(self: *Grid, point: Point) *State {
        return &self.grid[point.x][point.y][point.z];
    }
    /// Add x,y,z to given point and return new point if it is inside the grid bounds
    fn add(self: *const Grid, point: Point, x: i32, y: i32, z: i32) ?Point {
        const a = @intCast(i32, point.x) + x;
        if (a < 0 or a >= self.grid.len) {
            return null;
        }
        const b = @intCast(i32, point.y) + y;
        if (b < 0 or b >= self.grid[0].len) {
            return null;
        }
        const c = @intCast(i32, point.z) + z;
        if (c < 0 or c >= self.grid[0][0].len) {
            return null;
        }
        return Point.new(std.math.absCast(a), std.math.absCast(b), std.math.absCast(c));
    }
    fn neighs(self: *const Grid, of: Point) Neighbours {
        return Neighbours{ .grid = self, .point = of, .idx = 0 };
    }
    const Neighbours = struct {
        grid: *const Grid,
        point: Point,
        idx: usize,
        fn next(self: *Neighbours) ?Point {
            while (self.idx < 6) {
                const n = switch (self.idx) {
                    0 => self.grid.add(self.point, 1, 0, 0),
                    1 => self.grid.add(self.point, 0, 1, 0),
                    2 => self.grid.add(self.point, 0, 0, 1),
                    3 => self.grid.add(self.point, -1, 0, 0),
                    4 => self.grid.add(self.point, 0, -1, 0),
                    5 => self.grid.add(self.point, 0, 0, -1),
                    else => null,
                };
                self.idx += 1;
                if (n != null) {
                    return n;
                }
            }
            return null;
        }
    };
};

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [500000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day18.txt");
    defer allocator.free(input);

    const points = try parsePoints(allocator, input);
    defer allocator.free(points);
    var grid = try Grid.init(allocator, points);

    var stack = std.ArrayList(Point).init(allocator);
    const zero = Point.new(0, 0, 0);
    try stack.append(zero);
    while (stack.popOrNull()) |point| {
        grid.getMut(point).* = .Open;
        var neighs = grid.neighs(point);
        while (neighs.next()) |neigh| {
            if (grid.get(neigh) == .Unknown) {
                try stack.append(neigh);
            }
        }
    }
    var openFaces: u32 = 0;
    for (points) |p| {
        var neighs = grid.neighs(p);
        while (neighs.next()) |neigh| {
            if (grid.get(neigh) == .Open) {
                openFaces += 1;
            }
        }
    }
    std.debug.print("exterior openFaces: {}\n", .{openFaces});
}
