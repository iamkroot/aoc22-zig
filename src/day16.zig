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

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day16_dummy.txt");
    var inp = try Input.parse(allocator, input);
    std.debug.print("namegraph: {s}\n", .{inp.namegraph});
    std.debug.print("lst: {any}\n", .{inp.lst});
    std.debug.print("flowrates: {any}\n", .{inp.flowrates});
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day16_dummy.txt");
    _ = input;
}
