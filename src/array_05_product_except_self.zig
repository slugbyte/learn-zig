const std = @import("std");
const util = @import("./util.zig");
const print = std.debug.print;

pub fn productExceptSelf(comptime len: usize, list: []u32) []u32 {
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

    print("pretex {any}\n", .{prefixHelper});
    print("postfix {any}\n", .{postfixHelper});
    return list;
}

test "productExceptSelf" {
    util.setTestName("productExceptSelf");

    const size = 4;
    var data: [size]u32 = .{ 3, 4, 5, 7 };
    productExceptSelf(size, &data);

    try util.isOk("[0] 3-> 140", data[0] == 140);
    try util.isOk("[1] 4-> 105", data[1] == 105);
    try util.isOk("[2] 5-> 84", data[2] == 84);
    try util.isOk("[3] 7-> 60", data[3] == 60);
}
