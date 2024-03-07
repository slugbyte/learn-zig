const std = @import("std");
const util = @import("./util.zig");

// Time: O(n^2)
// Space: O(1)
fn bubbleSort(comptime T: type, list: []T) void {
    var i: usize = 0;
    while (i < list.len) : (i += 1) {
        var j: usize = 0;
        while (j < list.len - 1 - i) : (j += 1) {
            if (list[j] > list[j + 1]) {
                const temp = list[j];
                list[j] = list[j + 1];
                list[j + 1] = temp;
            }
        }
    }
}

test "bubbleSort" {
    var data: [5]u8 = .{ 12, 2, 1, 5, 0 };
    bubbleSort(u8, &data);

    try util.isOk("[0] is 0", data[0] == 0);
    try util.isOk("[1] is 1", data[1] == 1);
    try util.isOk("[2] is 2", data[2] == 2);
    try util.isOk("[3] is 5", data[3] == 5);
    try util.isOk("[4] is 12", data[4] == 12);
}
