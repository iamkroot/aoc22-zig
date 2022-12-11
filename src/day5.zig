const std = @import("std");
const read_input = @import("input.zig").read_input;

fn parseStackLine(line: []const u8, numStacks: u8, list: []u8) void {
    var i: u8 = 1;
    while (i < numStacks * 4) : (i += 4) {
        list[i / 4] = line[i];
    }
}

const Stacks = struct {
    numStacks: u8,
    stacks: []std.ArrayList(u8),
    maxHeight: u32 = 0,
    constructed: bool = false,

    fn init(numStacks: u8, allocator: std.mem.Allocator) !Stacks {
        var stacks = try allocator.alloc(std.ArrayList(u8), numStacks);
        for (stacks) |*stack| {
            stack.* = std.ArrayList(u8).init(allocator);
        }
        return Stacks{
            .numStacks = numStacks,
            .stacks = stacks,
        };
    }

    fn deinit(self: *Stacks, allocator: std.mem.Allocator) void {
        for (self.stacks) |stack| {
            stack.deinit();
        }
        allocator.free(self.stacks);
    }

    fn appendLine(self: *Stacks, linelist: []const u8) !void {
        for (linelist) |v, i| {
            if (v != 32) {
                // we store them in reverse order of stack
                try self.stacks[i].append(v);
            }
        }
    }

    /// Called when all stack lines have been parsed.
    fn done(self: *Stacks) void {
        var maxHeight: u32 = 0;
        for (self.stacks) |stack| {
            maxHeight = std.math.max(maxHeight, @intCast(u32, stack.items.len));
        }
        self.maxHeight = maxHeight;
        // reverse the stacks so that we can pop
        for(self.stacks) | *stack | {
            std.mem.reverse(u8, stack.items);
        }
        self.constructed = true;
    }

    pub fn format(
        self: Stacks,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        var maxHeight: u32 = 0;
        if (self.maxHeight == 0) {
            // if we haven't calculated the max height yet, do it.
            for (self.stacks) |stack| {
                maxHeight = std.math.max(maxHeight, @intCast(u32, stack.items.len));
            }
        } else {
            maxHeight = self.maxHeight;
        }

        var height = maxHeight;

        while (height > 0) : (height -= 1) {
            for (self.stacks) |stack, stackNum| {
                if (stack.items.len >= height) {
                    var idx: usize = undefined;
                    if (!self.constructed) {
                        idx = stack.items.len - height;
                    } else {
                        idx = height - 1;
                    }
                    const ch = stack.items[idx];
                    try writer.print("[{c}]", .{ch});
                } else {
                    try writer.writeAll("   ");
                }
                if (stackNum < self.numStacks + 1) {
                    try writer.writeAll(" ");
                }
            }
            try writer.writeAll("\n");
        }
        for (self.stacks) |_, stackNum| {
            try writer.print(" {d} ", .{stackNum + 1});
            if (stackNum < self.numStacks + 1) {
                try writer.writeAll(" ");
            }
        }
        try writer.writeAll("\n");
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day5_dummy.txt");
    var lines = std.mem.split(u8, input, "\n");

    const head = lines.next().?;

    const numStacks = @intCast(u8, (head.len + 1) / 4);

    var linelist = try allocator.alloc(u8, numStacks);

    var stacks = try Stacks.init(numStacks, allocator);
    defer stacks.deinit(allocator);

    parseStackLine(head, numStacks, linelist);
    try stacks.appendLine(linelist);
    while (lines.next()) |line| {
        if (line[1] == '1') {
            break;
        } else {
            for (linelist) |*v| {
                v.* = 0;
            }
            parseStackLine(line, numStacks, linelist);
            try stacks.appendLine(linelist);
        }
    }
    allocator.free(linelist);
    stacks.done();

    // empty line
    _ = lines.next().?;

    std.debug.print("numStacks: {}\n{any}\n", .{ numStacks, stacks });
}
