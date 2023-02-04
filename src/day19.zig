const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;
const MakeParser = @import("utils.zig").MakeParser;

const Costs = struct { ore: u32 = 0, clay: u32 = 0, obs: u32 = 0 };

const BluePrint = struct {
    oreCost: Costs,
    clayCost: Costs,
    obsCost: Costs,
    geodeCost: Costs,

    fn new(oreCost: Costs, clayCost: Costs, obsCost: Costs, geodeCost: Costs) BluePrint {
        return BluePrint{ .oreCost = oreCost, .clayCost = clayCost, .obsCost = obsCost, .geodeCost = geodeCost };
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]BluePrint {
    const n = std.mem.count(u8, std.mem.trim(u8, input, "\n"), "\n") + 1;
    var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
    var bps = try allocator.alloc(BluePrint, n);
    var i: usize = 0;
    const BPParser = MakeParser("Blueprint \\d+: Each ore robot costs \\d+ ore. Each clay robot costs \\d+ ore. Each obsidian robot costs \\d+ ore and \\d+ clay. Each geode robot costs \\d+ ore and \\d+ obsidian.", u32);

    while (lines.next()) |line| {
        const ints = BPParser.parse(line);
        const ore = Costs{ .ore = ints[1] };
        const clay = Costs{ .ore = ints[2] };
        const obs = Costs{ .ore = ints[3], .clay = ints[4] };
        const geode = Costs{ .ore = ints[5], .obs = ints[6] };
        bps[i] = BluePrint.new(ore, clay, obs, geode);
        i += 1;
    }
    return bps;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day19_dummy.txt");
    defer allocator.free(input);
    const bps = try parseInput(allocator, input);
    std.debug.print("bps{any}\n", .{bps});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day19_dummy.txt");
    defer allocator.free(input);
}
