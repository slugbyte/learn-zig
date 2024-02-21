const std = @import("std");

var test_name: []const u8 = "unknown";

pub fn setTestName(name: []const u8) void {
    std.debug.print("\n", .{});
    test_name = name;
}

pub fn expect(test_kind: []const u8, msg: []const u8, is_ok: bool) !void {
    if (is_ok) {
        std.debug.print("[{s}] {s: >7} succes: {s}\n", .{ test_name, test_kind, msg });
        return;
    }
    std.debug.print("[{s}] {s: >7} failed: {s}\n", .{ test_name, test_kind, msg });
    try std.testing.expect(is_ok);
}

pub fn isOk(msg: []const u8, is_ok: bool) !void {
    return expect("isOk", msg, is_ok);
}

pub fn isNotOk(msg: []const u8, is_ok: bool) !void {
    return expect("isNotOk", msg, !is_ok);
}
