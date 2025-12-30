#!/bin/bash
# =============================================================================
# PSX Toolchain Download Script
# =============================================================================
# Downloads the PSX compiler and related tools needed for decompilation.
#
# Tools downloaded:
#   - cc1-psx-26: PSY-Q GCC 2.6 based C compiler
#   - (Optional) wibo: Windows binary runner for Linux
#
# NOTE: These tools are provided for educational/preservation purposes.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_DIR/bin"

mkdir -p "$BIN_DIR"

echo "==================================="
echo "PSX Toolchain Download"
echo "==================================="
echo ""

# -----------------------------------------------------------------------------
# cc1-psx-26 - PSY-Q C Compiler
# -----------------------------------------------------------------------------
# This is a Linux-native build of the PSY-Q GCC 2.6 compiler
# Source: https://github.com/decompals/old-gcc

CC1_URL="https://github.com/decompals/old-gcc/releases/download/release/cc1-psx-26"
CC1_PATH="$BIN_DIR/cc1-psx-26"

if [ -f "$CC1_PATH" ]; then
    echo "✓ cc1-psx-26 already exists"
else
    echo "Downloading cc1-psx-26..."
    curl -L "$CC1_URL" -o "$CC1_PATH"
    chmod +x "$CC1_PATH"
    echo "✓ cc1-psx-26 downloaded"
fi

# Verify it works
if "$CC1_PATH" --version 2>/dev/null | grep -q "gcc"; then
    echo "✓ cc1-psx-26 verified working"
else
    echo "⚠ cc1-psx-26 may not be working correctly"
fi

# -----------------------------------------------------------------------------
# wibo - Windows Binary Runner (optional)
# -----------------------------------------------------------------------------
# Only needed if you need to run Windows-only tools (like mwccpsp for PSP)
# Source: https://github.com/decompals/wibo

# TODO: Uncomment if PSP support is needed
# WIBO_URL="https://github.com/decompals/wibo/releases/download/0.6.13/wibo"
# WIBO_PATH="$BIN_DIR/wibo"
#
# if [ -f "$WIBO_PATH" ]; then
#     echo "✓ wibo already exists"
# else
#     echo "Downloading wibo..."
#     curl -L "$WIBO_URL" -o "$WIBO_PATH"
#     chmod +x "$WIBO_PATH"
#     echo "✓ wibo downloaded"
# fi

echo ""
echo "==================================="
echo "Toolchain setup complete!"
echo "==================================="
echo ""
echo "Tools installed in: $BIN_DIR"
echo ""
echo "Next steps:"
echo "  1. Place your game binary in disks/"
echo "  2. Configure config/splat.us.yaml"
echo "  3. Run: nix develop"
echo "  4. Run: make extract"
echo ""

# -----------------------------------------------------------------------------
# TODO: Additional tools that may be needed
# -----------------------------------------------------------------------------
# 
# dosemu2 - For running DOS-based PSY-Q tools
#   Not packaged for Nix. Use Docker or Ubuntu packages from:
#   https://github.com/sozud/dosemu-deb
#
# PSP tools (allegrex-as, mwccpsp) - For PSP version support
#   Would need separate download/packaging
#
# Saturn tools (sh-elf binutils) - For Saturn version support
#   Available in Nix as pkgsCross.sh4-linux-gnu
