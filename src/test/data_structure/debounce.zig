const std = @import("std");
const util = @import("util");

pub const Debouce = struct {
    const Self = @This();
    timestamp: i64,
    debounce_ms: i64,

    pub fn init(ms: i64) Self {
        return Self{
            .timestamp = std.time.milliTimestamp(),
            .debounce_ms = ms,
        };
    }

    /// get delta_time if at least debout_ms has passed since the last check
    /// else null
    pub fn check(self: *Self) ?i64 {
        const current_time = std.time.milliTimestamp();
        const delta_time = current_time - self.timestamp;
        self.timestamp = current_time;

        if (delta_time > self.debounce_ms) {
            return delta_time;
        }
        return null;
    }
};

test "debouce" {
    util.setTestName("debounce 50 ms");
    var debounce = Debouce.init(50);
    try util.isEql("debounce.check() after 0ms", debounce.check(), null);
    std.time.sleep(std.time.ns_per_ms * 30);
    try util.isEql("debounce.check() after 30ms", debounce.check(), null);
    std.time.sleep(std.time.ns_per_ms * 30);
    try util.isEql("debounce.check() after 30ms again", debounce.check(), null);
    std.time.sleep(std.time.ns_per_ms * 50);
    try util.isGT("debounce.check() after 50ms", debounce.check().?, 50);
}
