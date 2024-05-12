const std = @import("std");
const util = @import("./util.zig");

// what index does the crystal ball break at
// Time: O(sqrt(n))
// Space: O(1)
pub fn crystalBallBreak(crystal_ball: []const bool) ?usize {
    const jump_amount: usize = std.math.sqrt(crystal_ball.len);

    var i: usize = jump_amount;
    while (i < crystal_ball.len) : (i += jump_amount) {
        if (crystal_ball[i]) {
            break;
        }
    }

    i -= jump_amount;

    var j: usize = 0;
    while (j <= jump_amount and i < crystal_ball.len) {
        if (crystal_ball[i]) {
            return i;
        }
        i += 1;
        j += 1;
    }

    return null;
}

test "crystalBallDrop" {
    util.setTestName("crystalBallDrop");

    const ball_a: [100]bool = .{false} ** 100;
    const ball_b: [100]bool = .{true} ** 100;
    const ball_c: [100]bool = .{false} ** 66 ++ .{true} ** 34;
    const ball_d: [100]bool = .{false} ** 99 ++ .{true};

    try util.isOk("ball_a never breaks", crystalBallBreak(&ball_a) == null);
    try util.isOk("ball_b breaks at 0", crystalBallBreak(&ball_b).? == 0);
    try util.isOk("ball_c breaks at 66", crystalBallBreak(&ball_c).? == 66);
    try util.isOk("ball_d breaks at 99", crystalBallBreak(&ball_d).? == 99);
}
