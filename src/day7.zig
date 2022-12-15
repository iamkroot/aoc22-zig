const std = @import("std");
const read_input = @import("input.zig").read_input;

const DirEntry = union(enum) {
    dir: *DirTree,
    file: u64,
};

const DirTree = std.StringHashMap(DirEntry);

fn printDT(dt: *DirTree, indent: u8) void {
    var it = dt.iterator();
    while (it.next()) |entry| {
        std.debug.print("{}-{s}", .{ indent, entry.key_ptr.* });
        switch (entry.value_ptr.*) {
            .dir => |d| {
                std.debug.print("\n", .{});
                printDT(d, indent + 2);
            },
            .file => |size| {
                std.debug.print(" {d}\n", .{size});
            },
        }
    }
}

fn getSmallNodes(dt: *DirTree, finalSum: *u64) u64 {
    var it = dt.iterator();
    var nodeSize: u64 = 0;
    while (it.next()) |entry| {
        switch (entry.value_ptr.*) {
            .dir => |d| {
                nodeSize += getSmallNodes(d, finalSum);
            },
            .file => |size| {
                nodeSize += size;
            },
        }
    }
    if(nodeSize <= 100000) {
        finalSum.* += nodeSize;
    }
    return nodeSize;
}

fn joinDir(allocator: std.mem.Allocator, parent: []const u8, child: []const u8) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}/", .{ parent, child });
}

fn addDir(allocator: std.mem.Allocator, rootDir: *DirTree, dir: []const u8) !*DirTree {
    var nodeIter = rootDir;
    var parts = std.mem.split(u8, dir, "/");
    while (parts.next()) |part| {
        if (part.len == 0) {
            continue;
        } else {
            var gop = try nodeIter.getOrPut(part);
            if (!gop.found_existing) {
                gop.value_ptr.* = DirEntry{ .dir = try allocator.create(DirTree) };
                gop.value_ptr.dir.* = DirTree.init(allocator);
            } else {
            }
            nodeIter = gop.value_ptr.dir;
        }
    }
    return nodeIter;
}

fn dirnameWithTrailSlashPosix(path: []const u8) ?[]const u8 {
    if (path.len == 0)
        return null;

    var end_index: usize = path.len - 1;
    while (path[end_index] == '/') {
        if (end_index == 0)
            return null;
        end_index -= 1;
    }

    while (path[end_index] != '/') {
        if (end_index == 0)
            return null;
        end_index -= 1;
    }

    if (end_index == 0 and path[0] == '/')
        return path[0..1];

    if (end_index == 0)
        return null;

    if (path[end_index-1] == '/')
        {return path[0..end_index];}
    else
        {return path[0..end_index+1];}
}


pub fn part1(dataDir: std.fs.Dir) !void {
    var buffer: [108000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day7.txt");
    var iter = std.mem.split(u8, std.mem.trim(u8, input, " \n"), "$ ");
    var curDir: []const u8 = undefined;
    var curDirNode: *DirTree = undefined;

    var rootDir2 = DirTree.init(allocator);
    while (iter.next()) |cmd| {
        if (cmd.len == 0) {
            continue;
        }
        const trimmedCmd = std.mem.trim(u8, cmd, "\n");
        var lines = std.mem.split(u8, trimmedCmd, "\n");
        const cmdLine = lines.next().?;
        if (cmdLine[0] == 'c') {
            if (cmdLine[3] == '/') {
                curDir = cmdLine[3..];
            } else if (cmdLine.len >= 5 and std.mem.eql(u8, cmdLine[3..5], "..")) {
                curDir = dirnameWithTrailSlashPosix(curDir).?;

            } else {
                curDir = try joinDir(allocator, curDir, cmdLine[3..]);
            }
            curDirNode = try addDir(allocator, &rootDir2, curDir);
        } else {
            var i: u16 = 0;
            while (lines.next()) |line| : (i += 1) {
                if (std.mem.startsWith(u8, line, "dir ")) {
                    const d = try joinDir(allocator, curDir, line[4..]);
                    _ = d;
                    // _ = try addDir(allocator, &rootDir2, d);
                } else {
                    var parts = std.mem.split(u8, line, " ");
                    const sizeS = parts.next().?;
                    const name = parts.next().?;
                    const size = try std.fmt.parseUnsigned(u64, sizeS, 10);
                    try curDirNode.put(name, DirEntry{ .file = size });
                }
            }
        }
    }
    printDT(&rootDir2, 0);
    var sum: u64 = 0;
    _ = getSmallNodes(&rootDir2, &sum);
    std.debug.print("sum: {}\n", .{ sum });
}

pub fn part2(dataDir: std.fs.Dir) !void {
    var buffer: [14000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const input = try read_input(dataDir, allocator, "day7_dummy.txt");
    _ = input;
}
