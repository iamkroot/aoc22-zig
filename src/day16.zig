const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;

const Input = struct {
    const Name = [2]u8;
    const AdjList = [][]u8;
    namegraph: []Name,
    flowrates: []u8,
    lst: AdjList,
    /// Indexes of tunnels with non zero flows
    /// Needed to compress the open bitset size in memo
    nonzeroflows: []u8,
    mindist: AdjList,

    /// string interner
    fn insert_name(ng: []Name, name: []const u8, num_names: *u8) u8 {
        for (ng[0..num_names.*], 0..) |name2, i| {
            if (std.mem.eql(u8, name, &name2)) {
                return @intCast(u8, i);
            }
        }
        ng[num_names.*][0] = name[0];
        ng[num_names.*][1] = name[1];
        num_names.* += 1;
        return num_names.* - 1;
    }

    /// Index of "AA" in namegraph
    fn aa_pos(self: *const Input) u8 {
        var dummy: u8 = 0;
        return Input.insert_name(self.namegraph, "AA", &dummy);
    }

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Input {
        const num_valves = std.mem.count(u8, input, "\n");
        var ng = try allocator.alloc(Name, num_valves);
        var flowrates = try allocator.alloc(u8, num_valves);
        var adjlst = try allocator.alloc([]u8, num_valves);

        var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        var num_names: u8 = 0;
        while (lines.next()) |line| {
            const name = line[6..8];
            const name_i = insert_name(ng, name, &num_names);
            const num_neigh = std.mem.count(u8, line, ",") + 1;
            var neighs = try allocator.alloc(u8, num_neigh);
            {
                var d: usize = 0;
                const fr = @intCast(u8, parseIntChomp(line[23..], &d));
                flowrates[name_i] = fr;
            }
            var i = std.mem.indexOf(u8, line, "valve").? + 5;
            while (line[i] != ' ') {
                i += 1;
            }
            i += 1;
            var s = std.mem.split(u8, line[i..], ", ");
            var j: usize = 0;
            while (s.next()) |neigh| {
                const neigh_i = insert_name(ng, neigh, &num_names);
                neighs[j] = neigh_i;
                j += 1;
            }
            adjlst[name_i] = neighs;
        }
        const nonzero = try calc_nonzero(&flowrates, allocator);
        const mindist = try calc_mindist(&adjlst, allocator);
        return Input{ .namegraph = ng, .flowrates = flowrates, .lst = adjlst, .nonzeroflows = nonzero, .mindist = mindist };
    }

    fn calc_nonzero(flowrates: *[]u8, allocator: std.mem.Allocator) ![]u8 {
        var num_nonzero: usize = flowrates.len - std.mem.count(u8, flowrates.*, &[_]u8{0});
        var nonzero = try allocator.alloc(u8, num_nonzero);
        for (flowrates.*, 0..) |fr, idx| {
            if (fr != 0) {
                nonzero[num_nonzero - 1] = @truncate(u8, idx);
                num_nonzero -= 1;
            }
        }
        return nonzero;
    }

    fn calc_mindist(adjlst: *AdjList, allocator: std.mem.Allocator) !AdjList {
        var dists = try allocator.alloc([]u8, adjlst.len);
        for (dists, 0..) |*d, i| {
            d.* = try allocator.alloc(u8, adjlst.len);
            std.mem.set(u8, d.*, std.math.maxInt(u8));
            for (adjlst.*[i]) |j| {
                dists[i][j] = 1;
            }
            dists[i][i] = 0;
        }
        for (0..adjlst.len) |k| {
            for (0..adjlst.len) |i| {
                for (0..adjlst.len) |j| {
                    dists[i][j] = std.math.min(dists[i][j], std.math.add(u8, dists[i][k], dists[k][j]) catch std.math.maxInt(u8));
                }
            }
        }
        return dists;
    }
};

const ValvesSet = std.bit_set.IntegerBitSet(32);
const MaxScoreMap = std.AutoHashMap(ValvesSet, u32);

