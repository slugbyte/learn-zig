const std = @import("std");
const util = @import("util");
const t = std.testing;
const mem = std.mem;
const fmt = std.fmt;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

/// encode an array of strings ([]u8) into a single string
/// each string prefixed with {len}#{original_string}
/// then they are all concatinated together
/// NOTE: Caller ownes the memory
/// Time: O(n)
/// space: O(n)
pub fn encodeStringList(string_list: ArrayList([]const u8), allocator: Allocator) ![]u8 {
    var result = ArrayList(u8).init(allocator);
    defer result.deinit();

    for (string_list.items) |string| {
        const marker = try fmt.allocPrint(allocator, "{d}#", .{string.len});
        defer allocator.free(marker);
        try result.appendSlice(marker);
        try result.appendSlice(string);
    }

    return allocator.dupe(u8, result.items);
}

/// take an string with an encoded list of strings and turn it back into a list of strings
/// NOTE: Caller ownes the memory
/// Time: O(n)
/// space: O(n)
pub fn decodeStringList(string: []const u8, allocator: Allocator) !ArrayList([]u8) {
    var result = ArrayList([]u8).init(allocator);
    var mark_start: usize = 0;
    var i: usize = 0;
    while (i < string.len) {
        const ch = string[i];
        if (ch == '#') {
            // parse word len
            const mark_num = string[mark_start..i];
            const word_len = try fmt.parseInt(usize, mark_num, 0);
            // parse word
            const word_start = i + 1;
            const word_end = word_start + word_len;
            const word = try allocator.dupe(u8, string[word_start..word_end]);
            try result.append(word);
            // move on to next mark#word
            mark_start = word_end;
            i = word_end;
        } else {
            i += 1;
        }
    }
    return result;
}

test "encodeStringList and decodeStringList" {
    util.setTestName("encodeStringList");

    var example_list = ArrayList([]const u8).init(t.allocator);
    defer example_list.deinit();
    const first = "hello world";
    const second = "my name is";
    const third = "slugbyte";
    const fourth = "my lucky # is 4";
    try example_list.append(first);
    try example_list.append(second);
    try example_list.append(third);
    try example_list.append(fourth);

    const encoded = try encodeStringList(example_list, t.allocator);
    defer t.allocator.free(encoded);

    const expected_encoding = "11#hello world10#my name is8#slugbyte15#my lucky # is 4";
    try util.isOkFmt(t.allocator, "encoded should be \"{s}\"", .{expected_encoding}, util.eql(encoded, expected_encoding));

    util.setTestName("decodeStringList");
    const decoded = try decodeStringList(encoded, t.allocator);
    defer decoded.deinit();

    try util.isOk("decoded has 4 items", decoded.items.len == 4);
    try util.isOkFmt(t.allocator, "decoded[0] is {s}", .{first}, util.eql(decoded.items[0], first));
    try util.isOkFmt(t.allocator, "decoded[1] is {s}", .{second}, util.eql(decoded.items[1], second));
    try util.isOkFmt(t.allocator, "decoded[2] is {s}", .{third}, util.eql(decoded.items[2], third));
    try util.isOkFmt(t.allocator, "decoded[3] is {s}", .{fourth}, util.eql(decoded.items[3], fourth));

    for (decoded.items) |item| {
        t.allocator.free(item);
    }
}
