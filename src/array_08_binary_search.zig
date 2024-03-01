const std = @import("std");
const util = @import("./util.zig");

/// binary search
/// Time: O(log(n))
/// Space: O(1)
pub fn binarySearch(comptime T: type, list: []const T, target: T) ?T {
    var min_i: usize = 0;
    var max_i: usize = list.len;
    var i: usize = @divFloor(max_i, 2);
    while (true) {
        if (list[i] == target) {
            return target;
        }
        if (list[i] < target) {
            min_i = i;
            const remain: usize = max_i - min_i;
            i = min_i + @divFloor(remain, 2);
            if (min_i == i) {
                break;
            }
        }
        if (list[i] > target) {
            max_i = i;
            const remain: usize = max_i - min_i;
            i = min_i + @divFloor(remain, 2);
            if (max_i == i) {
                break;
            }
        }
    }
    return null;
}

test "binarySearch" {
    const data: [9]u32 = .{ 2, 3, 5, 7, 9, 12, 17, 23, 55 };

    try util.isOk("found 7", binarySearch(u32, data[0..], 7).? == 7);
    try util.isOk("found 23", binarySearch(u32, data[0..], 23).? == 23);
    try util.isOk("found 2", binarySearch(u32, data[0..], 2).? == 2);
    try util.isOk("found 55", binarySearch(u32, data[0..], 55).? == 55);
    try util.isOk("not found 1", binarySearch(u32, data[0..], 1) == null);
    try util.isOk("not found 8", binarySearch(u32, data[0..], 8) == null);
    try util.isOk("not found 90", binarySearch(u32, data[0..], 90) == null);
}
