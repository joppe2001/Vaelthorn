# Start Here

Your prep checklist before we kick off Phase 0. Total time: ~30 minutes.

---

## Must do (before next session)

### 1. Install Godot 4.3 LTS — 5 min

Download from https://godotengine.org/download/macos/

- Pick **Standard** (not the .NET / Mono version — we're using GDScript).
- Drag `Godot.app` to `/Applications`.
- Open it once so macOS approves it (right-click → Open if Gatekeeper complains).
- Close it after the project manager appears — **don't create a project**.
  I'll scaffold it for you in our next session.

### 2. Verify Git is installed — 2 min

In Terminal:

```bash
git --version
```

If it errors, install Homebrew + git:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git
```

You probably already have it since you're using Claude Code.

### 3. Create a private GitHub repo — 5 min

- Go to https://github.com/new
- Name it `pixel-arena` (or your final project name).
- Set it **Private**.
- **Skip** "Initialize with README" — we have our own.
- Copy the SSH URL: `git@github.com:youruser/pixel-arena.git`

Save the URL. You'll paste it to me at the start of the next session.

---

## Should do (before next session)

### 4. Skim the design docs — 15 min

This is your last chance to push back on design decisions cheaply. Once we
start coding, changes get expensive.

Priority reading order:

1. [01 — Vision](docs/01-vision.md) — am I excited about *this* game?
2. [02 — Combat](docs/02-combat.md) — does the damage formula and ATB feel right?
3. [03 — Heroes](docs/03-heroes.md) — is the hybrid rarity ladder what you want?
4. [08 — Roadmap](docs/08-roadmap.md) — are the phase priorities right? Is v1.0 at Phase 8 acceptable?
5. [11 — Engineering](docs/11-engineering.md) — the principles I'll hold us to.

**Flag anything you disagree with.** We update the doc, *then* start. Examples
of things worth flagging:

- The 6 elements (Fire/Water/Earth/Wind/Light/Dark) — fine, or change?
- The 6 classes (Attacker/Defender/Healer/Buffer/Debuffer/Ranger) — fine?
- The `DEF * 0.5` damage constant — feel concern?
- The hybrid rarity (Common → Mythic × 1–5★) — confirmed?
- Co-op raids before guild raids? — currently guild first, co-op last.
- v1.0 single-player launch on itch.io as the first milestone — agree?

Don't worry about every detail. We can tune numbers later. Lock in the *shape*.

### 5. Pick your project name (or keep placeholder)

`pixel-arena` is a placeholder. If you already have a real name, tell me — I'll
rename the folder, update all docs, and use it for the GitHub repo.

If you don't have one yet, we ship Phase 0 as `pixel-arena` and rename
anytime. Names can change up until v1.0 marketing starts.

---

## Defer (do when needed)

### Aseprite

You don't need Aseprite until Phase 2 when sprite tweaks start. Buy it then:
https://www.aseprite.org/ ($20 one-time).

### Pre-commit hooks

I'll install + configure these in Phase 0. You don't need to do anything.

### Node.js / Docker

Not needed until Phase 9 (server). Forget about it for now.

---

## When you're ready to start the next session

Paste this in chat:

```
Godot:        installed
GitHub repo:  <paste SSH URL here>
Design docs:  [shipped as written | I have feedback on X, Y]
Project name: [pixel-arena | something else]
```

I'll then immediately start Phase 0:

- Scaffold the full folder structure ([07 — Tech](docs/07-tech.md) project layout).
- Create `project.godot` with pixel-perfect rendering settings.
- Set up `.gitignore`, autoload stubs (Game, EventBus, ContentRegistry,
  SaveManager, SoundManager, Telemetry), and the pre-commit config.
- Write Title + Hub scenes that wire into the autoloads.
- Initialize git, make a first commit, push to your GitHub repo.

You'll open Godot to a real project running on day one — not a blank canvas.

---

## What we will NOT do in Phase 0

To set expectations clearly:

- **No combat code yet.** That's Phase 1.
- **No hero data yet.** That's Phase 3.
- **No art beyond a placeholder background.** Real art starts when you pick
  asset packs.
- **No server.** That's Phase 9.

Phase 0 is *foundation*. Boring and load-bearing.

---

## If you get stuck before next session

- **Godot won't open** ("damaged" or "unidentified developer" on macOS): right-click
  the app → Open. macOS will let you bypass once.
- **`git` not found**: install Homebrew first, then `brew install git`.
- **GitHub SSH key not set up**: run `ssh-keygen -t ed25519 -C "your@email"`,
  then paste the contents of `~/.ssh/id_ed25519.pub` into
  https://github.com/settings/keys.
- **Anything else**: ask me, save the screenshot, we sort it together.

See you on the other side.
