"""
A Sublime Text 4 plugin to create skeleton files for each new day.
1. Creates a src/day{num}.zig file with standard imports and part1,2 funcs
2. Downloads the big input into data/input/day{num}.txt (need to set SESS_COOKIE)
"""

import re
import sys
import threading
from pathlib import Path
from textwrap import dedent
from typing import Optional

import sublime
import sublime_plugin

sys.path.insert(0, sublime.packages_path() + "/requests/all")
import requests

SESS_COOKIE = "GET_THIS_FROM_YOUR_BROWSER_WEB_INSPECTOR"
DAY_PAT = re.compile(r"^day(\d+)")


def create_files(
    window: sublime.Window, root: Path, stem: str, prev_day: Optional[str] = None
):
    input_dir = root / "data" / "input"
    files = [
        input_dir / f"{stem}.txt",
        input_dir / f"{stem}_dummy.txt",
        root / "src" / f"{stem}.zig",
    ]
    for file in files:
        file.touch()
        window.open_file(str(file))
    data = dedent(
        f"""
        const std = @import("std");
        const read_input = @import("input.zig").read_input;

        pub fn part1(dataDir: std.fs.Dir) !void {{
            var buffer: [10000]u8 = undefined;
            var fba = std.heap.FixedBufferAllocator.init(&buffer);
            const allocator = fba.allocator();
            const input = try read_input(dataDir, allocator, "{stem}_dummy.txt");
            defer allocator.free(input);
            var lines = std.mem.split(u8, std.mem.trim(u8, input, "\\n"), "\\n");
        }}

        pub fn part2(dataDir: std.fs.Dir) !void {{
            var buffer: [14000]u8 = undefined;
            var fba = std.heap.FixedBufferAllocator.init(&buffer);
            const allocator = fba.allocator();
            const input = try read_input(dataDir, allocator, "{stem}_dummy.txt");
            defer allocator.free(input);
        }}
        """
    ).lstrip()
    files[-1].write_text(data)
    print(f"{prev_day=}")
    if prev_day:
        main_file = root / "src" / "main.zig"
        main_data = main_file.read_text()
        main_file.write_text(main_data.replace(prev_day, stem))
    if m := DAY_PAT.match(stem):
        download_input(int(m.group(1)), files[0])


def get_next_file(input_dir: Path):
    prev_day = max(
        list(input_dir.glob("day*")),
        default=None,
        key=lambda d: int(DAY_PAT.match(d.stem).group(1)),
    )
    if not prev_day:
        return None, "day1"
    m = DAY_PAT.match(prev_day.stem)
    assert m is not None
    prev_day_num = int(m.group(1))
    return f"day{prev_day_num}", f"day{prev_day_num + 1}"


def download_input(day: int, out_file: Path):
    URL = f"https://adventofcode.com/2022/day/{day}/input"
    resp = requests.get(URL, cookies={"session": SESS_COOKIE})
    if resp:
        out_file.write_text(resp.text)


class AocScaffoldCommand(sublime_plugin.WindowCommand):
    def run(self, *args, **kwargs):
        folder = self.window.folders()[0]
        assert folder.endswith("zig-aoc22")
        root = Path(folder)
        input_dir = root / "data" / "input"
        prev_day, next_day = get_next_file(input_dir)
        self.window.show_input_panel(
            "File stem",
            next_day,
            on_done=lambda stem: threading.Thread(
                target=lambda: create_files(
                    self.window, root, stem, prev_day if stem == next_day else None
                )
            ).start(),
            on_change=None,
            on_cancel=None,
        )

    def is_enabled(self):
        folders = self.window.folders()
        if not folders:
            return
        return folders[0].endswith("zig-aoc22")
