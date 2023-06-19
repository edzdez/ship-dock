# ship-dock

A program written in [zig 0.9.1](https://ziglang.org) that finds the shortest solution to Ian Stewart's `SHIP-DOCK` puzzle.
I know that finding a solution to the puzzle is not the point of the exercise, but I just couldn't resist :).

## Build

```shell
$ git clone https://github.com/edzdez/ship-dock.git
$ cd ship-dock
$ zig build
$ ./zig-out/bin/ship-dock

# alternatively, build and run in one step!
$ zig build run
```

## Output

```
Shortest path from ship to dock:
ship -> shap -> soap -> soak -> sock -> dock
```

