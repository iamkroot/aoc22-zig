const std = @import("std");
const read_input = @import("input.zig").read_input;
const parseIntChomp = @import("utils.zig").parseIntChomp;

const Input = struct {
    const Name = [2]u8;
    const AdjList = [][]u8;
    namegraph: []Name,
    flowrates: []u8,
    lst: AdjList,
    /// Store index of tunnels with non-zero flow rates
    /// Needed to compress the open_valves bitset size in memo
    nonzeroflows: []u8,
    num_nonzero: u8,

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

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Input {
        const num_valves = std.mem.count(u8, input, "\n");
        var ng = try allocator.alloc(Name, num_valves);
        var flowrates = try allocator.alloc(u8, num_valves);
        var adjlst = try allocator.alloc([]u8, num_valves);
        var nonzero = try allocator.alloc(u8, num_valves);
        std.mem.set(u8, nonzero, 0); // dummy val

        var lines = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        var num_names: u8 = 0;
        var num_nonzero: u8 = 0;
        while (lines.next()) |line| {
            const name = line[6..8];
            const name_i = insert_name(ng, name, &num_names);
            const num_neigh = std.mem.count(u8, line, ",") + 1;
            var neighs = try allocator.alloc(u8, num_neigh);
            {
                var d: usize = 0;
                const fr = @intCast(u8, parseIntChomp(line[23..], &d));
                flowrates[name_i] = fr;
                if (fr != 0) {
                    nonzero[name_i] = num_nonzero;
                    num_nonzero += 1;
                }
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
        return Input{ .namegraph = ng, .flowrates = flowrates, .lst = adjlst, .num_nonzero = num_nonzero, .nonzeroflows = nonzero };
    }
};

var memo: [][][]u32 = undefined;
const BS = std.bit_set.IntegerBitSet(32);

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
        ovb2.set(inp.nonzeroflows[cur_valve]);
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

const Memo2Key = struct {
    remtime: u8,
    eleremtime: u8,
    cur_valve: u8,
    ele_valve: u8,
    ov_mask: BS,

    fn new(remtime: u8, eleremtime: u8, cur_valve: u8, ele_valve: u8, ov_mask: BS) Memo2Key {
        return Memo2Key{ .remtime = remtime, .eleremtime = eleremtime, .cur_valve = cur_valve, .ele_valve = ele_valve, .ov_mask = ov_mask };
    }
};

// var memo2x: [][][][][]u32 = undefined;
var memo2: std.AutoHashMap(Memo2Key, u32) = undefined;

fn getMax2(inp: Input, open_valves: []bool, ovb: BS, cur_valve: u8, ele_valve: u8, remtime: u8, eleremtime: u8) !u32 {
    if (remtime <= 1 and eleremtime <= 1) {
        return 0;
    }
    const memokey = Memo2Key.new(remtime, eleremtime, cur_valve, ele_valve, ovb);
    if (memo2.get(memokey)) |val| {
        // const oldval = memo2x[remtime][eleremtime][cur_valve][ele_valve][ovb.mask];
        // std.debug.print("val: {} {} {}\n", .{ memokey, val, oldval });
        return val;
    }
    var max: u32 = 0;

    // first try opening self
    if (remtime > 1 and !open_valves[cur_valve] and inp.flowrates[cur_valve] != 0) {
        var newremtime = remtime - 1; // one minute to open it
        // remaining contribution
        var selfcontrib = @intCast(u32, inp.flowrates[cur_valve]) * newremtime;
        open_valves[cur_valve] = true;
        var ovb2 = ovb;
        ovb2.set(inp.nonzeroflows[cur_valve]);

        if (eleremtime > 1 and !open_valves[ele_valve] and inp.flowrates[ele_valve] != 0) {
            // first open ele_valve
            var neweleremtime = eleremtime - 1;
            var elecontrib = @intCast(u32, inp.flowrates[ele_valve]) * neweleremtime;
            open_valves[ele_valve] = true;
            ovb2.set(inp.nonzeroflows[ele_valve]);
            for (inp.lst[cur_valve]) |neigh| {
                for (inp.lst[ele_valve]) |eleneigh| {
                    const withself = try getMax2(inp, open_valves, ovb2, neigh, eleneigh, newremtime - 1, neweleremtime - 1);
                    max = std.math.max(max, withself + selfcontrib + elecontrib);
                }
            }
            ovb2.unset(inp.nonzeroflows[ele_valve]);
            open_valves[ele_valve] = false;
        }
        for (inp.lst[cur_valve]) |neigh| {
            if (eleremtime > 1) {
                for (inp.lst[ele_valve]) |eleneigh| {
                    const withself = try getMax2(inp, open_valves, ovb2, neigh, eleneigh, newremtime - 1, eleremtime - 1);
                    max = std.math.max(max, withself + selfcontrib);
                }
            } else {
                // don't move the elephant
                const withself = try getMax2(inp, open_valves, ovb2, neigh, ele_valve, newremtime - 1, 0);
                max = std.math.max(max, withself + selfcontrib);
            }
        }
        // ovb.unset(cur_valve);
        open_valves[cur_valve] = false;
    }
    // check results without self
    var ovb2 = ovb;

    if (remtime > 1) {
        if (eleremtime > 1 and !open_valves[ele_valve] and inp.flowrates[ele_valve] != 0) {
            // open ele_valve
            var neweleremtime = eleremtime - 1;
            var elecontrib = @intCast(u32, inp.flowrates[ele_valve]) * neweleremtime;
            open_valves[ele_valve] = true;
            ovb2.set(inp.nonzeroflows[ele_valve]);
            for (inp.lst[cur_valve]) |neigh| {
                for (inp.lst[ele_valve]) |eleneigh| {
                    const withself = try getMax2(inp, open_valves, ovb2, neigh, eleneigh, remtime - 1, neweleremtime - 1);
                    max = std.math.max(max, withself + elecontrib);
                }
            }
            ovb2.unset(inp.nonzeroflows[ele_valve]);
            open_valves[ele_valve] = false;
        }
        for (inp.lst[cur_valve]) |neigh| {
            if (eleremtime > 1) {
                for (inp.lst[ele_valve]) |eleneigh| {
                    const withoutself = try getMax2(inp, open_valves, ovb, neigh, eleneigh, remtime - 1, eleremtime - 1);
                    max = std.math.max(max, withoutself);
                }
            } else {
                const withoutself = try getMax2(inp, open_valves, ovb, neigh, ele_valve, remtime - 1, 0);
                max = std.math.max(max, withoutself);
            }
        }
    } else if (eleremtime > 1) {
        if (eleremtime > 1 and !open_valves[ele_valve] and inp.flowrates[ele_valve] != 0) {
            // open ele_valve
            var neweleremtime = eleremtime - 1;
            var elecontrib = @intCast(u32, inp.flowrates[ele_valve]) * neweleremtime;
            open_valves[ele_valve] = true;
            ovb2.set(inp.nonzeroflows[ele_valve]);
            for (inp.lst[cur_valve]) |neigh| {
                for (inp.lst[ele_valve]) |eleneigh| {
                    const withself = try getMax2(inp, open_valves, ovb2, neigh, eleneigh, 0, neweleremtime - 1);
                    max = std.math.max(max, withself + elecontrib);
                }
            }
            ovb2.unset(inp.nonzeroflows[ele_valve]);
            open_valves[ele_valve] = false;
        }
        for (inp.lst[ele_valve]) |eleneigh| {
            const withoutself = try getMax2(inp, open_valves, ovb, cur_valve, eleneigh, 0, eleremtime - 1);
            max = std.math.max(max, withoutself);
        }
    }
    if (remtime == 25) {
        std.debug.print("cur_valve, ele_valve, max: {} {} {}\n", .{ cur_valve, ele_valve, max });
    }
    // memo2x[remtime][eleremtime][cur_valve][ele_valve][ovb.mask] = max;
    try memo2.put(memokey, max);
    if (memo2.count() % 1000000 == 0) {
        std.debug.print("size: {} {}\n", .{ memo2.count(), memo2.capacity() });
    }
    return max;
}

pub fn part1(dataDir: std.fs.Dir) !void {
    // var buffer: [16000000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();
    const allocator = std.heap.page_allocator;
    const input = try read_input(dataDir, allocator, "day16.txt");
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
            y.* = try allocator.alloc(u32, std.math.pow(usize, 2, inp.num_nonzero));
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
    const allocator = std.heap.page_allocator;
    const input = try read_input(dataDir, allocator, "day16.txt");
    var inp = try Input.parse(allocator, input);
    std.debug.print("namegraph: {s}\n", .{inp.namegraph});
    std.debug.print("lst: {any}\n", .{inp.lst});
    std.debug.print("flowrates: {any}\n", .{inp.flowrates});

    const TIME: u32 = 26;

    std.debug.print("pow: {}\n", .{std.math.pow(usize, 2, inp.num_nonzero)});

    const size = (TIME) * (TIME) * inp.lst.len * inp.lst.len * std.math.pow(usize, 2, inp.num_nonzero);
    std.debug.print("size: {}\n", .{size});
    std.debug.print("memokeysize: {}\n", .{@sizeOf(Memo2Key)});
    // return;

    // memo2x = try allocator.alloc([][][][]u32, TIME + 1);
    // for (memo2x) |*x| {
    //     x.* = try allocator.alloc([][][]u32, TIME + 1);
    //     for (x.*) |*y| {
    //         y.* = try allocator.alloc([][]u32, inp.lst.len);
    //         for (y.*) |*z| {
    //             z.* = try allocator.alloc([]u32, inp.lst.len);
    //             for (z.*) |*w| {
    //                 w.* = try allocator.alloc(u32, std.math.pow(usize, 2, inp.num_nonzero));
    //                 std.mem.set(u32, w.*, std.math.maxInt(u32));
    //             }
    //         }
    //     }
    // }
    var nn = @intCast(u8, inp.lst.len);
    const AApos = Input.insert_name(inp.namegraph, "AA", &nn);
    var max: u32 = 0;
    var open_valves = try allocator.alloc(bool, inp.lst.len);

    memo2 = std.AutoHashMap(Memo2Key, u32).init(allocator);

    std.mem.set(bool, open_valves, false);
    var ovb = BS.initEmpty();
    const v = try getMax2(inp, open_valves, ovb, AApos, AApos, TIME, TIME);
    max = std.math.max(max, v);
    std.debug.print("memo2 size: {}\n", .{ memo2.count() });

    std.debug.print("max: {}\n", .{max});
}
