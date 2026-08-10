---
name: java-debugger
description: Connect to and control a Java application debugger via JDWP. Attach to running JVMs, set breakpoints, inspect variables, modify state at runtime, and step through code. Use when debugging Java/Spring Boot applications, diagnosing exceptions, or inspecting runtime state in development or Kubernetes environments.
version: 1.0.0
author: opencode
type: skill
category: debugging
tags:
  - java
  - debugger
  - jdb
  - jdwp
  - spring-boot
  - kubernetes
  - breakpoints
---

# Java Debugger Skill

> **Purpose**: Attach to running Java applications via JDWP (Java Debug Wire Protocol) and control the JDB debugger interactively — set breakpoints, inspect state, modify variables, and step through code.

---

## What I Do

I provide a persistent JDB debugging session managed through `screen`. Unlike ephemeral jdb connections that die between commands, my session stays alive so you can:

- **Set breakpoints** at specific lines or methods
- **Inspect variables** and object state at any breakpoint
- **Modify runtime variables** without restarting the application
- **Step through code** (step into, step over, step out)
- **List threads** and inspect thread state
- **Evaluate expressions** on the fly

---

## Prerequisites

- **JDWP enabled** on the target JVM (e.g., `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005`)
- **`screen`** installed (`apt-get install -y screen`)
- **`jdb`** available (comes with JDK)

---

## How to Use Me

### Quick Start

```bash
# Start a debugging session
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh start localhost 5005

# Set a breakpoint
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh bp com.example.MyController:42

# Set a breakpoint on a method
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh bp com.example.MyController.processRequest

# Resume the app (let it run until breakpoint hits)
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh resume

# When breakpoint hits, inspect state
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh locals
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh print this.fieldName
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh dump this

# Modify a variable
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh send 'set this.myField = "new value"'

# Step through code
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh next    # step over
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh step    # step into

# Resume after inspection
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh resume

# Stop debugging session
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh stop
```

### Command Reference

| Command | Description |
|---------|-------------|
| `start [host] [port]` | Start jdb session (default: localhost:5005) |
| `stop` | Stop the active session |
| `status` | Check if session is active and show target |
| `send <command>` | Send raw jdb command |
| `output [lines]` | Show recent jdb output (default: 30) |
| `clear` | Clear the output log |
| `breakpoints` | List all active breakpoints |
| `bp <target>` | Set breakpoint (class:line or class.method) |
| `rb <target>` | Remove breakpoint |
| `resume` | Resume all threads |
| `step` | Step into next statement |
| `next` | Step over (execute method call, don't enter) |
| `locals` | Show local variables at current frame |
| `dump <expr>` | Dump full object contents recursively |
| `print <expr>` | Print expression value |
| `threads` | List all threads and their states |
| `quit` | End session and quit jdb |

---

## Common Workflows

### 1. Debug a Spring Boot Controller

```bash
# Start session
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh start localhost 5005

# Set breakpoints on controllers
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh bp com.example.OwnerController.showOwner
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh bp com.example.PetController.processCreationForm

# Resume and wait for requests to trigger breakpoints
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh resume

# Trigger with curl: curl http://localhost:8080/owners/1

# When hit, inspect state
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh locals
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh dump model
```

### 2. Diagnose an Exception

```bash
# Start session
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh start localhost 5005

# Set exception breakpoints (break on any exception)
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh send "exception java.lang.Exception"

# Resume - app will break on any thrown exception
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh resume

# When exception hits, inspect
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh locals
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh send "exception"
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh send "where"
```

### 3. Modify Runtime State

```bash
# At a breakpoint, change a variable
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh send 'set this.APP_VERSION = "my-custom-version"'
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh send 'set this.debugMode = true'

# Resume to see the effect
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh resume
```

### 4. Inspect Thread State

```bash
# List all threads
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh threads

# Switch to a specific thread
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh send "thread <thread-id>"

# Show stack trace
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh send "where"
```

---

## Kubernetes / Sidecar Usage

When running as a sidecar in a K8s pod:

```bash
# The JDWP port is typically forwarded or exposed locally
# Connect to localhost:5005 (or wherever JDWP is bound)

bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh start localhost 5005

# Set breakpoints before traffic hits the pod
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh bp com.example.MyController.handleRequest

# Resume and wait
bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh resume

# Trigger via service endpoint or port-forward
```

---

## JDB Command Cheat Sheet

### Breakpoints
```
stop at com.example.MyClass:42        # Break at line 42
stop in com.example.MyClass.myMethod  # Break at method entry
clear com.example.MyClass:42          # Remove breakpoint
clear                                 # List all breakpoints
```

### Execution Control
```
run       # Start/Restart application
resume    # Resume execution
step      # Step into method call
next      # Step over method call
stepi     # Step one instruction
```

### Inspection
```
locals                          # Show local variables
dump <object>                   # Deep dump object
print <expression>              # Evaluate and print
eval <expression>               # Same as print
where                           # Show stack trace
where all                       # Stack trace for all threads
threads                         # List all threads
thread <id>                     # Switch to thread
```

### Variable Modification
```
set <variable> = <value>        # Modify a variable
set x = 42
set name = "new value"
set this.enabled = true
```

### Exception Handling
```
exception <class>               # Break on exception
exception clear                 # Remove exception breakpoint
```

---

## Troubleshooting

### "Connection refused" on start
- Verify JDWP is enabled on the target JVM
- Check the port: `curl localhost:5005` (will fail but confirms port is open)
- Check process: `ps aux | grep java` should show `-agentlib:jdwp`

### "Screen session not found"
- Session may have died. Check: `screen -list`
- Restart: `bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh stop && bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh start`

### Breakpoints not hitting
- Verify the class is loaded: use `classes` command in jdb
- Check package/class name spelling
- For line breakpoints, ensure the line is executable code (not declarations)

### Output looks stale
- Use `output` to refresh
- Use `clear` to reset the log

---

## Architecture

```
/root/.opencode/skills/java-debugger/
├── SKILL.md                          # This file
└── scripts/
    └── jdb-session.sh                # Session manager script
```

### How It Works

1. **`screen`** creates a persistent terminal session that survives between tool calls
2. **`jdb`** runs inside screen, attached to the target JVM via JDWP
3. **`jdb-session.sh`** sends commands to jdb via `screen -S <session> -X stuff`
4. **Output** is captured to `/tmp/jdb_screen.log` for reading

---

## Integration with OpenCode

### As a Subagent Prompt

When debugging Java applications, delegate to this skill:

```
Use the java-debugger skill to:
1. Connect to the app on localhost:5005
2. Set breakpoints on [specific classes/methods]
3. Inspect [specific variables/objects]
4. Report findings
```

### Example: Diagnosing a Bug

```
1. Start session: `bash /root/.opencode/skills/java-debugger/scripts/jdb-session.sh start`
2. Set breakpoint on the failing method
3. Resume and trigger the request
4. When hit: dump relevant variables
5. Step through to find where the bug occurs
6. Report the root cause
```

---

**Java Debugger Skill** — Persistent JDB sessions for interactive Java debugging!
