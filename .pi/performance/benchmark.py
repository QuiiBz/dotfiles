import argparse
import errno
import fcntl
import json
import os
import pty
import select
import statistics
import struct
import subprocess
import termios
import time


def measure_startup(command, terminal_replies):
    master_fd, slave_fd = pty.openpty()
    fcntl.ioctl(slave_fd, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
    environment = dict(os.environ, PI_STARTUP_BENCHMARK="1", PI_STARTUP_READY="1", PI_TIMING="1", TERM="xterm-256color")
    start_time = time.perf_counter()
    process = subprocess.Popen([command, "--no-session"], stdin=slave_fd, stdout=slave_fd, stderr=slave_fd, env=environment)
    os.close(slave_fd)
    output = bytearray()
    ready_ms = None
    replied_queries = 0
    try:
        while time.perf_counter() - start_time < 10:
            if not select.select([master_fd], [], [], 0.1)[0]:
                if process.poll() is not None:
                    break
                continue
            try:
                chunk = os.read(master_fd, 65536)
            except OSError as error:
                if error.errno == errno.EIO:
                    break
                raise
            if not chunk:
                break
            output.extend(chunk)
            if terminal_replies:
                query_count = output.count(b"\x1b[c")
                if query_count > replied_queries:
                    os.write(master_fd, b"\x1b[?1;2c" * (query_count - replied_queries))
                    replied_queries = query_count
            if ready_ms is None:
                if b"PI_STARTUP_READY\n" in output or b"PI_STARTUP_READY\r\n" in output:
                    ready_ms = (time.perf_counter() - start_time) * 1000
                elif b"\x1b[?2004l" in output:
                    # Pi's benchmark waits 150 ms after init before it stops the TUI.
                    ready_ms = (time.perf_counter() - start_time) * 1000 - 150
        exit_code = process.wait(timeout=2)
        if exit_code != 0 or ready_ms is None or b"Failed to load extension" in output:
            raise RuntimeError(output.decode(errors="replace"))
        return ready_ms
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        os.close(master_fd)


parser = argparse.ArgumentParser()
parser.add_argument("commands", nargs="+", help="Executable paths to compare")
parser.add_argument("--runs", type=int, default=10)
parser.add_argument("--no-terminal-replies", action="store_true")
arguments = parser.parse_args()
if arguments.runs < 1:
    parser.error("--runs must be at least 1")
for command in arguments.commands:
    measure_startup(command, not arguments.no_terminal_replies)
    measurements = [measure_startup(command, not arguments.no_terminal_replies) for _ in range(arguments.runs)]
    print(json.dumps({"command": command, "runs": arguments.runs, "median_ms": round(statistics.median(measurements), 1), "min_ms": round(min(measurements), 1), "max_ms": round(max(measurements), 1), "samples_ms": [round(value, 1) for value in measurements]}))
