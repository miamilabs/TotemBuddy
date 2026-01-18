# TotemBuddy

A Shaman totem management addon for World of Warcraft: Wrath of the Lich King Classic.

## Requirements

- **World of Warcraft: Wrath of the Lich King Classic** (Interface 11503 / 3.4.x)
- **Ace3 Library** (REQUIRED) - Must be installed for the addon to function

### Installing Ace3

Ace3 can be installed in two ways:

1. **Standalone Download**: Download Ace3 from [CurseForge](https://www.curseforge.com/wow/addons/ace3) and extract to your `Interface/AddOns` folder
2. **Addon Manager**: Most addon managers (CurseForge, WowUp, etc.) will automatically install Ace3 as a dependency

If Ace3 is not installed, TotemBuddy will display an error message at login and will not load.

## Installation

1. Download TotemBuddy
2. Ensure Ace3 is installed (see above)
3. Extract TotemBuddy to `World of Warcraft/_classic_/Interface/AddOns/`
4. Restart WoW or type `/reload` in-game

## Features

### Core Features
- **Totem Bar**: Quick-access tiles for all 4 totem elements (Fire, Earth, Water, Air)
- **Totem Selection**: Right-click any tile to choose from all known totems of that element
- **Drag & Drop**: Unlock the bar to reposition anywhere on screen
- **Flexible Layouts**: Horizontal, vertical, or 2x2 grid arrangement

### Totem Sets (v2.0)
- **Save Sets**: Save your current totem configuration as a named set
- **Quick Switch**: Instantly switch between saved totem configurations
- **Keybindings**: Bind keys to cycle through sets or activate specific sets

### Modifier Keys
- Configure different totems for Shift+Click, Ctrl+Click, Alt+Click
- Customize per-element modifier overrides

### Additional Tracking
- **Weapon Imbues**: Track Windfury, Flametongue, and other weapon enchants
- **Shield Tracking**: Monitor Earth Shield, Lightning Shield, Water Shield
- **Call of the Elements**: Quick access to multi-totem casting (if learned)

## Slash Commands

### General Commands
| Command | Description |
|---------|-------------|
| `/tb` or `/totembuddy` | Open options panel |
| `/tb toggle` | Toggle bar visibility |
| `/tb lock` | Toggle frame lock (enable/disable dragging) |
| `/tb reset` | Reset bar position to default |
| `/tb scan` | Rescan spellbook for totems |
| `/tb show` | Force show the bar |
| `/tb debug` | Display debug information |

### Totem Set Commands
| Command | Description |
|---------|-------------|
| `/tb set <name>` | Activate a saved set by name |
| `/tb sets` | List all saved sets |
| `/tb nextset` | Cycle to next set |
| `/tb prevset` | Cycle to previous set |
| `/tb saveset <name>` | Save current totems as a new set |
| `/tb delset <name>` | Delete a saved set |

## Keybindings

Keybindings can be configured in **ESC > Key Bindings > TotemBuddy**:

- **Cast Element 1-4**: Cast the default totem for Fire/Earth/Water/Air
- **Select Element 1-4**: Open the totem selector for an element
- **Next Set / Previous Set**: Cycle through saved totem sets
- **Activate Set 1-5**: Directly activate a set by its position

> **Note**: Keybind casting is not available during combat due to WoW API restrictions. Click tiles directly during combat.

## Configuration

Access the options panel via:
- `/tb` command
- **ESC > Interface > AddOns > TotemBuddy**

### Options Tabs

1. **General**: Enable/disable addon, tooltips, combat behavior
2. **Layout**: Bar orientation, scale, anchor position
3. **Totems**: Default totem selection per element
4. **Modifiers**: Configure Shift/Ctrl/Alt click overrides

## Troubleshooting

### "TotemBuddy Error: Ace3 library is required"
Ace3 is not installed. Download it from CurseForge and place in your AddOns folder.

### "TotemBuddy Error: Missing Ace3 libraries"
Ace3 is partially installed. Reinstall Ace3 completely.

### Bar not showing
1. Check if the addon is enabled in the character selection screen
2. Try `/tb show` to force the bar visible
3. Try `/tb reset` to reset position
4. Check `/tb debug` for diagnostic info

### Totems not appearing in selector
Use `/tb scan` to rescan your spellbook for known totems.

## Support

For issues, bugs, or feature requests, please visit the addon's repository or CurseForge page.

## Version History

- **v2.0.0**: Added totem sets, keybindings, modifier overrides, weapon imbue tracking
- **v1.0.0**: Initial release with basic totem bar functionality

## License

This addon is provided as-is for personal use.
