# 📡 p-check — ICMP Packet Loss Analyzer

`p-check.sh` is a lightweight, cross-distro Bash script for analyzing ICMP packet loss from `ping` logs.  
It supports progress tracking, optional verbose output for missing sequences, and accurate wraparound handling (65535 ➝ 0).

---

## ✨ Features

- ✅ Detects missing ICMP packets based on `icmp_seq`
- ✅ Wraparound-safe (when sequence resets from 65535 to 0)
- ✅ Verbose mode to print exact missing ranges
- ✅ Efficient log scanning using a streaming parser
- ✅ Live progress percentage (non-intrusive, single-line)
- ✅ Compatible with large logs and long-running pings

---

## 📥 How to Create a Ping Log (Safe Background Mode)

To start a `ping` session that runs even if your terminal closes:

```bash
nohup ping 1.1.1.1 >> ping.log 2>&1 &
```

- `nohup` allows it to survive terminal closure  
- `>> ping.log` appends ping output to a file  
- `2>&1` redirects errors into the same log  
- `&` sends it to the background

You do not need to stop the `ping` process to analyze the log. You can run the `p-check` script on the fly while `ping` is still running.

---

## 🔍 How to Monitor or Stop a Running Ping

To find the running `ping` process:

```bash
ps aux | grep "[p]ing 1.1.1.1"
```

You’ll see something like:
```
root     12345  0.0  0.1  2600  820 ?   S   14:12   0:00 ping 1.1.1.1
```

Then stop it **gracefully** (this prints the final ping summary):

```bash
kill -2 12345
```

This is equivalent to pressing `Ctrl+C`.

---

## 🧠 How It Works

The script scans the ping log line-by-line:
- Extracts the sequence number (`icmp_seq`)
- Tracks missing values between each pair
- Handles sequence wraparound (65535 ➝ 0)
- Computes:
  - total expected packets
  - total received
  - total lost
  - loss percentage
- Shows real-time progress (based on file size)

---

## 🧪 Example Usage

Basic:

```bash
./p-check.sh ping.log
```

Verbose:

```bash
./p-check.sh -v ping.log
```

Output:
```
Missing packets between 103 and 105
Missing packets between 108 and 110
📄 File analyzed    : ping.log
✅ Packets received : 945
❌ Packets lost     : 10
📦 Total expected   : 955
📉 Packet loss      : 1.05 %
```

In **non-verbose mode**, only the real-time progress and final summary are shown.

To make the script executable and run it:

```bash
chmod +x p-check.sh
./p-check.sh ping.log
```

---

## ⚙️ Command-Line Options

```bash
./p-check.sh [-v|--verbose] <log_file>
```

| Option       | Description                                       |
|--------------|---------------------------------------------------|
| `-v`         | Verbose mode: print each missing range            |
| `-h`         | Show help and usage                               |
| `<log_file>` | Log file generated by `ping`                      |

---

## 📦 System Requirements

This script works on **any modern Linux distribution** that includes the following tools:

| Tool     | Purpose                     | Included in        |
|----------|-----------------------------|--------------------|
| `bash`   | Scripting shell              | All major distros  |
| `grep`   | Sequence number extraction   | GNU coreutils      |
| `sed`    | POSIX-compatible replacement | GNU coreutils      |
| `awk`    | Math operations              | GNU coreutils      |
| `stat`   | File size checking           | GNU coreutils      |
| `tput`   | Cursor positioning (progress)| ncurses            |

✅ Tested on:
- Debian / Ubuntu / Linux Mint
- Fedora / RHEL / CentOS
- Arch / Manjaro
- Alpine Linux (with `grep -P` workaround, see below)

---

## 🧩 Alpine Linux Compatibility

Alpine uses `busybox grep`, which doesn't support `-P` (Perl regex).  
To make the script work in Alpine:

Replace this line:

```bash
seq=$(echo "$line" | grep -oP 'icmp_seq=\K[0-9]+')
```

With this:

```bash
seq=$(echo "$line" | sed -n 's/.*icmp_seq=\([0-9]\+\).*//p')
```

This `sed` version is portable and POSIX-compliant.

---

## 📈 Performance Notes

- No memory issues: log is read line-by-line, not loaded fully into memory
- For huge logs (e.g. >1GB), progress remains responsive
- CPU usage is minimal unless `-v` is used (more output)

---

## 🔧 TODO (optional improvements)

- Interactive progress bar
- Estimated time remaining
- Real-time ping stats (live mode)

---

## 🪪 License

MIT License — feel free to use, fork, or modify.

---

## 👤 Author

Developed with 💻 and 📶 by [Lucian Udrea](https://github.com/lucianudrea)
