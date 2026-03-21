---
name: nvarena_controller
description: "Use when the user wants to start trading, manage positions, check portfolio P&L, configure risk rules, switch between paper and live trading, or control the automated trading pipeline. Receives signals from the signal monitor, manages positions, enforces risk rules (reserve, max positions, daily loss limits, max hold), and routes trades to executors (paper, Hyperliquid, etc.). The main entry point for running the full trading system."
metadata: {"openclaw":{"requires":{"bins":["node"]},"primaryEnv":"NVARENA_API_KEY"}}
---

# NVArena Controller v1 — Position Manager & Trade Router

Receives signals from the signal monitor, manages positions, enforces risk rules, and routes trade commands to an executor. Spawns the monitor automatically — one command starts the full pipeline.

## Setup

On first use, install dependencies:

```bash
cd {baseDir} && npm install yaml 2>/dev/null || (npm init -y && npm install yaml)
```

The controller auto-discovers the monitor and executor skills from sibling folders. Requires strategies to be saved in the claw skill's `strategies/` folder (via `node claw.js assemble`).

## Usage

```bash
# Start the full pipeline (spawns monitor, processes signals, routes trades)
cd {baseDir} && node controller.js

# Check current positions and P&L without starting
cd {baseDir} && node controller.js --status

# Help
cd {baseDir} && node controller.js --help
```

On first run, a default `controller.yaml` config is created. Edit it to configure risk rules, executor, and allocations.

## Config — controller.yaml

```yaml
# Executor — which skill handles trades
executor: paper                  # paper | hyperliquid | auto

# Human confirmation before each trade
confirm: false                   # true = ask before trading (not yet implemented)

# Risk management
risk:
  reserve_pct: 20                # % of balance to keep as cash reserve
  max_positions: 3               # max concurrent open positions across all coins
  max_daily_loss_pct: 5          # stop trading for the day if daily loss exceeds this %
  max_hold_hours: 48             # force close if held longer (uses lower of this or signal's)
  entry_end_action: hold         # hold | close — what to do when entry signal is lost

# Portfolio allocation — % of tradeable capital per coin
# If omitted, equal weight across coins with strategies
allocations:
  BTC: 40
  ETH: 35
  SOL: 25
```

### Config fields explained

- **executor**: `paper` (default, simulated), `hyperliquid` (live trading), `auto` (try Hyperliquid, fall back to paper)
- **reserve_pct**: percentage of total balance that's never traded — always kept as cash
- **max_positions**: total across all coins, not per coin
- **max_daily_loss_pct**: if daily P&L drops below this % of equity, controller stops opening new positions for the day
- **max_hold_hours**: force-closes positions held longer than this, or the signal's `maxHoldHours`, whichever is lower
- **entry_end_action**: when the monitor reports ENTRY_END (entry condition lost), `hold` keeps the position open waiting for EXIT, `close` exits immediately
- **allocations**: how tradeable capital (balance minus reserve) is distributed. BTC: 40 means 40% of tradeable capital goes to BTC positions

## Position Sizing

The controller calculates position size dynamically:

1. Reads actual balance from executor (`balance` command)
2. Subtracts reserve: `tradeable = balance × (1 - reserve_pct / 100)`
3. Applies coin allocation: `size = tradeable × (allocation / 100)`

If the user deposits more, positions scale up. If they withdraw, positions scale down. The controller never stores a fixed capital number.

## Signal Processing

The controller processes three event types from the monitor:

- **ENTRY** → risk checks → if passed, execute trade → track position
- **EXIT** → close position → record P&L
- **ENTRY_END** → check `entry_end_action` config → hold or close

### Risk checks on ENTRY:
1. No existing position for this coin
2. Under max positions limit
3. Daily loss limit not exceeded
4. Position size is at least $1

## Startup Flow

1. Load `controller.yaml` config
2. Load `state.json` (positions, P&L, trade history)
3. Initialize executor (paper or Hyperliquid)
4. Sync with executor — detect orphan positions
5. Spawn the signal monitor (auto-discovers strategies)
6. Begin processing signals
7. Check hold timers every 60 seconds

## Orphan Detection

On startup, the controller compares its state with the executor:

- **Orphan on executor**: position exists on exchange but controller doesn't know about it → warns the user
- **Stale in state**: controller tracks a position but executor doesn't have it → cleans up state

## File Structure

```
envy-controller/
  controller.js        Main script
  controller.yaml      Config (user-editable)
  state.json           Position state, P&L, history (auto-managed)
  paper_trades.jsonl   Paper trade log (paper mode only)
  SKILL.md             This file
```

## Executors

### Paper (default)
Simulated trading. No real funds. Tracks virtual positions and P&L. Uses real prices from the claw skill's indicator data. Trade log written to `paper_trades.jsonl`.

### Hyperliquid
Live perpetual futures trading. Requires:
- Hyperliquid skill installed as a sibling skill
- Environment variables: `HYPERLIQUID_ADDRESS`, `HYPERLIQUID_PRIVATE_KEY`

### Auto
Tries to find and use Hyperliquid. If not available or not configured, falls back to paper.

## Output

The controller emits position events to stdout as JSON lines:

```json
{"event":"POSITION_OPENED","coin":"BTC","direction":"LONG","signal":"RSI_OVERSOLD","price":84000,"sizeUsd":240,"timestamp":"..."}
{"event":"POSITION_CLOSED","coin":"BTC","direction":"LONG","signal":"RSI_OVERSOLD","entryPrice":84000,"exitPrice":85200,"pnlPct":1.43,"pnlUsd":3.43,"reason":"exit_signal","timestamp":"..."}
```

Logs go to stderr. Position events go to stdout.

## Architecture

```
claw.js assemble → strategies/ → monitor.js → controller.js → executor
                                                    ↓
                                              state.json
```

The claw skill creates signals and strategies. The monitor watches live data. The controller makes decisions and manages risk. The executor places trades.

## Response Guidelines

1. **Starting up** — Before running the controller, verify: subscription is active (`node claw.js status`), strategies exist (`node claw.js list-strategies`), and `controller.yaml` is configured.
2. **First time** — Run with `executor: paper` first. Let the user see signals and paper trades before switching to live.
3. **Checking status** — Use `node controller.js --status` to show positions and P&L without starting the full pipeline.
4. **Config changes** — Edit `controller.yaml` directly. The controller reads it on startup, not live. Restart to apply changes.
5. **Live trading** — Requires executor skill installed and env vars set. Always confirm with the user before switching from paper to live.
6. **Risk** — Explain what each risk parameter does. The reserve ensures the user always has cash. The daily loss limit is a circuit breaker.
7. **Errors** — If monitor can't find strategies, run `node claw.js assemble` first. If executor fails, check env vars and skill installation.

## Typical Workflow

1. Build strategies: `cd ../envy-claw && node claw.js assemble --yaml signals.yaml --mode normal`
2. Configure: edit `controller.yaml` (executor, risk, allocations)
3. Test with paper: `cd {baseDir} && node controller.js`
4. Review: `cd {baseDir} && node controller.js --status`
5. Go live: change `executor: hyperliquid` in config, set env vars, restart
