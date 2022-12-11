const std = @import("std");
const read_input = @import("input.zig").read_input;

const Outcome = enum(u8) {
    win = 6,
    draw = 3,
    lose = 0,
};

const Play = enum(u8) { rock = 1, paper = 2, scissors = 3};

const Iteration = struct {
    their: Play,
    our: Play,
    fn check(self: Iteration) Outcome {
        return switch (self.their) {
            .rock => switch (self.our) {
                .rock => Outcome.draw,
                .paper => Outcome.win,
                .scissors => Outcome.lose,
            },
            .paper => switch (self.our) {
                .rock => Outcome.lose,
                .paper => Outcome.draw,
                .scissors => Outcome.win,
            },
            .scissors => switch (self.our) {
                .rock => Outcome.win,
                .paper => Outcome.lose,
                .scissors => Outcome.draw,
            },
        };
    }
};

const GameIter = struct {
    input: []const u8 = undefined,
    gameiter: std.mem.SplitIterator(u8) = undefined,

    fn init(input: []const u8) GameIter {
        var iter = std.mem.split(u8, std.mem.trim(u8, input, "\n"), "\n");
        return GameIter{
            .input = input,
            .gameiter = iter,
        };
    }

    fn next(self: *GameIter) ?Iteration {
        if (self.gameiter.next()) |line| {
            const opp = switch (line[0]) {
                'A' => Play.rock,
                'B' => Play.paper,
                'C' => Play.scissors,
                else => unreachable,
            };
            const our = switch (line[2]) {
                'X' => Play.rock,
                'Y' => Play.paper,
                'Z' => Play.scissors,
                else => unreachable,
            };
            return .{ .their = opp, .our = our };
        } else {
            return null;
        }
    }
};

pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [10000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day2.txt");
    var iter = GameIter.init(input);
    var total: u64 = 0;
    while (iter.next()) |game| {
        const outcome = game.check();
        var score = @enumToInt(game.our) + @enumToInt(outcome);
        total += score;
    }
    std.debug.print("total: {}\n", .{ total });
}
