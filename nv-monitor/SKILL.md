---
name: nvarena_signal_monitor
description: "Use when the user wants to monitor live crypto signals, watch for trade entries/exits, run strategies against real-time data, or set up automated signal alerts. Supports multiple strategies across multiple coins via a single WebSocket (max 10 coins). Emits ENTRY/ENTRY_END/EXIT events on state transitions. Auto-discovers strategies from the claw skill's strategies/ folder. Stateless — feeds into a Controller skill for position management and execution."
metadata: {"openclaw":{"requires":{"bins":["node"]},"primaryEnv":"NVARENA_API_KEY"}}
---

# NVArena Signal Monitor v3 — Multi-Strategy Stateless Signal Emitter

Connects to the NVArena real-time indicator WebSocket, evaluates signal expressions for multiple coins/strategies every 15 seconds, and emits events on state transitions. Single WebSocket connection, up to 10 coins. Auto-discovers strategies from the claw skill's `strategies/` folder — zero configuration needed.

## Setup

On first use, install dependencies:

```bash
cd {baseDir} && npm install ws yaml 2>/dev/null || (npm init -y && npm install ws yaml)
```

Requires an active NVArena subscription (API key). The monitor auto-discovers both the API key and strategies by scanning sibling skill folders.

## Usage

```bash
# Zero-config — auto-discovers strategies from claw skill's strategies/ folder
cd {baseDir} && node monitor.js

# Explicit single strategy
cd {baseDir} && node monitor.js --strategy path/to/btc_strategy.yaml

# Multiple strategies
cd {baseDir} && node monitor.js --strategy btc.yaml --strategy eth.yaml --strategy sol.yaml

# Load all strategies from a specific folder
cd {baseDir} && node monitor.js --strategies ./my_strategies/

# With file output and webhook
cd {baseDir} && node monitor.js --file signals.jsonl --webhook https://my.server/signals

# Quiet mode — only JSON on stdout (for piping to Controller)
cd {baseDir} && node monitor.js --quiet | node ../controller/controller.js
```

## Auto-Discovery

When run with no `--strategy` or `--strategies` flags, the monitor automatically:

1. Scans sibling skill folders for a `strategies/` directory containing `.yaml` files
2. Loads all strategies found
3. Extracts unique coins and sets the WebSocket filter

This means the typical workflow is:

```bash
# In the claw skill — assemble saves to strategies/ automatically
cd ../envy-claw && node claw.js assemble --yaml signals.yaml --mode normal

# In the monitor skill — just run, it finds everything
cd {baseDir} && node monitor.js
```

No paths, no flags, no configuration.

## Strategy YAML Format

The monitor accepts strategy YAML files — either output from `node claw.js assemble` (auto-saved) or hand-crafted. Each file covers one coin:

```yaml
coin: BTC
signals:
  - priority: 1
    name: RSI_OVERSOLD_TREND
    signal_type: LONG
    expression: "RSI_3H30M <= 30 AND ADX_3H30M >= 25"
    exit_expression: "RSI_3H30M >= 70"
    max_hold_hours: 48
  - priority: 2
    name: MOMENTUM_SHORT
    signal_type: SHORT
    expression: "CMO_3H30M <= -40"
    exit_expression: "CMO_3H30M >= 0"
    max_hold_hours: 24
```

Fields per signal:
- `priority` — evaluation order (1 = highest, checked first)
- `name` — identifier for the signal
- `signal_type` — LONG or SHORT
- `expression` — entry condition using indicator codes with AND/OR
- `exit_expression` — exit condition
- `max_hold_hours` — included in ENTRY events for the Controller to enforce

## Signal Output Format

Three event types, each a single JSON line:

**ENTRY** — entry expression just became true (signal is active):
```json
{"event":"ENTRY","coin":"BTC","direction":"LONG","signal":"RSI_OVERSOLD_TREND","priority":1,"maxHoldHours":48,"timestamp":"...","indicators":{"RSI_3H30M":28.4,"ADX_3H30M":31.2}}
```

**ENTRY_END** — entry expression was true, just became false (signal lost, no exit triggered):
```json
{"event":"ENTRY_END","coin":"BTC","direction":"LONG","signal":"RSI_OVERSOLD_TREND","priority":1,"timestamp":"...","indicators":{"RSI_3H30M":35.1,"ADX_3H30M":22.0}}
```

**EXIT** — exit expression just became true:
```json
{"event":"EXIT","coin":"BTC","direction":"LONG","signal":"RSI_OVERSOLD_TREND","priority":1,"timestamp":"...","indicators":{"RSI_3H30M":71.2,"ADX_3H30M":28.5}}
```

## Event Lifecycle

A typical signal lifecycle for the Controller to handle:

1. `ENTRY` — condition fires → Controller decides whether to open a position
2. Either:
   - `EXIT` — explicit exit condition met → Controller closes position
   - `ENTRY_END` — entry condition lost, no exit yet → Controller decides: hold or bail?
3. Cycle repeats

The monitor does NOT track positions or enforce max hold hours. It just reports what's true and what changed. The Controller owns all that logic.

## Behavior

- Single WebSocket connection for all coins (max 10 unique coins)
- Evaluates ALL signals for ALL strategies on every 15s snapshot
- Emits only on state transitions — not every snapshot while a condition stays true
- Stateless — no position tracking, no grace periods, no preemption
- Auto-discovers API key and strategies from sibling skill folders
- Auto-reconnects on disconnect (up to 50 attempts with exponential backoff)
- Logs → stderr, signals → stdout (clean piping)
- Ctrl+C for graceful shutdown with session stats

## What It Does NOT Do

- No position tracking — that's the Controller's job
- No max hold enforcement — Controller reads `maxHoldHours` from ENTRY and manages timers
- No trading, no funds, no private keys, no exchange APIs
- No position sizing, no leverage decisions, no risk management

Product boundary: "here's what's true right now — you decide what to do."

## Architecture

```
claw.js assemble → strategies/*.yaml → Monitor (single WS, multi-coin) → Controller → Executor
```

The claw skill is the "brain" — it creates and manages signals and strategies. The monitor is the "eyes" — it watches live data and reports conditions. The Controller decides what to act on. The Executor places trades.

## Typical Workflow

1. Build strategies in the claw skill: `cd ../envy-claw && node claw.js assemble --yaml signals.yaml --mode normal` (auto-saved to strategies/)
2. Repeat for other coins
3. Start monitoring: `cd {baseDir} && node monitor.js` (auto-discovers strategies/)
4. Watch for signal events or pipe to Controller

## Response Guidelines

1. **Starting monitor** — Always verify the user has an active subscription first: `cd ../envy-claw && node claw.js status`
2. **Strategy files** — If the user doesn't have any, help them build strategies via `node claw.js assemble` first. Strategies auto-save to `strategies/`. Check what's available: `cd ../envy-claw && node claw.js list-strategies`
3. **Zero-config** — The default way to run is just `node monitor.js` with no flags. Only use `--strategy` or `--strategies` for overrides.
4. **Output** — Signals go to stdout as JSON lines. Recommend `--file` for persistence and `--webhook` for real-time delivery. Use `--quiet` when piping to Controller.
5. **Not trading** — Always remind users this emits signals only. They need a Controller + execution skill to act on signals.
6. **Events** — Explain the three event types: ENTRY (condition active), ENTRY_END (condition lost), EXIT (exit condition met). The Controller decides what to do with each.
7. **Errors** — If WebSocket disconnects repeatedly, check subscription status. If no strategies found, run `node claw.js list-strategies` to check what's saved. If no data for a coin, verify it's supported via `node claw.js coins`.
