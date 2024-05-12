const std = @import("std");
const util = @import("util");

const AutoDestroy = @import("./auto_destory.zig").AutoDestroy;

/// create a queue that can auto free/destory any remaning values using the allocator provided
/// if the queue is not empty at deinit
///
/// items returned by dequeue need to be managed by caller
///
/// NOTE: auto_destroy must be comptime or the switch statement in deinit will complian
/// that the branches are trying to pass invaild values into free and destroy
/// at compile time
pub fn Queue(comptime T: type, comptime auto_destroy: AutoDestroy) type {
    return struct {
        head: ?*Node = null,
        tail: ?*Node = null,
        allocator: std.mem.Allocator,
        len: usize = 0,
        const Self = @This();

        const Node = struct {
            value: T,
            prev: ?*Node = null,
            next: ?*Node = null,
        };

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
            };
        }

        /// free all of the nodes in the queue and auto_destroy value if necessary
        pub fn deinit(self: *Self) void {
            while (self.head) |current| {
                switch (auto_destroy) {
                    .Disabled => {},
                    .Free => self.allocator.free(current.value),
                    .Destroy => self.allocator.destroy(current.value),
                }
                self.head = current.next;
                self.allocator.destroy(current);
            }
            self.tail = null;
        }

        /// get the next item in the queue but leave it in the queue
        /// caller does not manage memory
        pub fn peek(self: *Self) ?T {
            if (self.tail) |tail| {
                return tail.value;
            }
            return null;
        }

        /// put a value into the queue
        /// Time: O(1)
        /// Space: O(n)
        pub fn enque(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.* = .{
                .value = value,
            };

            self.len += 1;
            if (self.head) |head| {
                head.prev = node;
                node.next = head;
                self.head = node;
            } else {
                self.head = node;
                self.tail = node;
            }
        }

        /// get the next item in the queue and remove it from the queue
        /// Time: O(1)
        /// Space: O(n)
        /// caller must manage memory
        pub fn dequeue(self: *Self) ?T {
            if (self.tail) |old_tail| {
                const result = old_tail.value;
                if (old_tail.prev) |new_tail| {
                    self.tail = new_tail;
                    new_tail.next = null;
                } else {
                    self.tail = null;
                    self.head = null;
                }
                self.allocator.destroy(old_tail);

                return result;
            }
            return null;
        }
    };
}

test "Queue" {
    util.setTestName("Queue No AutoDestroy");
    var queue = Queue(u8, AutoDestroy.Disabled).init(std.testing.allocator);
    defer queue.deinit();
    try util.isOk("len 0", queue.len == 0);
    try util.isOk("null when empty", queue.dequeue() == null);
    try queue.enque(0);
    try util.isOk("len 1", queue.len == 1);
    try queue.enque(1);
    try util.isOk("len 2", queue.len == 2);
    try queue.enque(2);
    try util.isOk("len 3", queue.len == 3);
    try queue.enque(3);
    try util.isOk("len 4", queue.len == 4);

    try util.isOk("peek is 0", 0 == queue.peek().?);
    try util.isOk("dequeue 0", 0 == queue.dequeue().?);
    try util.isOk("dequeue 1", 1 == queue.dequeue().?);
}

test "Queue Free" {
    util.setTestName("Queue Free");
    var queue = Queue([]u8, AutoDestroy.Free).init(std.testing.allocator);

    const a = try std.testing.allocator.alloc(u8, 5);
    for (a) |*item| {
        item.* = 22;
    }

    // auto_destroy
    const b = try std.testing.allocator.alloc(u8, 2);
    for (b) |*item| {
        item.* = 33;
    }

    // auto_destroy
    const c = try std.testing.allocator.alloc(u8, 9);
    for (c) |*item| {
        item.* = 44;
    }

    defer queue.deinit();
    try queue.enque(a);
    try queue.enque(b);
    try queue.enque(c);

    const first = queue.dequeue().?;
    defer std.testing.allocator.free(first);
    try util.isOk("first: len 5", first.len == 5);
    try util.isOk("first[0]: is 22", first[0] == 22);
}

test "Queue Distory" {
    util.setTestName("Queue Distory");
    const Point = struct {
        x: u8,
        y: u8,
    };

    var queue = Queue(*Point, AutoDestroy.Destroy).init(std.testing.allocator);

    const a = try std.testing.allocator.create(Point);
    a.* = .{ .x = 0, .y = 0 };

    const b = try std.testing.allocator.create(Point);
    b.* = .{ .x = 1, .y = 2 };

    // auto_destroy
    const c = try std.testing.allocator.create(Point);
    c.* = .{ .x = 3, .y = 4 };

    defer queue.deinit();

    try queue.enque(a);
    try queue.enque(b);
    try queue.enque(c);

    const first = queue.dequeue().?;
    defer std.testing.allocator.destroy(first);
    try util.isOk("first.x: is 0", first.x == 0);
    try util.isOk("first.y: is 0", first.y == 0);

    const second = queue.dequeue().?;
    defer std.testing.allocator.destroy(second);
    try util.isOk("second.x: is 1", second.x == 1);
    try util.isOk("second.y: is 2", second.y == 2);
}
