--[[
    TotemBuddy Localization - German (Germany)
    Deutsch (Deutschland)
]]

-- Only load for German clients
if GetLocale() ~= "deDE" then return end

-- Defensive check: ensure base locale table exists (handles load order edge cases)
if not TotemBuddy_L then
    TotemBuddy_L = setmetatable({}, { __index = function(t, k) return k end })
end
local L = TotemBuddy_L

-- General
L["General"] = "Allgemein"
L["TotemBuddy"] = "TotemBuddy"
L["Enable TotemBuddy"] = "TotemBuddy aktivieren"
L["Show or hide the totem bar"] = "Totemleiste ein- oder ausblenden"
L["Lock Position"] = "Position sperren"
L["Prevent the totem bar from being moved"] = "Verhindert das Verschieben der Totemleiste"
L["Show Tooltips"] = "Tooltips anzeigen"
L["Show spell tooltips when hovering over totem tiles"] = "Zeige Zauber-Tooltips beim Überfahren der Totemkacheln"

-- Display Options
L["Display Options"] = "Anzeigeoptionen"
L["Show Cooldowns"] = "Abklingzeiten anzeigen"
L["Display cooldown swipe on totem tiles"] = "Zeige Abklingzeit-Animation auf Totemkacheln"
L["Show Keybinds"] = "Tastenbelegung anzeigen"
L["Display keybind text on totem tiles"] = "Zeige Tastenbelegung auf Totemkacheln"
L["Show Element Indicator"] = "Elementanzeige anzeigen"
L["Display colored bar indicating totem element"] = "Zeige farbigen Balken zur Elementanzeige"

-- Timer Options
L["Timer Options"] = "Timer-Optionen"
L["Show Cooldown Numbers"] = "Abklingzeit-Zahlen anzeigen"
L["Display countdown numbers when a totem is on cooldown"] = "Zeige Countdown-Zahlen während der Abklingzeit"
L["Show Active Duration"] = "Aktive Dauer anzeigen"
L["Display remaining time for active totems"] = "Zeige verbleibende Zeit für aktive Totems"
L["Show Active Glow"] = "Aktiv-Leuchten anzeigen"
L["Display a glow effect when a totem is active"] = "Zeige Leuchteffekt wenn ein Totem aktiv ist"
L["Show Duration Bar"] = "Dauerbalken anzeigen"
L["Display a progress bar showing remaining totem duration"] = "Zeige Fortschrittsbalken für verbleibende Totemdauer"
L["Duration Bar Height"] = "Höhe des Dauerbalkens"
L["Height of the duration progress bar in pixels"] = "Höhe des Dauer-Fortschrittsbalkens in Pixeln"
L["Expiring Warning Threshold"] = "Ablauf-Warnschwelle"
L["Seconds remaining before totem is considered 'expiring soon' (triggers color change and pulse)"] = "Verbleibende Sekunden bevor Totem als 'läuft bald ab' gilt (löst Farbwechsel und Pulsieren aus)"
L["Expiring Warning Color"] = "Ablauf-Warnfarbe"
L["Color for duration text and bar when totem is about to expire"] = "Farbe für Dauertext und -balken wenn Totem bald abläuft"

-- Selector Options
L["Selector Options"] = "Auswahl-Optionen"
L["Show Selector in Combat"] = "Auswahl im Kampf anzeigen"
L["Allow the totem selector popup to appear while in combat (note: you cannot change totems during combat)"] = "Erlaube das Totem-Auswahlmenü im Kampf (Hinweis: Totems können im Kampf nicht gewechselt werden)"
L["Lock Selector"] = "Auswahl sperren"
L["When enabled, the totem selector only opens when holding Shift while hovering or right-clicking"] = "Wenn aktiviert, öffnet sich die Totemauswahl nur mit gedrückter Umschalttaste"
L["Right-Click Opens Selector"] = "Rechtsklick öffnet Auswahl"
L["When Lock Selector is enabled, right-clicking still opens the selector menu"] = "Wenn Auswahl sperren aktiviert ist, öffnet Rechtsklick trotzdem das Auswahlmenü"
L["Tip: Right-click a totem tile to quickly open the selector."] = "Tipp: Rechtsklick auf eine Totemkachel öffnet schnell die Auswahl."
L["Selector Behavior"] = "Auswahlverhalten"
L["Cast on Select"] = "Bei Auswahl wirken"
L["When selecting a totem from the popup, immediately cast it in addition to setting it as the default. Only works out of combat."] = "Beim Auswählen eines Totems aus dem Menü wird es sofort gewirkt. Funktioniert nur außerhalb des Kampfes."

