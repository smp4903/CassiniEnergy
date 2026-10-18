# CassiniEnergy

This is an addon for **World of Warcraft Classic** (Classic Era, TBC, and WOTLK clients).

The purpose of this addon is to track the **energy regeneration tick** cadence. In
Classic-era WoW, Energy regenerates in discrete ticks (a chunk of energy roughly
every 2 seconds) rather than continuously. CassiniEnergy shows a small progress bar
that fills toward the next predicted tick, so you can time abilities around it.

The addon is enabled for classes that use Energy — **Rogues** (always) and **Druids**
(while in Cat Form). For any other class it disables itself.

The tick-tracking mechanic is the same one used by the FiveSecondRule addon: energy
regen ticks are silent (they never show up in the combat log), while every other
energy gain (Tiger's Fury, Thistle Tea, Relentless Strikes, combat potency, etc.)
arrives as a combat-log energize event. Those explained gains are subtracted from
the per-frame power delta; whatever remains is a real regen tick, and it re-anchors
the 2-second clock to the server's actual cadence.

### Slash commands

- `/ce` or `/cassinienergy` — open the options panel
- `/ce unlock` (`/ce u`) — unlock the bar for moving/resizing
- `/ce lock` (`/ce l`) — lock the bar
- `/ce reset` — reset all settings
- `/ce enable` / `/ce disable` — toggle the addon
- `/ce debug` — toggle debug logging

### Notes

- Energy tick tracking works identically across Classic Era, TBC, and WOTLK clients.
- Saved settings are stored per character in `CassiniEnergy_Options`.

### Development

`tests/run.sh` loads the addon against a stubbed WoW API and checks the tick detection (energy changes against the combat log's energize events), the full-energy and energy-pool checks, and the Player frame placement. It needs `lua5.1`. Pass a folder to test a release build instead: `tests/run.sh dist/CassiniEnergy-v1-0-0/CassiniEnergy`.

### Release

`python3 tools/build_release.py` writes `dist/CassiniEnergy-v<version>.zip`, with the version from the TOC and dots as dashes (`1.0.0` becomes `1-0-0`), plus the same files unzipped in `dist/CassiniEnergy-v<version>/`. The zip holds a single `CassiniEnergy/` folder with the TOCs and the files they list; `Media/`, `tests/`, `tools/` and this README stay out.

