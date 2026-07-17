# shelpy

Mostly shell helper scripts.

## scripts

1. Call graph drawer using cscope (`cscope2dot.py`)
1. Difference limiter to single function
1. shell lib for loaders
1. shell lib for tracking shifts
1. shell lib for logging

### `libshift.sh`

Implement `shift_prepare` and `shift_cleanup` to run custom tasks after
`shift_start` and `shift_end`.

```bash
$ source ./libshift.sh
$ shift_start
[*] shift started at: 2026-07-18T03:44:47+05:00
$ shift_end
[*] shift started at: 2026-07-18T03:44:47+05:00
[*] shift ended at: 2026-07-18T03:44:51+05:00
[*] lasted for: 00:00:04
```

### `libload.sh`

Runs custom command with prepending pretty loader before it until the command
finishes.

```bash
$ source ./libload.sh
$ load_dots_sync sleep 5s
⠧ sleep 5s
```

After 5 seconds:
```bash
$ source ./libload.sh
$ load_dots_sync sleep 5s
✓ sleep 5s
```

### `liblog.sh`

```bash
$ source ./liblog.sh
$ log_info 'Hello, World!\n'
[    INFO]: Hello, World!
```
