const std = @import("std");
const util = @import("util");

const Allocator = std.mem.Allocator;
const Histogram = std.AutoHashMap(u8, u32);
const print = std.debug.print;

// compare two Histograms method
// Time: O(2n)
// Space: O(lhs + rhs)
pub fn isValidAnagramA(lhs: []const u8, rhs: []const u8, allocator: Allocator) !bool {
    if (lhs.len != rhs.len) {
        return false;
    }

    var l_hist = Histogram.init(allocator);
    defer l_hist.deinit();

    var r_hist = Histogram.init(allocator);
    defer r_hist.deinit();

    for (lhs, rhs) |lc, rc| {
        if (l_hist.get(lc)) |value| {
            try l_hist.put(lc, value + 1);
        } else {
            try l_hist.put(lc, 1);
        }

        if (r_hist.get(rc)) |value| {
            try r_hist.put(rc, value + 1);
        } else {
            try r_hist.put(rc, 1);
        }
    }

    for (lhs) |c| {
        if (l_hist.get(c)) |l_value| {
            if (r_hist.get(c)) |r_value| {
                if (l_value != r_value) {
                    return false;
                }
            } else {
                return false;
            }
        }
    }

    return true;
}

test "isAnagramA" {
    util.setTestName("isAnagramA");
    try util.isOk("abc cba", try isValidAnagramA("abc", "cba", std.testing.allocator));
    try util.isNotOk("abe abc", try isValidAnagramA("abe", "abc", std.testing.allocator));
    try util.isNotOk("car horse", try isValidAnagramA("car", "horse", std.testing.allocator));
}

pub fn sortU8Asc(context: void, a: u8, b: u8) bool {
    return std.sort.asc(u8)(context, a, b);
}

// sort two strings and compare
// Time O(log(lhs))
// Space O(lhs + rhs)
pub fn isValidAnagramB(lhs: []const u8, rhs: []const u8, allocator: Allocator) !bool {
    if (lhs.len != rhs.len) {
        return false;
    }

    const left: []u8 = try allocator.dupe(u8, lhs);
    defer allocator.free(left);
    std.mem.sort(u8, left, {}, sortU8Asc);

    const right: []u8 = try allocator.dupe(u8, rhs);
    defer allocator.free(right);
    std.mem.sort(u8, right, {}, sortU8Asc);

    return util.eql(left, right);
}

test "isAnagramB" {
    util.setTestName("isAnagramB");
    try util.isOk("abc cba", try isValidAnagramB("abc", "cba", std.testing.allocator));
    try util.isNotOk("abe abc", try isValidAnagramB("abe", "abc", std.testing.allocator));
    try util.isNotOk("car horse", try isValidAnagramB("car", "horse", std.testing.allocator));
}

// count needles in haystack
// Time: O(n^2)
// Space: O(1)
pub fn isValidAnagramC(lhs: []const u8, rhs: []const u8) bool {
    if (lhs.len != rhs.len) {
        return false;
    }

    for (lhs) |c| {
        if (std.mem.count(u8, lhs, &.{c}) != std.mem.count(u8, rhs, &.{c})) {
            return false;
        }
    }
    return true;
}

test "isAnagramC" {
    util.setTestName("isAnagramC");
    try util.isOk("abc cba", isValidAnagramC("abc", "cba"));
    try util.isNotOk("abe abc", isValidAnagramC("abe", "abc"));
    try util.isNotOk("car horse", isValidAnagramC("car", "horse"));
}
