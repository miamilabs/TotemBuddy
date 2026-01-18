# TotemTimers_Fork → TotemBuddy Feature Review for TBC

**Review Date**: 2026-01-17
**Status**: Planning Phase
**TotemTimers_Fork**: 9,738 lines | **TotemBuddy**: ~7,950 lines

---

## Implementation Checklist

### Phase 1: High-Impact Features

- [ ] **1. Long Cooldown Tracker** (NEW MODULE)
  - [ ] Create `Modules/UI/CooldownTracker.lua`
  - [ ] Track Fire Elemental / Earth Elemental
  - [ ] Track Mana Tide Totem
  - [ ] Track Bloodlust / Heroism
  - [ ] Track Nature's Swiftness
  - [ ] Track Elemental Mastery
  - [ ] Add cooldown spiral + text overlay
  - [ ] Add configurable warning threshold
  - [ ] Add options panel integration

- [ ] **2. Weapon Enchant Enhancement** (ENHANCE EXISTING)
  - [ ] Add WeaponEnchants ID mapping table to `Data/ShamanExtras.lua`
  - [ ] Enhance `ImbueTile.lua` to identify active enchant type
  - [ ] Add dual-spell combo support for dual wield (WF+FT)
  - [ ] Add combat glow warning when enchant expiring
  - [ ] Track max observed duration per enchant type

- [ ] **3. Earth Shield Intelligence** (ENHANCE EXISTING)
  - [ ] Add COMBAT_LOG_EVENT_UNFILTERED handler to `ShieldTile.lua`
  - [ ] Add target GUID tracking for Earth Shield
  - [ ] Add charge count display
  - [ ] Add main tank roster detection
  - [ ] Add quick-cast buttons for tanks (optional)

### Phase 2: Enhancement Spec Features

- [ ] **4. Flame Shock Target Tracking**
  - [ ] Create target debuff monitoring via CLEU
  - [ ] Display Flame Shock duration on current target
  - [ ] Handle target switching

- [ ] **5. Stormstrike Debuff Tracking**
  - [ ] Track Stormstrike debuff duration on target
  - [ ] Visual indicator when debuff active

- [ ] **6. Proc Indicator System**
  - [ ] Add overlay glow for Clearcasting
  - [ ] Add overlay glow for other procs
  - [ ] Use `ActionButton_ShowOverlayGlow` API

### Phase 3: Quality of Life

- [ ] **7. Crowd Control Tracking**
  - [ ] Create `Modules/UI/CCTracker.lua`
  - [ ] Track Hex duration on target
  - [ ] Track Bind Elemental duration
  - [ ] Detect CC breaks via CLEU

- [ ] **8. Warning Message System**
  - [ ] Add LibSink dependency (optional)
  - [ ] Configurable output (screen/chat/sound)
  - [ ] Per-ability warning settings

- [ ] **9. Masque Support**
  - [ ] Add Masque library integration
  - [ ] Apply skinning to all tile buttons

- [ ] **10. Additional Localizations**
  - [ ] French (frFR)
  - [ ] Spanish (esES, esMX)
  - [ ] Russian (ruRU)
  - [ ] Chinese (zhCN, zhTW)
  - [ ] Korean (koKR)

---

## Detailed Feature Analysis

### 1. Long Cooldown Tracker (Missing Entirely)

**Impact**: Critical for all Shaman specs

TotemBuddy has **no tracking** for major cooldowns. TotemTimers tracks:
- Fire Elemental / Earth Elemental
- Mana Tide Totem
- Bloodlust / Heroism
- Nature's Swiftness
- Elemental Mastery

**TotemTimers Implementation** (`TotemTimers.lua:200-300`):
- Dedicated timer buttons per cooldown
- Cooldown spiral + text overlay
- Warning at configurable threshold
- Bar timer option

**Recommendation**: Create new `CooldownTracker.lua` module with configurable cooldown list.

---

### 2. Enhanced Weapon Enchant Tracking

**Source**: `Weapon.lua` (262 lines)
**Impact**: Essential for Enhancement Shamans

| Feature | TotemTimers | TotemBuddy |
|---------|-------------|------------|
| Enchant ID → Spell mapping | ✅ 18 types | ❌ None |
| Dual weapon separate timers | ✅ | ⚠️ Basic |
| Double-spell combos (WF+FT) | ✅ | ❌ |
| Combat glow warning | ✅ | ❌ |
| Max duration memory | ✅ | ❌ |

