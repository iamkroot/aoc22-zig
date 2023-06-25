# Advent of Code 2022 in Zig!

This repo contains my solutions to the [AoC'22](https://adventofcode.com/2022) challenge, written in Zig. Just wanted to learn the language.

It should work with Zig 0.11.0 (I'm running `0.11.0-dev.1797+d3c9bfada`).

## The Curious Case of a Memory Leak
My Day 23 implementation led to an informative adventure, and I wrote a [blog post](https://iamkroot.github.io/blog/zig-memleak) about it.

## Random thoughts on Zig
Note that these are just my impressions centered around what I want from a language; your mileage may vary.

### The good
* Auto-union error types are amazing! Very ergonomic compared to Rust
* `defer` and `errdefer` are nice
* Explicit allocators everywhere- really makes you think about the memory allocation patterns in your code
* `XXXAssumeCapacity` class of functions for non-allocating modifications of dynamic data structures are good to have. This lang is geared towards perf. (But they also add to the noise in editor autocompletions- there's (at least) two versions of every method.)
* `enum`s are fun; `.` is easier to type than `::` (as in Rust, C++)

### The not so good
* I would _not_ want to read the code I've written. Unnecessary verbosity at various places (struct fields initialization, no operator overloading, while loops).
* `comptime` was too hard to get started- bad error messages from compiler, [random limitations](https://github.com/ziglang/zig/issues/6709), etc.
* `format` function seems hacky... In general, `anytype` is reminiscent of C++ template hell. No autocomplete :(
* ugly multiline strings
* ZLS/docs still have a lot of work to do
