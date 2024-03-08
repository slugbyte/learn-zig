const std = @import("std");

const util = @import("./util.zig");


const RangeIterator = struct {
    const Self = @This();
    .from: usize,
    .to: usize,
    .current = ?usize = null,
    .is_complete = false,

    fn next(self: *Self) ?usize {
        if (self.is_complete) {
            return null;
        }
        if (self.current) |current| {
            if (self.to < self.from) {
                if (current > self.to) {
                    self.current -= 1;
                    return self.current;
                } else {
                    self.is_complete = true;
                    return null;
                }
            }

            if (self.to > self.from) {
                if (current < self.to) {
                    self.current += 1;
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


test "RangeIterator" {
    const range = Range {
        .from = 10, 
        .to = 9,
    };

}
