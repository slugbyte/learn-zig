const std = @import("std");
const util = @import("./util.zig");

// This iterator returns an error and must be used with a while {} |thing| else |err| {}
const RandomIterator = struct {
    seed: u64,
    prng: std.rand.DefaultPrng,
    count: ?usize = null,

    pub fn init() RandomIterator {
        const time: u128 = @bitCast(std.time.nanoTimestamp());
        const seed: u64 = @truncate(time);
        return .{
            .seed = seed,
            .prng = std.rand.DefaultPrng.init(seed),
        };
    }

    pub fn initWithCount(count: usize) RandomIterator {
        var result = RandomIterator.init();
        result.count = count;
        return result;
    }

    pub fn next(self: *RandomIterator) !u8 {
        if (self.count) |*count| {
            if (count.* > 0) {
                count.* -= 1;
                return self.prng.random().int(u8);
            } else {
                return error.RandomIteratorEmpty;
            }
        } else {
            return self.prng.random().int(u8);
        }
    }
};

test "RandomIterator" {
    util.setTestName("RandomIterator");

    var randIter = RandomIterator.initWithCount(128);
    var count: usize = 0;
    const target = 88;
    var lastRand: u8 = undefined;
    while (randIter.next()) |rand| {
        count += 1;
        lastRand = rand;
        if (rand == target) {
            break;
        }
    } else |err| {
        try util.isOk("count is 128", count == 128);
        try util.isOk("target not hit", lastRand != target);
        try util.isOk("error.RandomIteratorEmpty", err == error.RandomIteratorEmpty);
        return;
    }
    try util.isOk("not yet 128", count < 128);
    try util.isOk("target hit", lastRand == target);
}

// This iterator returns an optional number and can be used with a while |thing| {}
pub fn RangeIterator(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Int, .Float => {},
        else => {
            @compileError("RandomIterator init error T must be a int or float type.");
        },
    }

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
