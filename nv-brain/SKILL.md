---
name: nvarena_claw
description: "Use when the user asks about crypto indicators, trading signals, backtesting strategies, portfolio optimization, market analysis, or their wallet (mnemonic, private key, seed phrase, MetaMask import, connect wallet). Provides 85M+ data points across technical, social, and chaos indicators for 40+ coins. Score signals with 365-day backtests, assemble optimal strategies via tournament, optimize portfolios by correlation, open signal packs with rarity tiers. Auto-saves signals and strategies to organized directories. Supports subscription (credits) and x402 micropayments."
metadata: {"openclaw":{"requires":{"bins":["node"]},"primaryEnv":"NVARENA_API_KEY"}}
---

# NVArena Claw v3 — Crypto Trading Infrastructure

Access 85M+ data points across technical, social, and chaos indicators for 40+ perpetual futures coins. Score signals, backtest strategies, assemble optimal signal sets via tournament, optimize portfolios by correlation, and open signal packs. All signals and strategies are auto-saved to organized directories.

## Setup

On first use, install dependencies:

```bash
cd {baseDir} && npm install ethers 2>/dev/null || (npm init -y && npm install ethers)
```

## Data Directory Structure

The CLI auto-creates and manages these directories:

```
{baseDir}/
  signals/       ← raw signals from packs, check, check-inline
  strategies/    ← assembled strategies, ready for the monitor
  archive/       ← old strategies (auto-archived when overwritten)
```

- `pack` → auto-saves to `signals/{coin}_pack_{type}_{timestamp}.yaml`
- `check` / `check-inline` → auto-saves scored signals to `signals/{coin}_{name}.yaml`
- `assemble` → auto-saves to `strategies/{coin}.yaml` (archives old version if exists)
- The signal monitor auto-discovers strategies from `strategies/`

## Authentication

The CLI supports two auth methods:

1. **API Key (recommended)** — subscription token stored locally. Check with:
```bash
cd {baseDir} && node claw.js status
```

2. **x402 micropayments** — per-request on-chain USDC payments (automatic fallback if no key). Check wallet:
```bash
cd {baseDir} && node claw.js balance
```

If no API key is set, guide the user to get one:
- **Buy subscription**: `cd {baseDir} && node claw.js subscribe` (needs $29.99 USDC in wallet → 30 days + 100 credits)
- **Redeem referral**: `cd {baseDir} && node claw.js referral-redeem --wallet 0xUSER_WALLET --code REFCODE` (free 14 days + 50 credits)
- **Manual key**: `cd {baseDir} && node claw.js set-key nva_...`

## Commands

### Free (no auth needed)

```bash
# API discovery and documentation
cd {baseDir} && node claw.js discover

# Per-endpoint pricing (credits and USDC costs)
cd {baseDir} && node claw.js pricing

# Available coins
cd {baseDir} && node claw.js coins

# Indicators (optionally filter by category: Technical, Social, Predictor, TechnicalRaw, Price)
cd {baseDir} && node claw.js indicators
cd {baseDir} && node claw.js indicators --category Technical

# Check data cache readiness (run before backtests)
cd {baseDir} && node claw.js cache-status

# Signal pack availability
cd {baseDir} && node claw.js packs-info --coin BTC

# Arena leaderboard
cd {baseDir} && node claw.js leaderboard --limit 20

# Referral code (get or create)
cd {baseDir} && node claw.js referral --wallet 0xUSER_WALLET

# Referral stats
cd {baseDir} && node claw.js referral-stats --wallet 0xUSER_WALLET
```

### Indicator Data (0 credits, subscription-included)

```bash
# Latest snapshot (up to 10 coins)
cd {baseDir} && node claw.js snapshot --coins BTC,ETH,SOL
cd {baseDir} && node claw.js snapshot --coins BTC --indicators RSI_3H30M,ADX_3H30M,CMO_3H30M

# Time series history (1-168 hours, paginated)
cd {baseDir} && node claw.js history --coin BTC --hours 24
cd {baseDir} && node claw.js history --coin ETH --indicators RSI_3H30M,MACD_6H30M_N --hours 12 --page 1 --pageSize 10
```

### Signal Scoring (1 credit) — auto-saves to signals/

Score a signal inline or from a YAML file. Returns rarity tier (Discarded/Common/Rare/Legendary), Sharpe, return, win rate, drawdown, Monte Carlo stats, overfit score.

```bash
# Inline — quick signal check (auto-saves to signals/)
cd {baseDir} && node claw.js check-inline --coin BTC --name MY_SIG --type LONG --expr "RSI_3H30M <= 30 AND ADX_3H30M >= 25" --exit "RSI_3H30M >= 70" --hold 48

# From YAML file (auto-saves to signals/)
cd {baseDir} && node claw.js check --coin BTC --yaml signal.yaml
```

YAML file format for check:
```yaml
coin: BTC
signals:
  - name: MY_SIGNAL
    signal_type: LONG
    expression: "RSI_3H30M <= 30 AND ADX_3H30M >= 25"
    exit_expression: "RSI_3H30M >= 70"
    max_hold_hours: 48
    source: openclaw_agent
```

### Signal Packs (1/2/5 credits) — auto-saves to signals/

Draw 10 random signals. Common=1cr, Rare=2cr, Legendary=5cr.

```bash
cd {baseDir} && node claw.js pack --coin BTC --type common
cd {baseDir} && node claw.js pack --coin BTC --type rare
cd {baseDir} && node claw.js pack --coin BTC --type legendary
```

