const std = @import("std");
const util = @import("util");
const Allocator = std.mem.Allocator;
const HashSet = std.AutoHashMap(u8, void);

/// This is a slow brute force implamentaion of contains dup
/// Time: O(n^2)
/// Space: O(1)
pub fn containsDuplicateA(text: []const u8) bool {
    for (text, 0..) |c, index| {
        var i = index + 1;
        while (i < text.len) : (i += 1) {
            if (c == text[i]) {
                return true;
            }
        }
    }
    return false;
}

test "containsDuplicateA" {
    util.setTestName("containsDuplicateA");
    var test_word: []const u8 = undefined;

    test_word = "snow storm";
    try util.isOk(test_word, containsDuplicateA(test_word));

    test_word = "worm king";
    try util.isNotOk(test_word, containsDuplicateA(test_word));
}

/// This is a fast hashset implimation of containsDuplicateB;
/// Time: O(n)
/// Space: O(n)
pub fn containsDuplicateB(text: []const u8, allocator: std.mem.Allocator) !bool {
    var crumb = HashSet.init(allocator);
    defer crumb.deinit();
    // errdefer crumb.deinit(); should I do this?
    for (text) |c| {
        if (crumb.get(c)) |_| {
            return true;
        } else {
            try crumb.put(c, {});
        }
    }
    return false;
}

test "containsDuplicateB" {
    util.setTestName("containsDuplicateB");
    var test_word: []const u8 = undefined;

    test_word = "orange juce";
    try util.isOk(test_word, try containsDuplicateB(test_word, std.testing.allocator));

    test_word = "pink table";
    try util.isNotOk(test_word, try containsDuplicateB(test_word, std.testing.allocator));
}
