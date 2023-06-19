const std = @import("std");
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;
fn HashSet(comptime T: type) type { return HashMap(T, void); }
const Queue = std.fifo.LinearFifo;
const LinkedList = std.TailQueue;

const WORD_LEN = 4;
const START = "ship";
const END = "dock";

fn readWordList(filename: []const u8, allocator: std.mem.Allocator) !ArrayList([WORD_LEN]u8) {
    var file = try std.fs.cwd().openFile(filename, .{ .read = true, .write = false });
    defer file.close();
    var reader = file.reader();

    var words = ArrayList([WORD_LEN]u8).init(allocator);
    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const word_len = line.len - 1;
        if (word_len == WORD_LEN) {
            var word: [WORD_LEN]u8 = undefined;
            std.mem.copy(u8, &word, line[0..WORD_LEN]);
            try words.append(word);
        }
    }

    return words;
}

fn numDiffs(left: []u8, right: []u8) usize {
    var res: usize = 0;

    var i: usize = 0;
    while (i < WORD_LEN) : (i += 1) {
        res += if (left[i] != right[i]) @as(usize, 1) else @as(usize, 0);
    }

    return res;
}

fn createGraph(words: *const ArrayList([WORD_LEN]u8), allocator: std.mem.Allocator) !HashMap([WORD_LEN]u8, ArrayList([WORD_LEN]u8)) {
    const num_words = words.items.len;
    var adj = HashMap([WORD_LEN]u8, ArrayList([WORD_LEN]u8)).init(allocator);

    var i: usize = 0;
    while (i < num_words) : (i += 1) {
        var j: usize = i + 1;
        while (j < num_words) : (j += 1) {
            const diffs = numDiffs(&words.items[i], &words.items[j]);
            if (diffs == 1) {
                var v = try adj.getOrPutValue(words.items[i], ArrayList([WORD_LEN]u8).init(allocator));
                try v.value_ptr.append(words.items[j]);

                v = try adj.getOrPutValue(words.items[j], ArrayList([WORD_LEN]u8).init(allocator));
                try v.value_ptr.append(words.items[i]);
            }
        }
    }

    return adj;
}

fn findPath(graph: *const HashMap([WORD_LEN]u8, ArrayList([WORD_LEN]u8)), allocator: std.mem.Allocator, start: [4]u8, end: [4]u8) !LinkedList([WORD_LEN]u8) {
    var visited = HashSet([4]u8).init(allocator);
    defer visited.deinit();

    var pred = HashMap([4]u8, [4]u8).init(allocator);
    defer pred.deinit();

    var q = Queue([4]u8, .Dynamic).init(allocator);
    defer q.deinit();

    try visited.put(start, {});
    try q.write(&.{start});
    while (q.count != 0) {
        const u = q.readItem().?;

        for (graph.get(u).?.items) |v| {
            if (!visited.contains(v)) {
                try visited.put(v, {});
                try pred.put(v, u);
                try q.write(&.{v});

                if (std.mem.eql(u8, v[0..], end[0..])) {
                    break;
                }
            }
        }
    }

    var path = LinkedList([WORD_LEN]u8){};
    var curr: ?[4]u8 = end;
    while (curr != null) : (curr = pred.get(curr.?)) {
        var node = try allocator.create(LinkedList([WORD_LEN]u8).Node );
        node.* = .{ .data = curr.? };
        path.prepend(node);
    }

    return path;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    defer _ = gpa.detectLeaks();

    const words = try readWordList("words.txt", allocator);
    defer words.deinit();

    var graph = try createGraph(&words, allocator);
    defer graph.deinit();
    defer {
        var it = graph.valueIterator();
        while (it.next()) |value| {
            value.deinit();
        }
    }

    var path = try findPath(&graph, allocator, START.*, END.*);
    defer {
        // this is really ugly
        var prev = path.first;
        var it = prev.?.next;
        while (it) |node| : ({
            prev = it; it = node.next;
        }) {
            allocator.destroy(prev.?);
        }
        allocator.destroy(prev.?);
    }

    const writer = std.io.getStdOut().writer();
    try writer.print("Shortest path from {s} to {s}:\n", .{START, END});
    try writer.print("{s}", .{START});
    var it = path.first.?.next;
    while (it) |node| : (it = node.next){
        try writer.print(" -> {s}", .{node.data});
    }
    try writer.print("\n", .{});
}

