const std = @import("std");
const util = @import("util");
const AutoDestroy = @import("./auto_destory.zig").AutoDestroy;

// const AutoDestroy = enum {
//     Disabled,
//     Free,
//     Destroy,
// };

/// A linked list based queue that can auto destroy/free values stored on deinit
/// if stack is not empty
pub fn Stack(comptime T: type, comptime auto_destory: AutoDestroy) type {
    return struct {
        head: ?*Node = null,
        len: usize = 0,
        allocator: std.mem.Allocator,

        const Self = @This();
        const Node = struct {
            value: T,
            next: ?*Node,
        };

        const PeekIterator = struct {
            is_complete: bool = false,
            current: ?*Node = null,

            pub fn next(self: *PeekIterator) ?T {
                if (self.is_complete) {
                    return null;
                }

                if (self.current) |current| {
                    self.current = current.next;
                    return current.value;
                } else {
                    self.is_complete = true;
                    return null;
                }
            }
        };

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.head) |head| {
                switch (auto_destory) {
                    .Disabled => {},
                    .Free => self.allocator.free(head.value),
                    .Destroy => self.allocator.destroy(head.value),
                }

                self.head = head.next;
                self.allocator.destroy(head);
            }
        }

        pub fn push(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.* = .{
                .value = value,
                .next = self.head,
            };

            self.head = node;
            self.len += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.head) |head| {
                const result = head.value;
                self.head = head.next;
                self.allocator.destroy(head);
                self.len -= 1;
                return result;
            } else {
                return null;
            }
        }

        pub fn peek(self: *Self) ?T {
            if (self.head) |head| {
                return head.value;
            } else {
                return null;
            }
        }

        pub fn peekIterator(self: *Self) PeekIterator {
            return .{
                .current = self.head,
            };
        }
    };
}

test "Stack No AutoDestroy" {
    util.setTestName("Stack No AutoDestroy");
    var stack = Stack(u8, AutoDestroy.Disabled).init(std.testing.allocator);
    defer stack.deinit();

    try util.isOk("peek null when empty", stack.peek() == null);
    try util.isOk("pop null when empty", stack.pop() == null);
    try util.isOk("len 0", stack.len == 0);

    try stack.push(2);
    try util.isOk("len 1", stack.len == 1);
    try stack.push(4);
    try util.isOk("len 2", stack.len == 2);
    try stack.push(6);
    try util.isOk("len 3", stack.len == 3);

    try util.isOk("pop 6", stack.pop().? == 6);
    try util.isOk("len 2", stack.len == 2);
    try util.isOk("pop 4", stack.pop().? == 4);
    try util.isOk("len 1", stack.len == 1);
    try util.isOk("pop 2", stack.pop().? == 2);
    try util.isOk("len 0", stack.len == 0);
}

test "Stack Free" {
    util.setTestName("Stack Free");
    var stack = Stack([]u8, AutoDestroy.Free).init(std.testing.allocator);
    defer stack.deinit();

    try util.isOk("peek null when empty", stack.peek() == null);
    try util.isOk("pop null when empty", stack.pop() == null);
    try util.isOk("len 0", stack.len == 0);

    const a = try std.testing.allocator.alloc(u8, 5);
    const b = try std.testing.allocator.alloc(u8, 6);
    const c = try std.testing.allocator.alloc(u8, 7);
    for (c) |*item| {
        item.* = 80;
    }

    try stack.push(a);
    try stack.push(b);
    try stack.push(c);

    const first = stack.pop().?;
    defer std.testing.allocator.free(first);
    try util.isOk("first len 7", first.len == 7);
    try util.isOk("first[0] is 80", first[0] == 80);
}

test "Stack Destory" {
    util.setTestName("Stack Destory");
    const Point = struct {
        x: u8,
        y: u8,
    };

    var stack = Stack(*Point, AutoDestroy.Destroy).init(std.testing.allocator);
    defer stack.deinit();

    const a = try std.testing.allocator.create(Point);
    a.* = .{ .x = 0, .y = 0 };

    // auto destroy
    const b = try std.testing.allocator.create(Point);
    b.* = .{ .x = 1, .y = 2 };

    // auto_destroy
    const c = try std.testing.allocator.create(Point);
    c.* = .{ .x = 3, .y = 4 };

    try stack.push(a);
    try stack.push(b);
    try stack.push(c);

    const first = stack.pop().?;
    defer std.testing.allocator.destroy(first);
    try util.isOk("first.x: is 3", first.x == 3);
    try util.isOk("first.y: is 4", first.y == 4);
}

test "Stack Self Destory With PeekIterator" {
    util.setTestName("Stack Destory");
    const Point = struct {
        x: u8,
        y: u8,
    };

    var stack = Stack(*Point, AutoDestroy.Disabled).init(std.testing.allocator);
    defer {
        var iter = stack.peekIterator();
        while (iter.next()) |value| {
            std.debug.print("peek iter free: Point({d}, {d})\n", .{ value.x, value.y });
            std.testing.allocator.destroy(value);
        }
        stack.deinit();
    }

    const a = try std.testing.allocator.create(Point);
    a.* = .{ .x = 0, .y = 0 };

    // auto destroy
    const b = try std.testing.allocator.create(Point);
    b.* = .{ .x = 1, .y = 2 };

    // auto_destroy
    const c = try std.testing.allocator.create(Point);
    c.* = .{ .x = 3, .y = 4 };

    try stack.push(a);
    try stack.push(b);
    try stack.push(c);

    const first = stack.pop().?;
    defer std.testing.allocator.destroy(first);
    try util.isOk("first.x: is 3", first.x == 3);
    try util.isOk("first.y: is 4", first.y == 4);
}
