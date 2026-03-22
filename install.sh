#!/bin/bash
# NVProtocol Trading System — Installer
# Installs nv-brain, nv-monitor, nv-controller into OpenClaw skills directory
# Does NOT modify any security/elevated settings — only checks and guides the user

set -e

echo "═══════════════════════════════════════════"
echo "  NVProtocol Trading System v1.0"
echo "═══════════════════════════════════════════"
echo ""

# ====================== PERMISSION CHECK ======================
echo "🔍 Checking OpenClaw permissions..."

if ! command -v openclaw &>/dev/null; then
  echo "⚠️  openclaw not found in PATH — skipping permission check"
else
  PERMISSION_OK=true

  if ! openclaw config get tools.profile 2>/dev/null | grep -q "full"; then
    echo "⚠️  tools.profile is not set to 'full'"
    PERMISSION_OK=false
  fi

  if ! openclaw config get tools.elevated.allowFrom.webchat 2>/dev/null | grep -q "true"; then
    echo "⚠️  Elevated access for webchat is not enabled"
    PERMISSION_OK=false
  fi

  if [ "$PERMISSION_OK" = false ]; then
    echo ""
    echo "❌ Insufficient permissions detected."
    echo ""
    echo "Please run these commands in your terminal and then restart OpenClaw:"
    echo ""
    echo "   openclaw config set tools.profile full --json"
    echo "   openclaw config set tools.elevated.enabled true --json"
    echo "   openclaw config set tools.elevated.allowFrom.webchat true --json"
    echo "   openclaw gateway restart"
    echo ""
    echo "After restarting OpenClaw, run this installer again."
    echo ""
    exit 1
  fi

  echo "✅ Permissions look good (full profile + elevated webchat access)."
fi

echo ""

# ====================== INSTALLATION ======================

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

# Install the three skills
for skill in nv-brain nv-monitor nv-controller; do
  echo "── Installing $skill ──"

  if [ -d "$SKILLS_DIR/$skill" ]; then
    echo "   Updating existing installation..."
    cp "$REPO_DIR/$skill"/*.js "$SKILLS_DIR/$skill/" 2>/dev/null || true
    cp "$REPO_DIR/$skill"/SKILL.md "$SKILLS_DIR/$skill/" 2>/dev/null || true
    cp "$REPO_DIR/$skill"/package.json "$SKILLS_DIR/$skill/" 2>/dev/null || true
  else
    cp -r "$REPO_DIR/$skill" "$SKILLS_DIR/$skill"
  fi

  (cd "$SKILLS_DIR/$skill" && npm install --silent 2>/dev/null) || echo "   ⚠  npm install had warnings (non-critical)"
  echo "   ✓ $skill installed"
done

echo ""
echo "═══════════════════════════════════════════"
echo "  ✓ Installation complete!"
echo "═══════════════════════════════════════════"
echo ""
echo "Next steps:"
echo ""
echo "  1. Restart OpenClaw completely"
echo ""
echo "  2. In the OpenClaw chat, say:"
echo "     'Set me up for trading'"
echo ""
echo "     (or with referral: 'Redeem referral code XXXX and set me up for trading')"
echo ""