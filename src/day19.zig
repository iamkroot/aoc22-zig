const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;
const MakeParser = @import("utils.zig").MakeParser;

const Size = u32;
const Costs = struct { ore: Size = 0, clay: Size = 0, obs: Size = 0 };

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
    const BPParser = MakeParser("Blueprint \\d+: Each ore robot costs \\d+ ore. Each clay robot costs \\d+ ore. Each obsidian robot costs \\d+ ore and \\d+ clay. Each geode robot costs \\d+ ore and \\d+ obsidian.", Size);

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

const Type = enum(u3) { Ore, Clay, Obs, Geode };
const Types = [_]Type{ .Geode, .Obs, .Clay, .Ore };

const State = struct {
    numOre: Size = 0,
    numClay: Size = 0,
    numObs: Size = 0,
    numGeode: Size = 0,

    numOreBots: Size = 1,
    numClayBots: Size = 0,
    numObsBots: Size = 0,
    numGeodeBots: Size = 0,

    fn makeBot(self: State, bot: Type, bp: BluePrint) ?State {
        var newstate = switch (bot) {
            .Ore => self.subCost(bp.oreCost),
            .Clay => self.subCost(bp.clayCost),
            .Obs => self.subCost(bp.obsCost),
            .Geode => self.subCost(bp.geodeCost),
        };
        return newstate;
    }
    fn addBot(self: *State, bot: Type) void {
        switch (bot) {
            .Ore => self.numOreBots += 1,
            .Clay => self.numClayBots += 1,
            .Obs => self.numObsBots += 1,
            .Geode => self.numGeodeBots += 1,
        }
    }

    fn subCost(self: State, costs: Costs) ?State {
        if (self.numOre < costs.ore) {
            return null;
        }
        if (self.numClay < costs.clay) {
            return null;
        }
        if (self.numObs < costs.obs) {
            return null;
        }
        return self.withRes(self.numOre - costs.ore, self.numClay - costs.clay, self.numObs - costs.obs, self.numGeode);
    }

    fn collectRes(self: *State) void {
        self.numOre += self.numOreBots;
        self.numClay += self.numClayBots;
        self.numObs += self.numObsBots;
        self.numGeode += self.numGeodeBots;
    }

    fn withRes(self: State, numOre: Size, numClay: Size, numObs: Size, numGeode: Size) State {
        return State{ .numOre = numOre, .numClay = numClay, .numObs = numObs, .numGeode = numGeode, .numOreBots = self.numOreBots, .numClayBots = self.numClayBots, .numObsBots = self.numObsBots, .numGeodeBots = self.numGeodeBots };
    }
    fn copy(self: State) State {
        return State{ .numOre = self.numOre, .numClay = self.numClay, .numObs = self.numObs, .numGeode = self.numGeode, .numOreBots = self.numOreBots, .numClayBots = self.numClayBots, .numObsBots = self.numObsBots, .numGeodeBots = self.numGeodeBots };
    }
};

const MemoTable = std.AutoArrayHashMap(std.meta.Tuple(&[_]type{ Size, State }), Size);
var memo: MemoTable = undefined;
// Store the maximum number of miners we need for each resource.
var mrm = Costs{};

fn initMrm(bps: []BluePrint) void {
    mrm = Costs{};
    for (bps) |bp| {
        {
            var v: Size = mrm.clay;
            v = std.math.max(v, bp.clayCost.clay);
            v = std.math.max(v, bp.oreCost.clay);
            v = std.math.max(v, bp.obsCost.clay);
            v = std.math.max(v, bp.geodeCost.clay);
            mrm.clay = v;
        }
        {
            var v: Size = mrm.ore;
            v = std.math.max(v, bp.clayCost.ore);
            v = std.math.max(v, bp.oreCost.ore);
            v = std.math.max(v, bp.obsCost.ore);
            v = std.math.max(v, bp.geodeCost.ore);
            mrm.ore = v;
        }
        {
            var v: Size = mrm.obs;
            v = std.math.max(v, bp.clayCost.obs);
            v = std.math.max(v, bp.oreCost.obs);
            v = std.math.max(v, bp.obsCost.obs);
            v = std.math.max(v, bp.geodeCost.obs);
            mrm.obs = v;
        }
    }
    // std.debug.print("maxRobotMap: {}\n", .{mrm});
}

