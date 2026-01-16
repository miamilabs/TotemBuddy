#!/bin/bash

#===============================================================================
# TotemBuddy Deployment Script
# Deploys the addon to WoW Anniversary Edition AddOns folder
#===============================================================================

# Configuration
ADDON_NAME="TotemBuddy"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BASE="/Volumes/StudioData/Applications/World of Warcraft/_anniversary_/Interface/AddOns"
TARGET_DIR="${TARGET_BASE}/${ADDON_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo " TotemBuddy Deployment Script"
echo "========================================"
echo ""

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory not found: $SOURCE_DIR${NC}"
    exit 1
fi

# Check if target base directory exists
if [ ! -d "$TARGET_BASE" ]; then
    echo -e "${RED}Error: WoW AddOns directory not found: $TARGET_BASE${NC}"
    echo "Please ensure the WoW installation is accessible."
    exit 1
fi

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Creating addon directory: $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
fi

echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Files and directories to copy
FILES_TO_COPY=(
    "TotemBuddy.toc"
    "TotemBuddy-Classic.toc"
    "TotemBuddy-BCC.toc"
    "TotemBuddy-WOTLKC.toc"
    "TotemBuddy.lua"
    "embeds.xml"
)

DIRS_TO_COPY=(
    "Modules"
    "Data"
    "Localization"
    "Libs"
)

# Copy individual files
echo "Copying files..."
for file in "${FILES_TO_COPY[@]}"; do
    if [ -f "$SOURCE_DIR/$file" ]; then
        cp "$SOURCE_DIR/$file" "$TARGET_DIR/"
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${YELLOW}⚠${NC} $file (not found, skipping)"
    fi
done

# Copy directories
echo ""
echo "Copying directories..."
for dir in "${DIRS_TO_COPY[@]}"; do
    if [ -d "$SOURCE_DIR/$dir" ]; then
        # Remove existing directory to ensure clean copy
        rm -rf "$TARGET_DIR/$dir"
        cp -r "$SOURCE_DIR/$dir" "$TARGET_DIR/"
        echo -e "  ${GREEN}✓${NC} $dir/"
    else
        echo -e "  ${YELLOW}⚠${NC} $dir/ (not found, skipping)"
    fi
done

echo ""
echo "========================================"
echo -e "${GREEN}Deployment complete!${NC}"
echo "========================================"
echo ""

# Check for Libs directory warning
if [ ! -d "$TARGET_DIR/Libs" ] || [ -z "$(ls -A "$TARGET_DIR/Libs" 2>/dev/null)" ]; then
    echo -e "${YELLOW}Warning: Libs directory is empty or missing.${NC}"
    echo "You need to add the Ace3 libraries to Libs/ folder:"
    echo "  - LibStub"
    echo "  - CallbackHandler-1.0"
    echo "  - AceAddon-3.0"
    echo "  - AceEvent-3.0"
    echo "  - AceDB-3.0"
    echo "  - AceDBOptions-3.0"
    echo "  - AceConsole-3.0"
    echo "  - AceGUI-3.0"
    echo "  - AceConfig-3.0"
    echo "  - AceConfigCmd-3.0"
    echo "  - AceConfigDialog-3.0"
    echo "  - AceConfigRegistry-3.0"
    echo ""
    echo "Download from: https://www.curseforge.com/wow/addons/ace3"
    echo ""
fi

# Count files deployed
TOTAL_FILES=$(find "$TARGET_DIR" -type f | wc -l | tr -d ' ')
echo "Total files deployed: $TOTAL_FILES"
echo ""
echo "To use TotemBuddy:"
echo "  1. Launch WoW Anniversary Edition"
echo "  2. Log in with a Shaman character"
echo "  3. Type /tb to open settings"
echo ""
