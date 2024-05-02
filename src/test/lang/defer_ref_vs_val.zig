const std = @import("std");
const util = @import("util");

const Item = struct {
    const Self = @This();
    num: usize,

    pub fn init(num: usize) Item {
        return .{
            .num = num,
        };
    }

    pub fn deferVal(self: Self) void {
        std.debug.print("defer val num: {d}\n", .{self.num});
    }

    pub fn deferRef(self: *Self) void {
        std.debug.print("defer ref num: {d}\n", .{self.num});
    }
};

test "defer val" {
    var item = Item.init(1);
    defer item.deferVal(); // this line is evaluated when scope ends, so item.num will actulaly be 2
    item.num = 2;
}

test "defer ref" {
    var item = Item.init(1);
    defer item.deferRef(); // this line is evaluated when scope ends, so item.num will actulaly be 2
    item.num = 2;
}
