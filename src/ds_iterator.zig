const std = @import("std");

const util = @import("./util.zig");

pub fn RangeIterator(comptime T: type) type {
    return struct {
        const Self = @This();
        from: T,
        to: T,
        current: ?T = null,
        is_complete: bool = false,

        pub fn reset(self: *Self) void {
            self.is_complete = false;
            self.current = null;
        }

        pub fn next(self: *Self) ?T {
            if (self.is_complete) {
                return null;
            }
            if (self.current) |*current| {
                if (self.to < self.from) {
                    if (current.* > self.to) {
                        current.* -= 1;
                        return self.current;
                    } else {
                        self.is_complete = true;
                        return null;
                    }
                }

                if (self.to > self.from) {
                    if (current.* < self.to) {
                        current.* += 1;
                        return self.current;
                    } else {
                        self.is_complete = true;
                        return null;
                    }
                }

                self.is_complete = true;
                return null;
            } else {
                self.current = self.from;
                return self.current;
            }
        }
    };
}

test "RangeIterator" {
    util.setTestName("RangeIterator");
    var range: RangeIterator(i32) = undefined;

    range = .{
        .from = 3,
        .to = -1,
    };

    try util.isNotOk("is_complete", range.is_complete);
    try util.isOk("3", range.next() == 3);
    try util.isOk("2", range.next() == 2);
    try util.isOk("1", range.next() == 1);
    try util.isOk("0", range.next() == 0);
    try util.isOk("-1", range.next() == -1);
    try util.isOk("null", range.next() == null);
    try util.isOk("is_complete", range.is_complete);

    range.reset();

    try util.isNotOk("is_complete", range.is_complete);
    try util.isOk("3", range.next() == 3);
    try util.isOk("2", range.next() == 2);
    try util.isOk("1", range.next() == 1);
    try util.isOk("0", range.next() == 0);
    try util.isOk("-1", range.next() == -1);
    try util.isOk("null", range.next() == null);
    try util.isOk("is_complete", range.is_complete);

    range = .{
        .from = 2,
        .to = 5,
    };

    try util.isNotOk("is_complete", range.is_complete);
    try util.isOk("2", range.next() == 2);
    try util.isOk("3", range.next() == 3);
    try util.isOk("4", range.next() == 4);
    try util.isOk("5", range.next() == 5);
    try util.isOk("null", range.next() == null);
    try util.isOk("is_complete", range.is_complete);
}
