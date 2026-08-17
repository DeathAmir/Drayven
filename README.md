# Drayven: Neon Requiem

A complete source-first 2D top-down story shooter built for **Godot 4.6.2**.

## Game

Noxara loses power in eleven seconds. Four operatives discover that the city's Drayven Core is not a reactor but a prison. Fight through four campaign chapters, recover fragments, unlock operatives and weapons, and confront the Core Titan.

### Playable operatives

- **Vex** — Phase Dash: short invulnerable dash through danger.
- **Iris** — Aegis Pulse: temporary high-damage-reduction shield.
- **Brakk** — Overdrive: movement and fire-rate burst.
- **Nyx** — Void Blink: teleport to aim point and damage nearby enemies.

### Weapons

Pulse Pistol, Arc SMG, Scattergun, Rail Rifle, and Nova Launcher. Weapons have distinct damage, spread, magazine, reload, projectile speed, recoil, and explosive behavior.

### Modes

- **Story** — four chapters, progressive waves, unlock rewards and final boss.
- **Neon Arena** — endless escalating survival with persistent best score.

### Systems

Persistent save, shards, unlocks, character roster, weapon cycling, reloads, elite enemies, boss combat, health drops, reward drops, procedural soundtrack, keyboard/mouse controls, and touch controls.

## Controls

Desktop: `WASD` move, mouse aim, left click fire, `Q` ability, `R` reload, `Z/X` weapon cycle.

Mobile: drag on the left side to move, hold/drag on the right to aim and fire, and use the on-screen Weapon / Reload / Ability buttons.

## Run

Open the repository folder in Godot 4.6.2 and run the project.

## Automated builds

`.github/workflows/build.yml` downloads the official Godot 4.6.2 editor and matching export templates, validates the project, and exports Windows x64, Linux x86_64, and Android arm64 APK artifacts.

### Android signing

For stable release signing, set `DRAYVEN_ANDROID_KEYSTORE_B64`, `DRAYVEN_ANDROID_KEY_ALIAS`, and `DRAYVEN_ANDROID_KEY_PASSWORD`. Without them CI generates an ephemeral signed testing keystore.

### Windows signing

For a trusted signature, set `DRAYVEN_WINDOWS_PFX_B64` and `DRAYVEN_WINDOWS_PFX_PASSWORD`. Without them CI uses a self-signed code-signing certificate.

## Licensing

Project code and original committed assets are MIT licensed. See `LICENSE` and `THIRD_PARTY_NOTICES.md`.
