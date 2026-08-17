# Drayven Mobile

Open-source 2D capture-the-flag shooter for **Godot 4.6.2**.

## Core game

- 300 generated campaign stages across 12 story sectors (25 missions per sector).
- Main loop: survive the enemy wave → hold position to capture every required flag → unlock the command chest → collect its reward → unlock the next stage.
- Boss mission every 25 stages.
- Four operatives: Vex, Iris, Brakk, Nyx; each has a distinct ability.
- Five weapons: Pulse Pistol, Arc SMG, Scattergun, Rail Rifle, Nova Launcher.
- Rare / Epic / Legendary reward chest tiers, persistent shards, unlocks, per-stage score and global best score.
- Persian UI using Vazirmatn, native RTL layout, and a large `بازی` Play button.
- Real touch UI: left virtual movement control plus textured fire, ability, reload and weapon controls. Right-side direct touch/drag aiming is also supported.
- Custom splash and PNG application icon; default Godot branding is not used as the project splash.
- Tamper-evident SHA-256 save wrapper plus range validation. This detects casual save edits; it is not represented as unbreakable client-side DRM.

## Real third-party assets

Gameplay graphics are not procedurally drawn. The player walk/shoot sheet, enemy PNGs, flag, projectile, reward chest, backgrounds, application icon, textured buttons, touch controls, music, SFX and Persian font are downloaded from their original open-license sources and committed into `assets/vendor/` by CI. See `ASSET_SOURCES.md`, `THIRD_PARTY_NOTICES.md`, and `licenses/`.

## Android only

The active export preset and GitHub Actions workflow build Android ARM64 only. CI uses Godot 4.6.2 and verifies the APK with `apksigner`.

For production signing set:

- `DRAYVEN_ANDROID_KEYSTORE_B64`
- `DRAYVEN_ANDROID_KEY_ALIAS`
- `DRAYVEN_ANDROID_KEY_PASSWORD`

If they are absent, CI creates an ephemeral testing keystore, so the APK is still signed and installable for testing but does not have a stable production identity.

After a successful build the workflow publishes a stable GitHub Release asset at:

`https://github.com/DeathAmir/Drayven/releases/download/mobile-latest/Drayven.apk`
