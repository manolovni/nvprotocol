#!/bin/bash
# NVProtocol Trading System — Installer
# Installs nv-brain, nv-monitor, nv-controller into OpenClaw skills directory

set -e

echo "═══════════════════════════════════════════"
echo "  NVProtocol Trading System v1.0"
echo "═══════════════════════════════════════════"
echo ""

# Detect skills directory
SKILLS_DIR=""
if [ -d "$HOME/.openclaw/workspace/skills" ]; then
  SKILLS_DIR="$HOME/.openclaw/workspace/skills"
elif [ -d "$HOME/.openclaw/skills" ]; then
  SKILLS_DIR="$HOME/.openclaw/skills"
else
  echo "⚠  OpenClaw skills directory not found."
  echo "   Install OpenClaw first: https://docs.openclaw.ai/install"
  echo ""
  read -p "   Enter your skills directory path (or press Enter to use ./skills): " CUSTOM_DIR
  SKILLS_DIR="${CUSTOM_DIR:-./skills}"
  mkdir -p "$SKILLS_DIR"
fi

echo "📁 Skills directory: $SKILLS_DIR"
echo ""

# Get the directory where this script lives (the cloned repo)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Install nv-brain
echo "── Installing nv-brain (data, signals, strategies) ──"
if [ -d "$SKILLS_DIR/nv-brain" ]; then
  echo "   Updating existing installation..."
  cp "$REPO_DIR/nv-brain/claw.js" "$SKILLS_DIR/nv-brain/claw.js"
  cp "$REPO_DIR/nv-brain/SKILL.md" "$SKILLS_DIR/nv-brain/SKILL.md"
  cp "$REPO_DIR/nv-brain/package.json" "$SKILLS_DIR/nv-brain/package.json"
else
  cp -r "$REPO_DIR/nv-brain" "$SKILLS_DIR/nv-brain"
fi
cd "$SKILLS_DIR/nv-brain" && npm install --silent 2>/dev/null
echo "   ✓ nv-brain installed"

# Install nv-monitor
echo "── Installing nv-monitor (live signal monitoring) ──"
if [ -d "$SKILLS_DIR/nv-monitor" ]; then
  echo "   Updating existing installation..."
  cp "$REPO_DIR/nv-monitor/monitor.js" "$SKILLS_DIR/nv-monitor/monitor.js"
  cp "$REPO_DIR/nv-monitor/SKILL.md" "$SKILLS_DIR/nv-monitor/SKILL.md"
  cp "$REPO_DIR/nv-monitor/package.json" "$SKILLS_DIR/nv-monitor/package.json"
else
  cp -r "$REPO_DIR/nv-monitor" "$SKILLS_DIR/nv-monitor"
fi
cd "$SKILLS_DIR/nv-monitor" && npm install --silent 2>/dev/null
echo "   ✓ nv-monitor installed"

# Install nv-controller
echo "── Installing nv-controller (position management) ──"
if [ -d "$SKILLS_DIR/nv-controller" ]; then
  echo "   Updating existing installation..."
  cp "$REPO_DIR/nv-controller/controller.js" "$SKILLS_DIR/nv-controller/controller.js"
  cp "$REPO_DIR/nv-controller/SKILL.md" "$SKILLS_DIR/nv-controller/SKILL.md"
  cp "$REPO_DIR/nv-controller/package.json" "$SKILLS_DIR/nv-controller/package.json"
else
  cp -r "$REPO_DIR/nv-controller" "$SKILLS_DIR/nv-controller"
fi
cd "$SKILLS_DIR/nv-controller" && npm install --silent 2>/dev/null
echo "   ✓ nv-controller installed"

echo ""
echo "═══════════════════════════════════════════"
echo "  ✓ Installation complete!"
echo "═══════════════════════════════════════════"
echo ""
echo "Next steps:"
echo ""
echo "  1. Restart OpenClaw to load the new skills"
echo ""
echo "  2. In OpenClaw chat, say:"
echo "     'Set me up for trading'"
echo ""
echo "     The agent will:"
echo "     • Check/create your subscription"
echo "     • Build a portfolio (3 coins)"
echo "     • Open signal packs"
echo "     • Assemble strategies"
echo "     • Start paper trading"
echo ""
echo "  3. Or if you have a referral code:"
echo "     'Redeem referral code XXXX and set me up'"
echo ""
echo "Docs: https://arena.nvprotocol.com"
echo ""