-- Actions
L["Actions"] = "Aktionen"
L["Reset Position"] = "Position zurücksetzen"
L["Reset the totem bar to the center of the screen"] = "Totemleiste zur Bildschirmmitte zurücksetzen"
L["Rescan Totems"] = "Totems neu scannen"
L["Rescan your spellbook for known totems"] = "Zauberbuch nach bekannten Totems durchsuchen"

-- Layout
L["Layout"] = "Ansicht"
L["Bar Layout"] = "Leistenansicht"
L["Choose how totem tiles are arranged"] = "Wähle die Anordnung der Totemkacheln"
L["Horizontal"] = "Horizontal"
L["Vertical"] = "Vertikal"
L["2x2 Grid"] = "2x2 Raster"
L["Size"] = "Größe"
L["Scale"] = "Skalierung"
L["Overall scale of the totem bar"] = "Gesamtskalierung der Totemleiste"
L["Tile Size"] = "Kachelgröße"
L["Size of individual totem tiles"] = "Größe einzelner Totemkacheln"
L["Tile Spacing"] = "Kachelabstand"
L["Space between totem tiles"] = "Abstand zwischen Totemkacheln"
L["Appearance"] = "Aussehen"
L["Show Border"] = "Rahmen anzeigen"
L["Show a border around the totem bar"] = "Zeige Rahmen um die Totemleiste"
L["Background Color"] = "Hintergrundfarbe"
L["Background color of the totem bar"] = "Hintergrundfarbe der Totemleiste"
L["Selector Popup"] = "Auswahlmenü"
L["Selector Position"] = "Auswahlposition"
L["Where the totem selection popup appears"] = "Position des Totem-Auswahlmenüs"
L["Above"] = "Oberhalb"
L["Below"] = "Unterhalb"
L["Left"] = "Links"
L["Right"] = "Rechts"
L["Selector Columns"] = "Auswahl-Spalten"
L["Number of columns in the totem selector popup"] = "Anzahl der Spalten im Totem-Auswahlmenü"
L["Selector Scale"] = "Auswahl-Skalierung"
L["Scale of the totem selector popup"] = "Skalierung des Totem-Auswahlmenüs"

-- Totems Tab
L["Totems"] = "Totems"
L["Use Highest Rank"] = "Höchsten Rang verwenden"
L["Always cast the highest rank of each totem you know. When disabled, you can choose specific ranks."] = "Wirke immer den höchsten Rang jedes bekannten Totems. Wenn deaktiviert, kannst du bestimmte Ränge wählen."
L["When 'Use Highest Rank' is disabled, you can select specific ranks for each totem in the hover selection popup."] = "Wenn 'Höchsten Rang verwenden' deaktiviert ist, kannst du bestimmte Ränge für jedes Totem im Auswahlmenü wählen."
L["Show Unavailable Totems"] = "Nicht verfügbare Totems anzeigen"
L["Show totems you haven't learned yet in the selector (grayed out)"] = "Zeige noch nicht erlernte Totems in der Auswahl (ausgegraut)"
L["Default Totems"] = "Standard-Totems"
L["Choose the default totem for each element. These will be displayed on the totem bar."] = "Wähle das Standard-Totem für jedes Element. Diese werden auf der Totemleiste angezeigt."
L["Earth Totem"] = "Erdtotem"
L["Fire Totem"] = "Feuertotem"
L["Water Totem"] = "Wassertotem"
L["Air Totem"] = "Lufttotem"
L["First Available"] = "Erstes Verfügbare"
L["Totem"] = "Totem"
L["Default %s totem to display"] = "Standard-%s-Totem zur Anzeige"

-- Elements
L["Earth"] = "Erde"
L["Fire"] = "Feuer"
L["Water"] = "Wasser"
L["Air"] = "Luft"

