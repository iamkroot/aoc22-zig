const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;

const Input = struct {
    const Name = [2]u8;
    const AdjList = [][]u8;
    namegraph: []Name,
    flowrates: []u8,
    lst: AdjList,

    fn insert_name(ng: []Name, name: []const u8, num_names: *u8) u8 {
        for (ng[0..num_names.*]) |name2, i| {
            if (std.mem.eql(u8, name, &name2)) {
                return @intCast(u8, i);
            }
        }
        ng[num_names.*][0] = name[0];
        ng[num_names.*][1] = name[1];
        num_names.* += 1;
        return num_names.* - 1;
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
                flowrates[name_i] = @intCast(u8, parseIntChomp(line[23..], &d));
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
        return Input{ .namegraph = ng, .flowrates = flowrates, .lst = adjlst };
    }
};

var memo: [][][]u32 = undefined;
const BS = std.bit_set.IntegerBitSet(64);

fn getMax(inp: Input, open_valves: []bool, ovb: BS, cur_valve: u8, prev_valve: u8, remtime: u8) u32 {
    if (remtime <= 1) {
        return 0;
    }
    if (memo[remtime][cur_valve][ovb.mask] != std.math.maxInt(u32)) {
        return memo[remtime][cur_valve][ovb.mask];
    }
    _ = prev_valve;
    // std.debug.print("cur_valve, prev_valve, remtime, open_valves: {} {} {} {any}\n", .{ cur_valve, prev_valve, remtime, open_valves });
    var newremtime = remtime;
    var selfcontrib: u32 = 0;
    var max: u32 = 0;

    // first try opening self
    if (!open_valves[cur_valve] and inp.flowrates[cur_valve] != 0) {
        newremtime -= 1; // one minute to open it
        // remaining contribution
        selfcontrib = @intCast(u32, inp.flowrates[cur_valve]) * newremtime;
        if (remtime == 2) {
            return selfcontrib;
        }
    } else {
        selfcontrib = 0;
    }
    if (!open_valves[cur_valve] and inp.flowrates[cur_valve] != 0) {
        // once, try with selfcontrib
        open_valves[cur_valve] = true;
        var ovb2 = ovb;
        ovb2.set(cur_valve);
        for (inp.lst[cur_valve]) |neigh| {
            const withself = getMax(inp, open_valves, ovb2, neigh, cur_valve, newremtime - 1);
            max = std.math.max(max, withself + selfcontrib);
        }
        // ovb.unset(cur_valve);
        open_valves[cur_valve] = false;
    }
    for (inp.lst[cur_valve]) |neigh| {
        const withoutself = getMax(inp, open_valves, ovb, neigh, cur_valve, remtime - 1);
        max = std.math.max(max, withoutself);
    }
    if (remtime == 29) {
        std.debug.print("cur_valve, max: {} {}\n", .{ cur_valve, max });
    }
    memo[remtime][cur_valve][ovb.mask] = max;
    return max;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    // var buffer: [16000000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();
    const allocator = std.heap.page_allocator;
    const input = try read_input(dataDir, allocator, "day16_dummy.txt");
    var inp = try Input.parse(allocator, input);
    std.debug.print("namegraph: {s}\n", .{inp.namegraph});
    std.debug.print("lst: {any}\n", .{inp.lst});
    std.debug.print("flowrates: {any}\n", .{inp.flowrates});

    const TIME: u32 = 30;
    var max: u32 = 0;
    var open_valves = try allocator.alloc(bool, inp.lst.len);

    memo = try allocator.alloc([][]u32, TIME + 1);
    for (memo) |*x| {
        x.* = try allocator.alloc([]u32, inp.lst.len);
        for (x.*) |*y| {
            y.* = try allocator.alloc(u32, std.math.pow(usize, 2, inp.lst.len));
            std.mem.set(u32, y.*, std.math.maxInt(u32));
        }
    }
    var nn = @intCast(u8, inp.lst.len);
    const AApos = Input.insert_name(inp.namegraph, "AA", &nn);

    std.mem.set(bool, open_valves, false);
    for (memo) |*x| {
        for (x.*) |*y| {
            std.mem.set(u32, y.*, std.math.maxInt(u32));
        }
    }
    var ovb = BS.initEmpty();
    const v = getMax(inp, open_valves, ovb, AApos, 0, TIME);
    max = std.math.max(max, v);

    std.debug.print("max: {}\n", .{max});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day16_dummy.txt");
    _ = input;
}
