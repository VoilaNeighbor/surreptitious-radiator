const std = @import("std");

const HttpMessage = struct {
    raw: []u8,
};

pub const HttpParser = struct {
    const State = union(enum) {
        idle,
        busy,
    };

    state: State,
    buffer: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) HttpParser {
        return .{ .state = State.idle, .buffer = std.ArrayList(u8).init(allocator) };
    }

    pub fn deinit(self: *HttpParser) void {
        std.debug.assert(self.state == .idle);
        self.buffer.deinit();
    }

    /// Return value call-owned.
    pub fn handle(self: *HttpParser, byte: u8) !?HttpMessage {
        try self.buffer.append(byte);
        switch (self.state) {
            .idle => self.state = State.busy,
            .busy => {
                const a = &self.buffer.items;
                if (byte == '\n' and a.len > 3 and std.mem.eql(u8, "\r\n\r\n", a.*[a.len - 4 ..])) {
                    self.state = .idle;
                    return .{ .raw = try self.buffer.toOwnedSlice() };
                }
            },
        }
        return null;
    }
};

fn parse_http_messages(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(HttpMessage) {
    var parser = HttpParser.init(allocator);
    defer parser.deinit();

    var result = std.ArrayList(HttpMessage).init(allocator);
    for (input) |byte| {
        if (try parser.handle(byte)) |new_message| {
            try result.append(new_message);
        }
    }
    return result;
}

// TODO(Fifnmar) Extract logic?
test "Segment byte stream into HTTP packets" {
    const msg = "GET / HTTP/1.1\r\nHost: www.example.com\r\n\r\n";
    const input = msg ** 2;

    const messages = try parse_http_messages(std.testing.allocator, input);
    defer messages.deinit();
    defer for (messages.items) |x| std.testing.allocator.free(x.raw);

    try std.testing.expectEqual(messages.items.len, 2);
    try std.testing.expectEqualSlices(u8, messages.items[0].raw, msg);
    try std.testing.expectEqualSlices(u8, messages.items[1].raw, msg);
}

test "Ill-formed HTTP" {
    // TODO(Fifnmar)
}
