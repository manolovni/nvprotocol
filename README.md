# NVProtocol Trading System

Non-custodial AI trading agent for crypto perpetual futures. Built on 86M+ data points, 85 orthogonal indicators across 7 dimensions, and a signal engine rooted in nonlinear dynamics and chaos theory.

**Your keys. Your wallet. Your strategies. Open source.**

## What It Does

```
You: "Set me up for trading"

Agent: Building portfolio... BTC, ETH, SOL
       Opening signal packs... 30 signals scored
       Assembling strategies...
       ✓ BTC: +47.3% return, 1.82 Sharpe (168 trades, 365 days)
       ✓ ETH: +31.5% return, 1.44 Sharpe (203 trades, 365 days)
       ✓ SOL: +52.8% return, 1.67 Sharpe (189 trades, 365 days)
       Starting paper trader... watching 3 coins, 30 signals

You: "How are my positions?"

Agent: 2 open — BTC LONG +1.2%, ETH SHORT -0.3%
       Daily P&L: +$12.40
```

## Signal Philosophy

Most trading signals are entry detectors. A signal fires when a condition is met and the system trades.

NVProtocol signals are different. Their primary responsibility is not to find entries. It is to stay silent.

A signal here is a self-contained, regime-aware predicate. It knows not just what to look for, but when its own logic is valid. It fires only when multiple independent dimensions of market state simultaneously confirm that conditions are right. In all other states, it stays silent.

This is why Sharpe ratios hold over 365 days across different market regimes. The edge is not in the entries — it is in the refusal to trade when the market is not in a state where the signal's assumptions hold. Once regime is correctly detected, entry optimization contributes roughly 0.1–0.8% on top. The regime is the work.

## The Perception Layer

Price is a chaotic stochastic process. It is sometimes predictable, sometimes genuinely random. Most trading systems assume it is always one or the other. This is the foundational error.

NVProtocol measures predictability continuously using nonlinear dynamics:

- **Hurst exponent** — long-range memory in price series: trending, mean-reverting, or random walk
- **DFA (Detrended Fluctuation Analysis)** — fractal scaling behavior separated from noise
- **Lyapunov exponents** — sensitivity to initial conditions, how chaotic the system is right now
- **Strange attractor destabilization** — regime phase transition detection before it appears in price

These are not indicators layered on top of technical analysis. They are the mathematical foundation for knowing when any indicator is trustworthy at all. Linear TA indicators are approximations of a nonlinear system — valid in some regimes, meaningless in others. The chaos layer tells the system which is which.

The result is 13 mathematically derived market states — coordinates in Hurst × Lyapunov × DFA phase space. They do not have human names like "bull" or "bear." They are more precise than that.

## Indicator Depth

85 indicators across 7 independent dimensions, selected from 500+ candidates by filtering for genuine orthogonality in high-dimensional space:

| Category | What it captures |
|----------|-----------------|
| **Chaos** | Hurst, DFA, Lyapunov, attractor dynamics, regime state |
| **Technical** | Price structure, momentum, volatility |
| **TechnicalRaw** | Unsmoothed price derivatives for microstructure |
| **Price** | Cross-timeframe price relationships |
| **Social** | Analyst, influencer, and crowd sentiment — tracked independently with convergence/divergence signals |
| **CrossAsset** | Inter-market correlations including non-obvious relationships |
| **Predictor** | Forward-looking composite signals |

85 is not an arbitrary number. Correlated features were removed. What remains are independent views of market state across 40+ coins, updated every 15 minutes, over 427 days of history.

5,524 signals have been scored against this feature matrix to date.

## Engagement Levels

The API supports four levels of engagement depending on what you want to build:

**1. Raw Indicators** — access the live 85-dimension feature matrix directly. Snapshot or time series. Build your own signals, models, or visualizations on top of real data.

**2. Signals** — score your own signal expressions against 365 days of history, or open signal packs (Common / Rare / Legendary) to receive pre-scored signals with backtest metrics, Sharpe, drawdown, and rarity tier.

**3. Per-Coin Strategies** — submit a signal set and the strategy assembler runs a backtest tournament to find the optimal combination. Returns a priority-ordered strategy with full metrics.

**4. Portfolio Balancing** — provide your existing holdings and the optimizer finds additions with minimum return correlation. Constructs a portfolio across 40+ coins designed to reduce regime concentration.

Each level can be used independently or as a full pipeline.

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
NVArena API (86M+ data points, 40+ coins, 85 indicators, 427-day history, 5524 scored signals)
    ↓
nv-brain: score signals, assemble strategies, save to strategies/
    ↓
nv-monitor: connect WebSocket, evaluate expressions every 15s
    ↓
nv-controller: risk checks → position sizing → execute trade
    ↓
Executor (paper / Hyperliquid / your own)
```

## Signal Events

| Event | Meaning | Controller Action |
|-------|---------|-------------------|
| `ENTRY` | Entry condition just became true | Open position (if risk allows) |
| `ENTRY_END` | Entry condition lost (no exit yet) | Hold or close (configurable) |
| `EXIT` | Exit condition just became true | Close position |

## API

Full documentation: `GET https://arena.nvprotocol.com/api/claw/discover`

- 40+ perpetual futures coins
- 85 indicators across 7 categories (Chaos, CrossAsset, Predictor, Price, Social, Technical, TechnicalRaw)
- 5,524 scored signals with rarity tiers (Common / Rare / Legendary)
- 365-day backtesting with Monte Carlo validation and overfit detection
- Strategy assembly via backtest tournament
- Portfolio optimization via return correlation
- Real-time WebSocket stream (15s updates, up to 10 coins per connection)
- x402 micropayments + subscription system

## License

MIT — do whatever you want with the client code.

The API backend is a paid service. Subscription: $29.99/month or use a referral code for a free trial.