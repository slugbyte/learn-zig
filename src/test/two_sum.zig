const std = @import("std");
const util = @import("./util.zig");

const Allocator = std.mem.Allocator;

const TwoSumResult = union(enum) {
    success: [2]usize,
    failure: void,
};

/// brute force implamentation
/// Time: O(n^2)
/// Space: O(1)
pub fn twoSumA(comptime T: type, list: []const T, target: T) bool {
    for (list, 0..) |item, index| {
        var i = index + 1;
        while (i < list.len) : (i += 1) {
            if (item + list[i] == target) {
                return true;
            }
        }
    }
    return false;
}

test "twoSumA" {
    util.setTestName("twoSumA");
    const data: [3]u32 = .{ 1, 6, 9 };
    try util.isOk("1,6,9->10", twoSumA(u32, &data, 10));
    try util.isNotOk("1,6,9->11", twoSumA(u32, &data, 11));
}

/// hash mab implamentaion
/// Time: O(n)
/// Space: O(n)
pub fn twoSumB(comptime T: type, list: []const T, target: T, allocator: Allocator) !bool {
    const Map = std.AutoHashMap(T, usize);
    var map = Map.init(allocator);
    defer map.deinit();

    for (list, 0..) |item, index| {
        if (map.get(target - item)) |_| {
            return true;
        } else {
            try map.put(item, index);
        }
    }
    return false;
}

test "twoSumB" {
    util.setTestName("twoSumB");
    const data: [3]u32 = .{ 1, 6, 9 };
    try util.isOk("1,6,9->10", try twoSumB(u32, &data, 10, std.testing.allocator));
    try util.isNotOk("1,6,9->11", try twoSumB(u32, &data, 11, std.testing.allocator));
}
