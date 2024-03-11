const std = @import("std");

var TEST_NAME: []const u8 = "unknown";

pub const color_red = "\x1b[31m";
pub const color_blue = "\x1b[34m";
pub const color_reset = "\x1b[0m";

pub const JSON_NOTE_FILE_CONTENT = @embedFile("./res/json/note.json");
pub const xxd = std.debug.print;

pub fn xxp(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.testing.allocator, fmt, args) catch return;
    defer std.testing.allocator.free(msg);
    std.debug.print("{s}\n", .{msg});
}

pub fn xxpRed(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.testing.allocator, fmt, args) catch return;
    defer std.testing.allocator.free(msg);
    std.debug.print("{s}{s}{s}\n", .{ color_red, msg, color_reset });
}

pub fn xxxxxxxxxxxxxxxHEADER(comptime text: []const u8) void {
    const msg = std.fmt.allocPrint(std.testing.allocator, " {s}{s}{s}", .{ color_blue, text, color_reset }) catch return;
    defer std.testing.allocator.free(msg);
    xxp("\n[{s}] {s:->55} ----", .{ TEST_NAME, msg });
}

pub fn xxl(comptime text: []const u8) void {
    xxp("{s}", .{text});
}

pub fn xxn() void {
    std.debug.print("\n", .{});
}

pub inline fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn setTestName(name: []const u8) void {
    std.debug.print("\n", .{});
    TEST_NAME = name;
}

pub fn expect(test_kind: []const u8, msg: []const u8, is_ok: bool) !void {
    if (is_ok) {
        xxp("[{s}] {s: >7} success: {s}", .{ TEST_NAME, test_kind, msg });
        return;
    }
    xxpRed("[{s}] {s: >7} failed: {s}", .{ TEST_NAME, test_kind, msg });

    if (!is_ok) {
        return error.NeetCodeTestFailed;
    }
}

pub fn isEql(msg: []const u8, actual: anytype, expected: anytype) !void {
    const is_ok = expected == actual;
    if (is_ok) {
        xxd("[{s}] {s: >7} success: {s} is {any}\n", .{ TEST_NAME, "isEql", msg, expected });
        return;
    } else {
        xxd("{s}[{s}] {s: >7} failed: {s} (expected {any} -> found {any}){s}\n", .{ color_red, TEST_NAME, "isEql", msg, expected, actual, color_reset });
        return error.NeetCodeTestFailed;
    }
}

pub fn isLT(msg: []const u8, actual: anytype, moreThan: anytype) !void {
    const is_ok = actual < moreThan;
    if (is_ok) {
        xxd("[{s}] {s: >7} success: {s} ({any} < {any})\n", .{ TEST_NAME, "isEql", msg, actual, moreThan });
        return;
    } else {
        xxd("{s}[{s}] {s: >7} failed: {s} ({any} is not < {any}){s}\n", .{ color_red, TEST_NAME, "isEql", msg, actual, moreThan, color_reset });
        return error.NeetCodeTestFailed;
    }
}

pub fn isGT(msg: []const u8, actual: anytype, lessThan: anytype) !void {
    const is_ok = actual > lessThan;
    if (is_ok) {
        xxd("[{s}] {s: >7} success: {s} ({any} > {any})\n", .{ TEST_NAME, "isEql", msg, actual, lessThan });
        return;
    } else {
        xxd("{s}[{s}] {s: >7} failed: {s} ({any} is not > {any}){s}\n", .{ color_red, TEST_NAME, "isEql", msg, actual, lessThan, color_reset });
        return error.NeetCodeTestFailed;
    }
}

pub fn isOk(msg: []const u8, is_ok: bool) !void {
    return expect("isOk", msg, is_ok);
}

pub fn isNotOk(msg: []const u8, is_ok: bool) !void {
    return expect("isNotOk", msg, !is_ok);
}

pub fn isOkFmt(comptime fmt: []const u8, args: anytype, is_ok: bool) !void {
    const msg = try std.fmt.allocPrint(std.testing.allocator, fmt, args);
    defer std.testing.allocator.free(msg);
    return expect("isOkFmt", msg, is_ok);
}

pub fn isNotOkFmt(comptime fmt: []const u8, args: anytype, is_ok: bool) !void {
    const msg = try std.fmt.allocPrint(std.testing.allocator, fmt, args);
    defer std.testing.allocator.free(msg);
    return expect("isNotOkFmt", msg, !is_ok);
}
