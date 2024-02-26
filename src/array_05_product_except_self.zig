const std = @import("std");
const util = @import("./util.zig");
const print = std.debug.print;

// create an array of nums the product of all other items
// without using /
// Time: O(n)
// space: O(n)
pub fn productExceptSelfA(comptime len: usize, list: []const u32) [len]u32 {
    var prefix: [len]u32 = undefined;
    var postfix: [len]u32 = undefined;
    var result: [len]u32 = undefined;

    for (list, 0..) |item, index| {
        const reverse_index = len - 1 - index;
        if (index == 0) {
            prefix[index] = item;
            postfix[reverse_index] = list[reverse_index];
        } else {
            prefix[index] = item * prefix[index - 1];
            postfix[reverse_index] = list[reverse_index] * postfix[reverse_index + 1];
        }
    }

    const prefixHelper = .{1} ++ prefix;
    const postfixHelper = postfix ++ .{1};

    for (list, 0..) |_, index| {
        result[index] = postfixHelper[index + 1] * prefixHelper[index];
    }

    return result;
}

test "productExceptSelfA" {
    util.setTestName("productExceptSelffA");

    const size = 4;
    // immutable data
    const data: [size]u32 = .{ 3, 4, 5, 7 };
    const result = productExceptSelfA(size, &data);

    try util.isOk("[0] 3-> 140", result[0] == 140);
    try util.isOk("[1] 4-> 105", result[1] == 105);
    try util.isOk("[2] 5-> 84", result[2] == 84);
    try util.isOk("[3] 7-> 60", result[3] == 60);
}

// mutate a slice of nums in lace to be the product of all other items
// without using /
// Time: O(n)
// space: O(n)
pub fn productExceptSelfB(comptime len: usize, list: []u32) void {
    var prefix: [len]u32 = undefined;
    var postfix: [len]u32 = undefined;

    for (list, 0..) |item, index| {
        const reverse_index = len - 1 - index;
        if (index == 0) {
            prefix[index] = item;
            postfix[reverse_index] = list[reverse_index];
        } else {
            prefix[index] = item * prefix[index - 1];
            postfix[reverse_index] = list[reverse_index] * postfix[reverse_index + 1];
        }
    }

    const prefixHelper = .{1} ++ prefix;
    const postfixHelper = postfix ++ .{1};

    for (list, 0..) |_, index| {
        list[index] = postfixHelper[index + 1] * prefixHelper[index];
    }
}

test "productExceptSelfB" {
    util.setTestName("productExceptSelffB");

    const size = 4;
    // mutable data
    var data: [size]u32 = .{ 3, 4, 5, 7 };
    productExceptSelfB(size, &data);

    try util.isOk("[0] 3-> 140", data[0] == 140);
    try util.isOk("[1] 4-> 105", data[1] == 105);
    try util.isOk("[2] 5-> 84", data[2] == 84);
    try util.isOk("[3] 7-> 60", data[3] == 60);
}
