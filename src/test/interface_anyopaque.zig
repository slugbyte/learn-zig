const std = @import("std");
const util = @import("./util.zig");

const Greeter = struct {
    ptr: *const anyopaque,
    implSpeak: *const fn (ptr: *const anyopaque, say: []const u8) void,

    pub fn speak(self: Greeter, say: []const u8) void {
        return self.implSpeak(self.ptr, say);
    }
};

const Person = struct {
    const Self = @This();
    name: []const u8,

    fn implGreeterSpeak(ptr: *const anyopaque, say: []const u8) void {
        const self: *const Self = @ptrCast(@alignCast(ptr));
        std.debug.print("{s} says \"{s}\"!\n", .{ self.name, say });
    }

    pub fn greeter(self: *const Self) Greeter {
        return .{
            .ptr = self,
            .implSpeak = implGreeterSpeak,
        };
    }
};

const Dog = struct {
    const Self = @This();
    name: []const u8,
    kind: []const u8,

    fn implGreeterSpeak(ptr: *const anyopaque, say: []const u8) void {
        const self: *const Self = @ptrCast(@alignCast(ptr));
        std.debug.print("a {s} named {s} barks \"{s}\"!\n", .{ self.kind, self.name, say });
    }

    pub fn greeter(self: *const Self) Greeter {
        return .{
            .ptr = self,
            .implSpeak = implGreeterSpeak,
        };
    }
};

test "Greeter" {
    util.setTestName("Interface Greeter");

    const dog = Dog{
        .name = "hank",
        .kind = "cow dog",
    };

    const dogGreeter = dog.greeter();
    dogGreeter.speak("woof woof");

    const person = Person{
        .name = "slugbyte",
    };

    const personGreeter = person.greeter();
    personGreeter.speak("i could use a cheeseburger");
}
