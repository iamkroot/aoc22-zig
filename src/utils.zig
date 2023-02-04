const std = @import("std");

/// `d` will point to the last valid digit
pub fn parseIntChomp(inp: []const u8, d: *usize) i32 {
    var n: i32 = 0;
    var neg: bool = false;
    while (d.* < inp.len) : (d.* += 1) {
        const c = inp[d.*];
        if (c == '-') {
            neg = true;
        } else if (std.ascii.isDigit(c)) {
            n *= 10;
            n += c - '0';
        } else {
            break;
        }
    }
    if (neg) {
        n *= -1;
    }
    return n;
}

/// A comptime parser for parsing integers inside fixed patterns.
/// _Very_ limited in what is allowed. Would be nice to make a parser-combinator out of this.
/// Wishlist:
/// * Report failures- we should check if parseIntChomp parsed at least one digit
/// * Named field captures
/// * Support for '?' modifier on chars
/// * Better parser for the pattern itself. Going META!
pub fn MakeParser(comptime pattern: []const u8, comptime IntTy: type) type {
    const delim = "\\d+";
    const n = comptime std.mem.count(u8, pattern, delim);
    const TupTy = std.meta.Tuple(&[_]type{IntTy} ** n);

    return struct {
        const Self = @This();
        pub fn parse(text: []const u8) TupTy {
            var lens: std.meta.Tuple(&[_]type{usize} ** (n + 1)) = .{0} ** (n + 1);
            comptime {
                var parts = std.mem.split(u8, pattern, delim);
                var i: usize = 0;
                while (parts.next()) |p| {
                    lens[i] = p.len;
                    i += 1;
                }
            }
            var tups: TupTy = .{0} ** n;
            var j: usize = 0;
            inline for (lens) |len, i| {
                if (i == n) {
                    break;
                }
                j += len;
                const val = parseIntChomp(text, &j);
                tups[i] = @intCast(IntTy, val);
            }
            return tups;
        }
    };
}
