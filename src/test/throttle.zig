const std = @import("std");
const util = @import("./util.zig");

pub const Throttle = struct {
    const Self = @This();
    timestamp: i64,
    throttle_ms: i64,

    pub fn init(ms: i64) Self {
        return Self{
            .timestamp = std.time.milliTimestamp(),
            .throttle_ms = ms,
        };
    }

    /// get delta_time if throttle_ms has passed sinc init or the last throttle
    /// else null
    pub fn check(self: *Self) ?i64 {
        const current_time = std.time.milliTimestamp();
        const delta_time = current_time - self.timestamp;

        if (delta_time > self.throttle_ms) {
            self.timestamp = current_time;
            return delta_time;
        }
        return null;
    }
};

test "throttle" {
    util.setTestName("throttle 50 ms");
    var throttle = Throttle.init(50);
    try util.isEql("throttle.check() after 0ms", throttle.check(), null);
    std.time.sleep(std.time.ns_per_ms * 30);
    try util.isEql("throttle.check() after 30ms", throttle.check(), null);
    std.time.sleep(std.time.ns_per_ms * 20);
    try util.isGT("throttle.check() after 20ms more", throttle.check().?, 50);
    std.time.sleep(std.time.ns_per_ms * 45);
    try util.isEql("throttle.check() after 45ms", throttle.check(), null);
    std.time.sleep(std.time.ns_per_ms * 5);
    try util.isGT("throttle.check() after 5ms more", throttle.check().?, 50);
}
