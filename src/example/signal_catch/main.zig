const std = @import("std");

var count: usize = 0;

fn handle_sigint(_: c_int) align(1) callconv(.C) void {
    _ = std.io.getStdOut().write("\nupdate count\n") catch unreachable;
    count += 1;
}

pub fn main() !void {
    std.debug.print("sigal catch\n", .{});

    const sigaction = std.os.Sigaction{
        .handler = .{ .handler = handle_sigint },
        .flags = std.os.SA.RESTART,
        .mask = 0,
    };

    try std.os.sigaction(std.os.SIG.USR1, @ptrCast(&sigaction), null);
    var count_old = count;
    var keep_alive = true;
    while (keep_alive) {
        if (count_old != count) {
            count_old = count;
            std.debug.print("count: {d}", .{count});
            if (count == 5) {
                keep_alive = false;
            }
        }
    }
}