-- Modifiers Tab
L["Modifiers"] = "Modifikatoren"
L["Configure modifier key overrides for each element. When holding Shift, Ctrl, or Alt while clicking a totem tile, it will cast the configured override totem instead of the default.\n\nThis uses secure macros built when out of combat, so modifiers work during combat."] = "Konfiguriere Modifikatortasten-Überschreibungen für jedes Element. Wenn du Umschalt, Strg oder Alt beim Klicken auf eine Totemkachel gedrückt hältst, wird das konfigurierte Ersatz-Totem gewirkt.\n\nDies verwendet sichere Makros die außerhalb des Kampfes erstellt werden, sodass Modifikatoren im Kampf funktionieren."
L["Fire Totems"] = "Feuer-Totems"
L["Earth Totems"] = "Erd-Totems"
L["Water Totems"] = "Wasser-Totems"
L["Air Totems"] = "Luft-Totems"
L["Shift"] = "Umschalt"
L["Ctrl"] = "Strg"
L["Alt"] = "Alt"
L["+Click"] = "+Klick"
L["Totem to cast when %s+clicking the %s tile"] = "Totem das beim %s+Klick auf die %s-Kachel gewirkt wird"
L["Clear All Modifiers"] = "Alle Modifikatoren löschen"
L["Remove all modifier override assignments"] = "Alle Modifikator-Überschreibungen entfernen"
L["Clear all modifier overrides?"] = "Alle Modifikator-Überschreibungen löschen?"
L["Modifier overrides cleared. Macro updates will apply after combat ends."] = "Modifikator-Überschreibungen gelöscht. Makro-Aktualisierungen werden nach dem Kampf angewendet."
L["All modifier overrides cleared."] = "Alle Modifikator-Überschreibungen gelöscht."
L["None (disabled)"] = "Keine (deaktiviert)"
L["Cannot update macros in combat. Changes will apply after combat ends."] = "Makros können im Kampf nicht aktualisiert werden. Änderungen werden nach dem Kampf angewendet."

-- Earth Shield Targeting
L["Earth Shield Targeting"] = "Erdschild-Zielauswahl"
L["Configure which target Earth Shield casts on when holding modifier keys. Changes apply after leaving combat."] = "Konfiguriere auf welches Ziel Erdschild wirkt wenn Modifikatortasten gedrückt werden. Änderungen werden nach dem Kampf angewendet."
L["No Modifier (Default)"] = "Kein Modifikator (Standard)"
L["Shift+Click"] = "Umschalt+Klick"
L["Ctrl+Click"] = "Strg+Klick"
L["Alt+Click"] = "Alt+Klick"
L["Target for Earth Shield when %s is used"] = "Ziel für Erdschild wenn %s verwendet wird"
L["Disabled"] = "Deaktiviert"
L["Self"] = "Selbst"
L["Focus"] = "Fokus"
L["Party"] = "Gruppe"
L["Party 1"] = "Gruppe 1"
L["Party 2"] = "Gruppe 2"
L["Party 3"] = "Gruppe 3"
L["Party 4"] = "Gruppe 4"
L["Party 5"] = "Gruppe 5"
L["Click"] = "Klick"

-- Profiles
L["Profiles"] = "Profile"

-- Messages
L["Locked"] = "gesperrt"
L["Unlocked"] = "entsperrt"
L["Position Reset"] = "Position zurückgesetzt"
L["Scan Complete"] = "Scan abgeschlossen"
L["Totem scan complete"] = "Totem-Scan abgeschlossen"
L["%s is now your default."] = "%s ist jetzt dein Standard."
L["Cannot open selector during combat."] = "Auswahl kann im Kampf nicht geöffnet werden."
L["%s will be set as default when leaving combat."] = "%s wird nach dem Kampf als Standard gesetzt."
L["Options panel not available in this client."] = "Optionen-Fenster ist in diesem Client nicht verfügbar."
L["Failed to cast %s: %s"] = "Konnte %s nicht wirken: %s"

-- Tooltip hints
L["Cooldown: %s"] = "Abklingzeit: %s"
L["Click to queue as default (after combat)"] = "Klicken um als Standard vorzumerken (nach Kampf)"
L["Click to set as default and cast"] = "Klicken um als Standard zu setzen und zu wirken"
L["Click to set as default"] = "Klicken um als Standard zu setzen"
L["Not yet learned"] = "Noch nicht erlernt"
L["Requires level %d"] = "Benötigt Stufe %d"
L["Visit a trainer to learn"] = "Besuche einen Lehrer zum Erlernen"

-- Extra Features Section
L["Extra Features"] = "Zusatzfunktionen"
L["Show Call of Totems"] = "Ruf der Totems anzeigen"
L["Show Call of Elements, Call of the Ancestors, and Call of the Spirits buttons"] = "Zeige Schaltflächen für Ruf der Elemente, Ruf der Ahnen und Ruf der Geister"
L["Show Weapon Imbues"] = "Waffenverzauberungen anzeigen"
L["Show weapon imbue tiles for mainhand and offhand"] = "Zeige Waffenverzauberungs-Kacheln für Haupt- und Nebenhand"
L["Show Shields"] = "Schilde anzeigen"
L["Show shield tile for Lightning Shield, Water Shield, and Earth Shield"] = "Zeige Schild-Kachel für Blitzschlagschild, Wasserschild und Erdschild"
L["Changes will apply after combat."] = "Änderungen werden nach dem Kampf angewendet."

