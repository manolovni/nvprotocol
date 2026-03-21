# NVProtocol Trading System

Non-custodial AI trading agent for crypto perpetual futures. Analyzes 85M+ data points, scores signals with 365-day backtests, assembles optimal strategies, and trades automatically via OpenClaw.

**Your keys. Your wallet. Your strategies. Open source.**

## What It Does

```
You: "Set me up for trading"

Agent: Building portfolio... BTC, MATIC, FET
       Opening signal packs... 30 signals scored
       Assembling strategies...
       ✓ BTC: +94.7% return, 2.57 Sharpe
       ✓ MATIC: +67.2%, 1.89 Sharpe  
       ✓ FET: +112.4%, 3.01 Sharpe
       Starting paper trader... watching 3 coins, 30 signals

You: "How are my positions?"

Agent: 2 open — BTC LONG +1.2%, FET SHORT -0.3%
       Daily P&L: +$12.40
```

## Architecture

```
nv-brain (data & strategies) → nv-monitor (live signals) → nv-controller (trades)
```

- **nv-brain** — 22 API endpoints. Indicators, signal scoring, backtesting, strategy assembly, portfolio optimization. The data engine.
- **nv-monitor** — Connects to real-time WebSocket. Evaluates signal expressions every 15 seconds. Emits ENTRY/EXIT/ENTRY_END events on state transitions. Stateless.
- **nv-controller** — Receives signals, manages positions, enforces risk rules (reserve, max positions, daily loss limits, max hold), routes trades to executors.

## Install

Requires [OpenClaw](https://docs.openclaw.ai/install) and Node.js 22+.

```bash
cd ~/.openclaw/workspace/skills
git clone https://github.com/manolovni/nvprotocol
cd nvprotocol && bash install.sh
```

Restart OpenClaw. Done.

## Quick Start

In OpenClaw chat:

```
"Set me up for trading"
```

The agent handles everything — subscription, portfolio, signals, strategies, and starts paper trading.

### With a referral code (free 14-day trial + 50 credits):

```
"Redeem referral code XXXX and set me up for trading"
```

## Manual Setup

If you prefer step-by-step:

```
1. "Check my subscription status"
2. "Open a common signal pack for BTC"
3. "Assemble a BTC strategy in normal mode"
4. "Start the monitor"
5. "Check my positions"
```

## Configuration

### Risk Rules — `nv-controller/controller.yaml`

```yaml
executor: paper              # paper | hyperliquid | auto
risk:
  reserve_pct: 20            # keep 20% as cash
  max_positions: 3           # max concurrent positions
  max_daily_loss_pct: 5      # circuit breaker
  max_hold_hours: 48         # force close after 48h
  entry_end_action: hold     # hold | close when signal lost

allocations:
  BTC: 40
  ETH: 35
  SOL: 25
```

### Executors

| Executor | What it does | Required |
|----------|-------------|----------|
| `paper` | Simulated trading, no real funds (default) | Nothing |
| `hyperliquid` | Live perpetual futures trading | Hyperliquid skill + private key |
| `auto` | Try Hyperliquid, fall back to paper | Nothing |

## Data Flow

```
NVArena API (85M+ data points, 40+ coins, 46 indicators)
    ↓
nv-brain: score signals, assemble strategies, save to strategies/
    ↓
nv-monitor: connect WebSocket, evaluate expressions every 15s
    ↓
nv-controller: risk checks → position sizing → execute trade
    ↓
Executor (paper / Hyperliquid / your own)
```

## Key Features

- **Non-custodial** — wallet created locally, keys never leave your machine
- **Open source** — verify everything yourself
- **Real data** — 85M+ indicator data points, not toy data
- **Backtested** — every signal scored with 365-day backtest, Monte Carlo validation, overfit detection
- **Auto-discovery** — skills find each other, API keys, strategies automatically
- **Paper mode** — test with real data, no real money at risk
- **Portable** — macOS, Linux, Windows (WSL2)

## Signal Events

The monitor emits three event types:

| Event | Meaning | Controller Action |
|-------|---------|-------------------|
| `ENTRY` | Entry condition just became true | Open position (if risk allows) |
| `ENTRY_END` | Entry condition lost (no exit yet) | Hold or close (configurable) |
| `EXIT` | Exit condition just became true | Close position |

## API

The backend API at `arena.nvprotocol.com` provides:

- 40+ perpetual futures coins
- 46 indicators (technical, social, chaos)
- Signal packs with rarity tiers (Common/Rare/Trump)
- 365-day backtesting with Monte Carlo validation
- Strategy assembly via backtest tournament
- Portfolio optimization via return correlation
- Real-time WebSocket indicator stream (15s updates)
- x402 micropayments + subscription system

## License

MIT — do whatever you want with the client code.

The API backend is a paid service. Subscription: $29.99/month or use a referral code for a free trial.
