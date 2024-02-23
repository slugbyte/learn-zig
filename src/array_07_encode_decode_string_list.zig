const std = @import("std");
const t = std.testing;
const util = @import("./util.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn encodeStringList(string_list: ArrayList([]const u8), allocator: Allocator) ![]u8 {
    var result = ArrayList(u8).init(allocator);
    defer result.deinit();

    for (string_list.items) |string| {
        const marker = try std.fmt.allocPrint(allocator, "{d}#", .{string.len});
        defer allocator.free(marker);
        try result.appendSlice(marker);
        try result.appendSlice(string);
    }

    return allocator.dupe(u8, result.items);
}

pub fn decodeStringList(string: []const u8, allocator: Allocator) !ArrayList([]u8) {
    var result = ArrayList([]u8).init(allocator);
    // defer result.deinit();

    var mark_start: usize = 0;
    var mark_end: usize = 0;

    var i: usize = 0;
    while (i < string.len) {
        const ch = string[i];
        if (ch == '#') {
            mark_end = i;
            const mark_num = string[mark_start..mark_end];
            // std.debug.print("mark: ({s})\n", .{mark_num});
            const word_len = try std.fmt.parseInt(usize, mark_num, 0);
            const word_start = i + 1;
            const word_end = word_start + word_len;

            const word = try allocator.dupe(u8, string[word_start..word_end]);
            try result.append(word);
            // std.debug.print("word_len: ({d})\n", .{word_len});
            // std.debug.print("cool word: ({s})\n", .{string[word_start..word_end]});
            i = word_end;
            mark_start = word_end;
        } else {
            i += 1;
        }
    }

    return result;
}

test "encodeStringList" {
    util.setTestName("encodeStringList");

    var example_list = ArrayList([]const u8).init(t.allocator);
    defer example_list.deinit();

    try example_list.append("hello world");
    try example_list.append("my name is");
    try example_list.append("dunk");

    const wat = try encodeStringList(example_list, t.allocator);
    defer t.allocator.free(wat);

    const decoded = try decodeStringList(wat, t.allocator);
    defer decoded.deinit();

    for (decoded.items) |item| {
        std.debug.print("item: {s}\n", .{item});
        t.allocator.free(item);
    }
    // std.debug.print("cool beans:\n{s}\n", .{wat});
}