-- Imbue/Shield Status
L["Active"] = "Aktiv"
L["Not active"] = "Nicht aktiv"
L["charges"] = "Aufladungen"
L["Active: %s remaining"] = "Aktiv: %s verbleibend"
L["Mainhand"] = "Haupthand"
L["Offhand"] = "Nebenhand"
L["Applies to: %s"] = "Wird angewandt auf: %s"
L["Right-click to select imbue"] = "Rechtsklick um Verzauberung auszuwählen"
L["Right-click to select shield"] = "Rechtsklick um Schild auszuwählen"
L["Click to set for %s"] = "Klicken um für %s zu setzen"
L["Can be cast on friendly targets"] = "Kann auf freundliche Ziele gewirkt werden"
L["Casts on mouseover target or self"] = "Wirkt auf Mouseover-Ziel oder sich selbst"

-- Selector Tooltips
L["Click to set as default"] = "Klicken um als Standard zu setzen"
L["%s will be set as default when leaving combat."] = "%s wird nach dem Kampf als Standard gesetzt."
L["Cannot open selector during combat."] = "Auswahl kann im Kampf nicht geöffnet werden."

-- GeneralTab Extra Features
L["Display button(s) for Call of the Elements/Ancestors/Spirits spells"] = "Zeige Schaltfläche(n) für Ruf der Elemente/Ahnen/Geister Zauber"
L["Display buttons for weapon enchantments (Rockbiter, Flametongue, Windfury, etc.)"] = "Zeige Schaltflächen für Waffenverzauberungen (Felsbeiszer, Flammenzunge, Windzorn, etc.)"
L["Display button for Lightning Shield, Water Shield, or Earth Shield"] = "Zeige Schaltfläche für Blitzschlagschild, Wasserschild oder Erdschild"
L["Note: Features are disabled if no spells are known. Use 'Rescan Totems' after learning new spells."] = "Hinweis: Funktionen sind deaktiviert wenn keine Zauber bekannt sind. Verwende 'Totems neu scannen' nach dem Erlernen neuer Zauber."
L["Rescan your spellbook for known totems, imbues, shields, and call spells"] = "Zauberbuch nach bekannten Totems, Verzauberungen, Schilden und Ruf-Zaubern durchsuchen"

-- Keybinding Localization (global variables required by WoW API)
BINDING_HEADER_TOTEMBUDDY = "TotemBuddy"

-- Cast Element Totems
BINDING_NAME_TOTEMBUDDY_CAST_FIRE = "Feuertotem wirken"
BINDING_NAME_TOTEMBUDDY_CAST_EARTH = "Erdtotem wirken"
BINDING_NAME_TOTEMBUDDY_CAST_WATER = "Wassertotem wirken"
BINDING_NAME_TOTEMBUDDY_CAST_AIR = "Lufttotem wirken"

-- Open Element Selectors
BINDING_NAME_TOTEMBUDDY_SELECT_FIRE = "Feuertotem auswählen"
BINDING_NAME_TOTEMBUDDY_SELECT_EARTH = "Erdtotem auswählen"
BINDING_NAME_TOTEMBUDDY_SELECT_WATER = "Wassertotem auswählen"
BINDING_NAME_TOTEMBUDDY_SELECT_AIR = "Lufttotem auswählen"

-- Set Cycling
BINDING_NAME_TOTEMBUDDY_NEXT_SET = "Nächstes Totem-Set"
BINDING_NAME_TOTEMBUDDY_PREV_SET = "Vorheriges Totem-Set"

-- Direct Set Access
BINDING_NAME_TOTEMBUDDY_SET_1 = "Set 1 aktivieren"
BINDING_NAME_TOTEMBUDDY_SET_2 = "Set 2 aktivieren"
BINDING_NAME_TOTEMBUDDY_SET_3 = "Set 3 aktivieren"
BINDING_NAME_TOTEMBUDDY_SET_4 = "Set 4 aktivieren"
BINDING_NAME_TOTEMBUDDY_SET_5 = "Set 5 aktivieren"
