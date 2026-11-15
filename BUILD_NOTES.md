# Crystal Rush — build notes

## The game
**Crystal Rush** is an original 3D arena coin-collector for Roblox, built for the
make.fun bounty `roblox-game-01` ("Make the best Roblox game", $250, closes
2026-11-15T18:00:00Z = 23:30 IST).

- A colourful arena built entirely from code by the server script: grass
  baseplate with a sandy ring, blue border walls, four raised platforms (orange,
  blue, purple, yellow) with ramps, a central crystal tower with a glowing cyan
  crystal, trees and rocks around the edge.
- Gameplay: gold coins (1 point) spawn around the arena, up to 24 at a time; a
  golden crystal worth 10 points appears every 30 seconds and vanishes after
  15 seconds if nobody grabs it. Rounds last 120 seconds with a 10-second lobby
  before each round. Score, coins collected and best round show in the HUD and
  in Roblox's own leaderboard (leaderstats: Points, Best).
- Client: a start screen with the title and a PLAY button, a HUD (timer
  top-centre, score top-right, clear of Roblox's top-left menu buttons), a
  round-end screen naming the winner and your score, and a gold sparkle flash
  in the 3D world wherever a coin is collected.
- No external assets, no network calls, no plugins. All scripts are original,
  written for this entry; only `vendor/makefun-roblox.ts` is the kit's file,
  copied byte-for-byte and unchanged.

## What is done
- `src/server/init.server.luau` (487 lines) — arena, coins, scoring, round loop.
- `src/client/Game.client.luau` — start screen, HUD, round-end screen, sparkles.
- `default.project.json` — Rojo project "crystal-rush".
- `game.rbxl` — built headlessly with Rojo 7.7.1 (`rojo build
  default.project.json --output game.rbxl`); a real binary Roblox place,
  11,604 bytes.
- `main.ts` + `vendor/makefun-roblox.ts` — the kit's dossier builder, unchanged.
- `README.md` — the level-11 make.fun template (three live badges, bounty link,
  referral code 95gaw808), `LICENSE` (MIT).
- `PLAY.json` — still the starter's placeholder (`place_id: 0`, `universe_id: 0`).
  It MUST be filled in with the real published ids before submission (see below).

## Validation done (all on this machine, no Studio)
- Both Luau scripts compile clean with the Luau 0.747 compiler
  (`luau-compile` exit 0 for each; `luau-analyze` reports only "unknown global"
  warnings for Roblox globals like `Instance` and `game`, which is expected
  without Roblox type definitions).
- Rojo build exits 0 and produces a valid binary place (`<roblox!` magic,
  proper INST/PROP/PRNT chunks).
- Dossier smoke test: `main.ts` was run with `MAKEFUN_OUTPUT_DIR` against a
  throwaway copy of the repo plus one solid-colour test image in /tmp only.
  It built `dossier.json` successfully: 10 place instances, 2 scripts,
  21,375 bytes of source, **100.0% of script bytes matched to src/** (2 of 2
  scripts, 2 of 2 src/ files) — above the gate's 80% bar. The test image was
  never put in the repo.
- The game has NOT been play-tested in Studio (no Studio on this machine).
  The first real playtest happens on the user's laptop — see below.

## What is NOT done (needs the user's laptop + Roblox Studio)
1. **Screenshots (3 or 4) — none exist yet.** `screenshots/` in this repo is
   empty on purpose. No screenshot has been fabricated or staged anywhere.
2. **Publishing** — the experience is not published and not Public yet.
3. **PLAY.json** — still placeholder zeros; fill in after publishing.

## How the user finishes it (Roblox Studio on their own laptop)
Prerequisite: a Roblox account signed in to Studio that can already publish
(at least 2 days old, age check passed — an account made after the bounty
opened cannot publish before it closes).

1. Open `game.rbxl` in Roblox Studio. Press Play and check the game runs:
   the start screen shows, PLAY reveals the HUD, coins spin, the timer counts
   down from 2:00, collecting a coin adds a point and flashes gold.
2. Publish: File → Publish to Roblox As → create a new experience named
   "Crystal Rush". On the Creator Dashboard give it a description and a genre,
   answer the content questions, then set it **Public**.
3. Fill in `PLAY.json`: `place_id` is the number in the play link
   (`https://www.roblox.com/games/<place_id>`), `universe_id` is the number
   after `experiences/` in the Creator Dashboard address (or `game.GameId`
   in Studio). The place must be the experience's start place.
4. Take 3–4 screenshots while the game is running in Studio (the game pauses
   if Studio loses focus, so capture from inside Studio):
   - `1-start.png` — the start screen with the CRYSTAL RUSH title.
   - `2-play.png` — mid-game: coins visible, HUD timer and score showing.
   - `3-crystal.png` — the golden crystal moment (a golden crystal on screen).
   - `4-end.png` — the round-end screen with the winner.
   Each must be a PNG or JPEG, at most 256 KiB, long side at most 1280 px,
   short side at least 480 px. A Studio capture is often larger than 256 KiB,
   so re-encode as JPEG or scale it down until it fits. Keep HUD text clear
   of the top-left corner (Roblox's own menu buttons sit there).
   Put them in `screenshots/` (the first by name is the cover).
5. Tell the agent the screenshots and the PLAY.json ids are in — it rebuilds
   `game.rbxl` if anything changed, re-runs the dossier check, and submits.

## Repo About (for the parent when creating the GitHub repo)
- Description: `Crystal Rush: a bright 3D arena coin-collector for Roblox — collect coins, chase the golden crystal, beat the clock. Built by an AI agent for make.fun's "Make the best Roblox game" bounty, $250 in USDC.`
- Homepage: `https://make.fun/bounty/roblox-game-01`
- Topics: `makefun`, `ai-agents`, `bounties`, `games`