**Key Code Pattern** (`Weapon.lua:196-250`):
```lua
local WeaponEnchants = TotemTimers.WeaponEnchants -- Maps enchant IDs to spell IDs
local enchant, expiration, _, mainID = GetWeaponEnchantInfo()
if WeaponEnchants[mainID] then
    texture = SpellTextures[WeaponEnchants[mainID]]
end
```

**Recommendation**: Add `WeaponEnchants` mapping table and enhance `ImbueTile.lua:280-350`.

---

### 3. Earth Shield Intelligence System

**Source**: `EarthShield.lua` (356 lines)
**Impact**: Critical for Restoration Shamans

TotemBuddy's `ShieldTile.lua` only checks `UNIT_AURA` on player. TotemTimers has:

- **COMBAT_LOG_EVENT_UNFILTERED parsing** for real-time refresh detection
- **Target/Focus tracking** via GUID matching
- **Main tank roster integration** (auto-detects tanks in raid)
- **Charge count + duration display**
- **Quick-cast buttons** for tanks (TTActionBars with 4 slots)

**Key Pattern** (`EarthShield.lua:234-270`):
```lua
for i = 1, 40 do
    local name, _, count, _, duration, endtime, source = UnitBuff(unit, i)
    if name == EarthShieldSpellName and source == "player" then
        -- Track charges and duration on ANY unit
    end
end
```

---

### 4. Enhancement CDs Module

**Source**: `EnhanceCDs.lua` (815 lines)

Features for Enhancement spec:
- **Flame Shock duration tracking** on target via CLEU
- **Stormstrike debuff tracking** on target
- **Proc indicators** with pulse animations (Clearcasting, etc.)
- **Overlay glow** system using `ActionButton_ShowOverlayGlow`

---

### 5. Crowd Control Tracking

**Source**: `CrowdControl.lua` (100 lines)

Tracks Hex and Bind Elemental with:
- CLEU-based duration tracking on specific target GUID
- Target/Focus dual-targeting (left-click vs right-click)
- Break detection (`SPELL_AURA_BROKEN` events)

---

### 6. XiTimers Engine

**Source**: `XiTimers.lua` (1,077 lines)

Advanced timer features:
- Configurable update intervals
- Warning points with flash animations
- Out-of-combat alpha fading
- Mana check integration (icon color when OOM)

**Note**: Full adoption would require significant refactoring. Consider selective feature adoption.

---

## Code Quality Issues in TotemTimers_Fork

**These must be fixed before porting any code:**

| Severity | File | Line | Issue |
|----------|------|------|-------|
| CRITICAL | `EnhanceCDs.lua` | 27 | Uses `null` instead of `nil` |
| CRITICAL | `XiTimers.lua` | 541-558 | `StartMoving`/`StopMoving` infinite recursion |
| HIGH | `EnhanceCDs.lua` | 260-266 | Duplicate `SetAttribute("spell2")` |
| HIGH | `Range.lua` | 1 | UTF-8 BOM character |

---

## TotemBuddy Strengths to Preserve

- Clean module loader pattern (`TotemBuddyLoader`)
- Modern Lua documentation/type hints
- Combat-safe attribute handling (`ApplyAttributesSafely`)
- Good separation of concerns

---

## Reference Files

### TotemTimers_Fork Key Files:
- `/Users/paul/private/wow/TotemTimers_Fork/XiTimers.lua` - Timer engine
- `/Users/paul/private/wow/TotemTimers_Fork/Weapon.lua` - Weapon enchant tracking
- `/Users/paul/private/wow/TotemTimers_Fork/EarthShield.lua` - Earth Shield intelligence
- `/Users/paul/private/wow/TotemTimers_Fork/EnhanceCDs.lua` - Enhancement cooldowns
- `/Users/paul/private/wow/TotemTimers_Fork/CrowdControl.lua` - CC tracking
- `/Users/paul/private/wow/TotemTimers_Fork/Spells.lua` - Spell database

### TotemBuddy Files to Enhance:
- `/Users/paul/private/wow/TotemBuddy/Modules/UI/ImbueTile.lua`
- `/Users/paul/private/wow/TotemBuddy/Modules/UI/ShieldTile.lua`
- `/Users/paul/private/wow/TotemBuddy/Data/ShamanExtras.lua`

---

## Progress Log

| Date | Change | Status |
|------|--------|--------|
| 2026-01-17 | Initial review completed | ✅ |
| | | |
