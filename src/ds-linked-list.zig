const util = @import("./util.zig");
const std = @import("std");

const Allocator = std.mem.Allocator;

fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();
        allocator: Allocator,
        head: ?*Node = null,
        tail: ?*Node = null,
        len: usize = 0,
        deinit_child: bool = false,

        const Node = struct {
            value: T,
            next: ?*Node = null,
            prev: ?*Node = null,
        };

        const Iterator = struct {
            const IterSelf = @This();
            current: ?*Node = null,
            is_complete: bool = false,

            pub fn next(self: *IterSelf) ?T {
                if (self.is_complete) {
                    return null;
                }
                if (self.current) |current| {
                    const result = current.value;
                    self.current = current.next;
                    return result;
                }
                self.is_complete = true;
                return null;
            }
        };

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
            };
        }

        pub fn denint(self: *Self) void {
            var current: ?*Node = self.head;
            while (current != null) {
                if (current) |node| {
                    current = node.next;
                    self.allocator.destroy(node);
                }
            }
        }

        pub fn iterator(self: *const Self) Iterator {
            return .{
                .current = self.head,
            };
        }

        pub fn get(self: *const Self, index: usize) ?T {
            if (index >= self.len) {
                return null;
            }

            var c_index: usize = 0;
            var current: ?*Node = self.head;
            while (current != null and c_index < index) : (c_index += 1) {
                if (current) |node| {
                    current = node.next;
                }
            }

            if (current) |node| {
                return node.value;
            } else {
                unreachable;
            }
        }

        pub fn remove(self: *Self, index: usize) ?T {
            if (index >= self.len) {
                return null;
            }

            var c_index: usize = 0;
            var current: ?*Node = self.head;
            while (current != null and c_index < index) : (c_index += 1) {
                if (current) |node| {
                    current = node.next;
                }
            }

            if (current) |node| {
                if (node == self.head) {
                    self.head = node.next;
                }

                if (node == self.tail) {
                    self.tail = node.prev;
                }

                if (node.prev) |prev| {
                    prev.next = node.next;
                }

                if (node.next) |next| {
                    next.prev = node.prev;
                }

                const result = node.value;
                self.allocator.destroy(node);
                self.len -= 1;
                return result;
            } else {
                unreachable;
            }
        }

        pub fn prepend(self: *Self, value: T) !void {
            var node = try self.allocator.create(Node);
            node.* = .{
                .value = value,
            };

            if (self.head) |head| {
                head.prev = node;
                node.next = head;
                self.head = node;
                self.len += 1;
            } else {
                self.head = node;
                self.tail = node;
                self.len += 1;
            }
        }

        pub fn peekHead(self: *const Self) ?T {
            if (self.head) |head| {
                return head.value;
            } else {
                return null;
            }
        }

        pub fn peekTail(self: *const Self) ?T {
            if (self.tail) |tail| {
                return tail.value;
            } else {
                return null;
            }
        }

        pub fn popHead(self: *Self) ?T {
            if (self.head) |head| {
                const result = head.value;
                if (head == self.tail) {
                    self.head == null;
                    self.tail == null;
                }

                if (head.next) |next| {
                    next.prev = null;
                    self.head = next;
                }

                return result;
            }
            return null;
        }

        pub fn append(self: *Self, value: T) !void {
            var node = try self.allocator.create(Node);
            node.* = .{
                .value = value,
            };

            if (self.tail) |tail| {
                tail.next = node;
                node.prev = tail;
                self.tail = node;
                self.len += 1;
            } else {
                self.head = node;
                self.tail = node;
                self.len += 1;
            }
        }
    };
}

test "LinkedList prepend" {
    util.setTestName("LinkedList.prepend");

    var list = LinkedList(u32).init(std.testing.allocator);
    defer list.denint();
    try util.isOk("index 0 is null", list.get(0) == null);

    try list.prepend(2);
    try util.isOk("index 0 is 2", list.get(0) == 2);
    // n
    try util.isOk("head should be 2", list.peekHead().? == 2);
    try util.isOk("len should be 1", list.len == 1);
    try list.prepend(3);
    try util.isOk("head should be 3", list.peekHead() == 3);
    try util.isOk("tail should be 2", list.peekTail() == 2);
    try util.isOk("len should be 2", list.len == 2);
    try util.isOk("index 0 is 3", list.get(0) == 3);
    try util.isOk("index 1 is 2", list.get(1) == 2);
    try util.isOk("index 2 is null", list.get(3) == null);
    try list.prepend(4);
    try util.isOk("head should be 4", list.peekHead() == 4);
    try util.isOk("tail should be 2", list.peekTail() == 2);
    try util.isOk("len should be 3", list.len == 3);
    try util.isOk("index 0 is 4", list.get(0) == 4);
    try util.isOk("index 1 is 3", list.get(1) == 3);
    try util.isOk("index 2 is 2", list.get(2) == 2);
    try util.isOk("index 3 is null", list.get(3) == null);
}

test "LinkedList append" {
    util.setTestName("LinkedList.append");

    var list = LinkedList(u32).init(std.testing.allocator);
    defer list.denint();
    try list.append(2);
    try util.isOk("tail should be 2", list.peekTail() == 2);
    try util.isOk("head should be 2", list.peekHead() == 2);
    try util.isOk("len should be 1", list.len == 1);
    try list.append(3);
    try util.isOk("tail should be 3", list.peekTail() == 3);
    try util.isOk("head should be 2", list.peekHead() == 2);
    try util.isOk("len should be 2", list.len == 2);
    try list.append(4);
    try util.isOk("tail should be 4", list.peekTail() == 4);
    try util.isOk("head should be 2", list.peekHead() == 2);
    try util.isOk("len should be 3", list.len == 3);
}

test "LinkedList remove" {
    util.setTestName("LinkedList.remove");

    var list = LinkedList(u32).init(std.testing.allocator);
    defer list.denint();
    try list.append(2);
    try list.append(3);
    try list.append(4);

    const result = list.remove(1);
    try util.isOk("remove 2 should be null", list.remove(2) == null);
    try util.isOk("remove 4 should be null", list.remove(4) == null);
    try util.isOk("result should be 3", result == 3);
    try util.isOk("list len should be 2", list.len == 2);
    try util.isOk("list[0] == 2", list.get(0) == 2);
    try util.isOk("list[1] == 4", list.get(1) == 4);
    try util.isOk("list[2] == null", list.get(2) == null);
    try util.isOk("remove 1 should be 4", list.remove(1) == 4);
    try util.isOk("remove 0 should be 2", list.remove(0) == 2);
    try util.isOk("remove 0 should be null", list.remove(0) == null);
}

test "LinkedList iterator" {
    util.setTestName("LinkedList.remove");

    var list = LinkedList(u32).init(std.testing.allocator);
    defer list.denint();
    try list.append(2);
    try list.append(3);
    try list.append(4);

    var iter = list.iterator();

    try util.isOk("2", iter.next() == 2);
    try util.isOk("3", iter.next() == 3);
    try util.isOk("4", iter.next() == 4);
    try util.isOk("null", iter.next() == null);
    try util.isOk("iter is_complete", iter.is_complete);

    // while (iter.next()) |value| {
    //     std.debug.print("iter value: {d}\n", .{value});
    //     std.debug.print("is_complete: {any}\n", .{iter.is_complete});
    // }
}

test "LinkedList popHead" {}