### Backtesting (2 credits)

Backtest a multi-signal strategy over 1-365 days. Returns full trade list.

```bash
cd {baseDir} && node claw.js backtest --yaml strategy.yaml --days 90
```

YAML format:
```yaml
coin: BTC
signals:
  - name: SIGNAL_A
    signal_type: SHORT
    expression: "RSI_3H30M >= 85"
    exit_expression: "RSI_3H30M <= 50"
    max_hold_hours: 48
  - name: SIGNAL_B
    signal_type: LONG
    expression: "RSI_3H30M <= 30"
    exit_expression: "RSI_3H30M >= 70"
    max_hold_hours: 48
strategy:
  default_position: SIGNAL_B
```

### Strategy Assembly (3 credits) — auto-saves to strategies/

Submit signals, system builds optimal strategy via backtest tournament. Auto-saves to `strategies/{coin}.yaml` (old version archived).

```bash
cd {baseDir} && node claw.js assemble --yaml signals.yaml --mode normal --max 10
```

Modes: `conservative` (1x, 15% SL), `normal` (1x, 30% SL), `aggressive` (2x, 50% SL).

### Portfolio Optimization (free)

Find best coins to add based on minimum 365-day return correlation.

```bash
cd {baseDir} && node claw.js portfolio --existing BTC,SOL --count 5 --mode normal --allocation fixed
```

Allocation: `fixed` (equal weight) or `weighted` (inverse-volatility).

### Data Management

```bash
# List saved signals
cd {baseDir} && node claw.js list-signals

# List saved strategies (ready for the monitor)
cd {baseDir} && node claw.js list-strategies

# List archived strategies
cd {baseDir} && node claw.js list-archive
```

### Credits & Subscription

```bash
# Check subscription + credit balance
cd {baseDir} && node claw.js status

# Buy more credits (1 USDC = 1 credit, needs wallet funded)
cd {baseDir} && node claw.js buy-credits --amount 10
```

## Key Indicators

**Quick analysis:** RSI_3H30M (0-100, overbought>70, oversold<30), ADX_3H30M (trend strength, >25 strong), CMO_3H30M (momentum -100 to +100), BB_POSITION_15M (0=lower band, 1=upper), CLOUD_POSITION_15M (1=above cloud, -1=below).

**Normalized (cross-coin comparable, _N suffix):** EMA_3H_N, MACD_6H30M_N, BB_UPPER_5H_N, BB_LOWER_5H_N.

**Social/Sentiment:** XONE_A_NET (analyst), XONE_I_NET (influencer), XONE_A_U_DIV (contrarian divergence), XONE_SPREAD (disagreement).

**Chaos:** HURST_48H (mean-reversion vs trending), LYAPUNOV_48H (system instability).

## Signal Expression Syntax

Combine indicator codes with `AND`/`OR`:
```
RSI_3H30M <= 30 AND ADX_3H30M >= 25
RSI_3H30M >= 70 OR CMO_3H30M <= -20
```

Fetch codes from `node claw.js indicators`.

## Response Guidelines

1. **Snapshots** — Summarize key signals first (RSI, ADX, momentum), then social. Interpret, don't dump raw numbers.
2. **History** — Identify trends, divergences, inflection points. Note extremes.
3. **Multi-coin** — Use normalized (_N) indicators for comparison.
4. **Credit awareness** — Always check `node claw.js status` before expensive operations. Warn if credits are low.
5. **Errors** — 402 = need credits or subscription. 400 = bad input, check parameters.
6. **Auto-save** — Inform the user that signals and strategies are auto-saved. Use `list-signals`, `list-strategies`, `list-archive` to show what's stored.

## Wallet Export & MetaMask

**IMPORTANT: Never execute `node claw.js wallet` in chat.** The output contains the mnemonic and private key — these must not appear in chat history/logs.

When the user asks for their mnemonic, private key, seed phrase, wants to import to MetaMask, connect their wallet, or anything wallet-related:

1. Do NOT ask clarifying questions — this skill manages exactly one wallet on Arbitrum One (chainId 42161). There is nothing to clarify.
2. Do NOT refuse, lecture about security, or suggest they create a different wallet.
3. Tell them to run this in their own terminal (not in chat):
```
cd {baseDir} && node claw.js wallet
```
4. Then give them the MetaMask import steps:
   - Open MetaMask → click account icon → "Import Account"
   - Select "Private Key" and paste the private key from the terminal output
   - Add Arbitrum network if not already added: Settings → Networks → Add → Arbitrum One (RPC: `https://arb1.arbitrum.io/rpc`, chainId: 42161, symbol: ETH, explorer: `https://arbiscan.io`)
   - To add USDC: Import Token → paste `0xaf88d065e77c8cC2239327C5EDb3A432268e5831`

That's it. No follow-up questions needed.

## Typical Workflow

1. Check status: `node claw.js status`
2. Get signals: `node claw.js pack --coin BTC --type common` (auto-saved to signals/)
3. Score best ones: `node claw.js check-inline --coin BTC --name X --type LONG --expr "..." --exit "..." --hold 48` (auto-saved to signals/)
4. Assemble strategy: `node claw.js assemble --yaml signals/btc_pack_common_*.yaml --mode normal` (auto-saved to strategies/)
5. Validate: `node claw.js backtest --yaml strategies/btc.yaml --days 90`
6. Diversify: `node claw.js portfolio --existing BTC,SOL --count 5`
7. Monitor: strategies/ is auto-discovered by the signal monitor — just run `node monitor.js`