const State = struct {
    open: ValvesSet,
    cur_valve: u32,
    score: u32,
    elapsed: u8,
};

fn flow_per_min(input: *const Input, open: ValvesSet) u32 {
    var it = open.iterator(.{});
    var per_min: u32 = 0;
    while (it.next()) |op| {
        per_min += input.flowrates[input.nonzeroflows[op]];
    }
    return per_min;
}

fn recurse(input: *const Input, time_limit: u8, state: State, max_score: ?*MaxScoreMap) !u32 {
    const final = state.score + (time_limit - state.elapsed) * flow_per_min(input, state.open);
    if (max_score) |max_scores| {
        var entry = try max_scores.getOrPut(state.open);
        if (entry.found_existing) {
            entry.value_ptr.* = std.math.max(entry.value_ptr.*, final);
        } else {
            entry.value_ptr.* = final;
        }
    }
    if (state.open.count() == input.nonzeroflows.len or state.elapsed >= time_limit) {
        return final;
    }
    var max: u32 = 0;
    for (input.nonzeroflows, 0..) |valve_idx, i| {
        if (!state.open.isSet(i)) {
            const cost = input.mindist[state.cur_valve][valve_idx] + 1;
            const new_elapsed = state.elapsed + cost;
            if (new_elapsed >= time_limit) {
                const val = state.score + (time_limit - state.elapsed) * flow_per_min(input, state.open);
                max = std.math.max(max, val);
            } else {
                // open it
                const new_score = state.score + flow_per_min(input, state.open) * cost;
                var new_valves = state.open;
                new_valves.set(i);
                const val = try recurse(input, time_limit, State{
                    .open = new_valves,
                    .cur_valve = valve_idx,
                    .score = new_score,
                    .elapsed = new_elapsed,
                }, max_score);
                max = std.math.max(max, val);
            }
        }
    }
    return max;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [10000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day16.txt");
    defer allocator.free(input);
    var inp = try Input.parse(allocator, input);
    if (inp.nonzeroflows.len > ValvesSet.bit_length) {
        return error.input_too_big;
    }
    // for (inp.nonzeroflows[0..inp.num_nonzero]) |i| {
    //     std.debug.print("{} {s} ", .{ i, inp.namegraph[i] });
    // }
    // std.debug.print("\n", .{});
    // std.debug.print("  ", .{});
    // for (inp.namegraph) |n| {
    //     std.debug.print(" {s}", .{n});
    // }
    // std.debug.print("\n", .{});
    // for (mindists, 0..) |ds, i| {
    //     std.debug.print("{s} ", .{inp.namegraph[i]});
    //     for (ds) |d| {
    //         std.debug.print("{:2} ", .{d});
    //     }
    //     std.debug.print("\n", .{});
    // }

    const max = try recurse(&inp, 30, .{ .open = ValvesSet.initEmpty(), .cur_valve = inp.aa_pos(), .elapsed = 0, .score = 0 }, null);
    std.debug.print("max {}\n", .{max});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [256000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const input = try read_input(dataDir, allocator, "day16.txt");
    defer allocator.free(input);
    var inp = try Input.parse(allocator, input);
    if (inp.nonzeroflows.len > ValvesSet.bit_length) {
        return error.input_too_big;
    }
    var max_scores = MaxScoreMap.init(allocator);
    const max = try recurse(&inp, 26, .{ .open = ValvesSet.initEmpty(), .cur_valve = inp.aa_pos(), .elapsed = 0, .score = 0 }, &max_scores);
    std.debug.print("max {}\n", .{max});
    var it = max_scores.iterator();
    var m: u32 = 0;
    while (it.next()) |ent1| {
        var it2 = max_scores.iterator();
        while (it2.next()) |ent2| {
            if (ent1.key_ptr.intersectWith(ent2.key_ptr.*).count() == 0) {
                m = std.math.max(m, ent1.value_ptr.* + ent2.value_ptr.*);
            }
        }
    }
    std.debug.print("m {}\n", .{m});
}