fn maxGeodes(bp: BluePrint, state: State, remMins: Size) !Size {
    if (remMins == 0) {
        return state.numGeode;
    } else if (remMins == 1) {
        return state.numGeode + state.numGeodeBots;
    } else if (remMins == 2) {
        // we should only create geode bot in this case.
        if (state.makeBot(.Geode, bp) != null) {
            // preexisting geodes, geodes in current min, geodes in next min
            return state.numGeode + state.numGeodeBots + state.numGeodeBots + 1;
        } else {
            return state.numGeode + 2 * state.numGeodeBots;
        }
    }
    if (memo.get(.{ remMins, state })) |v| {
        return v;
    }
    var max: Size = 0;
    for (Types) |bot| {
        if (bot == .Obs and state.numObsBots >= mrm.obs) {
            // we don't need to create a new bot of this kind.
            continue;
        }
        if (bot == .Ore and state.numOreBots >= mrm.ore) {
            continue;
        }
        if (bot == .Clay and state.numClayBots >= mrm.clay) {
            continue;
        }
        var newstate = state.makeBot(bot, bp);
        // std.debug.print("bot: {} {} {any}\n", .{ bot, state, newstate });
        if (newstate) |*newState| {
            // reduce minutes by 1 and collect the new resources
            // std.debug.print("remMins:{} made bot: {}\n", .{ remMins, bot });
            newState.collectRes();
            newState.addBot(bot);
            const m2 = try maxGeodes(bp, newState.*, remMins - 1);
            max = std.math.max(max, m2);
            if (bot == .Geode) {
                try memo.put(.{ remMins, state }, max);

                return m2;
            }
        }
    }

    // get max geodes without creating any new bots
    var oldstate = state.copy();
    oldstate.collectRes();

    const n = try maxGeodes(bp, oldstate, remMins - 1);
    max = std.math.max(max, n);
    try memo.put(.{ remMins, state }, max);
    return max;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    // var buffer: [14000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = std.heap.page_allocator;
    const input = try read_input(dataDir, allocator, "day19.txt");
    defer allocator.free(input);
    const bps = try parseInput(allocator, input);
    defer allocator.free(bps);
    initMrm(bps);
    std.debug.print("bps{any}\n", .{bps});
    var quality: Size = 0;
    for (bps, 0..) |bp, i| {
        memo = MemoTable.init(allocator);
        const numGeodes = try maxGeodes(bp, State{}, 24);
        const qual = numGeodes * (@intCast(Size, i) + 1);
        std.debug.print("quality: {} {}\n", .{ i, qual });
        quality += qual;
        memo.deinit();
    }
    std.debug.print("numGeodes: {}\n", .{quality});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    const allocator = std.heap.page_allocator;
    const input = try read_input(dataDir, allocator, "day19.txt");
    defer allocator.free(input);
    const bps = try parseInput(allocator, input);
    defer allocator.free(bps);
    std.debug.print("bps{any}\n", .{bps});
    initMrm(bps[0..3]);

    var quality: u64 = 1;
    for (bps[0..std.math.min(3, bps.len)], 0..) |bp, i| {
        memo = MemoTable.init(allocator);
        const numGeodes = try maxGeodes(bp, State{}, 32);
        std.debug.print("quality: {} {}\n", .{ i, numGeodes });
        quality *= @intCast(u64, numGeodes);
        memo.deinit();
    }
    std.debug.print("quality: {}\n", .{quality});
}
