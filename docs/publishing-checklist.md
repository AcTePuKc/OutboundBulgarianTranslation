# Publishing Checklist

## Repository Positioning

Publish this repository as two related parts:

- Outbound Bulgarian Translation Mod: the player-facing BepInEx package for Outbound.
- Unity IL2CPP translation hook toolkit: the source workflow for games with Outbound-like `TranslationManager`, `Language`, and `Translate` classes.

Do not present it as a universal Unity translator or a general Outbound content-modding framework.

## Before Pushing To GitHub

- Keep the MIT `LICENSE` file and `NOTICE.md` attribution note.
- Confirm `git status` does not include `Dump/`, `Raw/`, `data/assetripper-export*`, `data/analysis/`, `build/`, `dist/`, or `tools/`.
- Do not commit generated files containing original game text.
- Do commit `src/OutboundTranslationMod/translations/labels.txt`, because it is the original Bulgarian translation.
- Do commit `release/` templates and `docs/`.

## Nexus Package

Build:

```powershell
.\scripts\build-plugin.ps1
```

Package:

```powershell
.\scripts\package-release.ps1 -Version 0.1.0
```

Upload the generated archive from:

```text
dist/OutboundTranslationMod-0.1.0.zip
```

The archive should contain:

- `BepInEx/plugins/OutboundTranslationMod/OutboundTranslationMod.dll`
- `BepInEx/plugins/OutboundTranslationMod/translations/labels.txt`
- `BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg`
- `README.txt`
- `LICENSE.txt`
- `NOTICE.md`

## Release Config

Normal release config:

```ini
DumpTranslations = false
EnableTranslationOverrides = true
LabelsFileName = labels.txt
TargetLanguageName = Ukrainian
OverrideAllLanguages = false
AssumeTargetLanguageOnStartup = true
```

Make `AssumeTargetLanguageOnStartup = true` visible in player-facing instructions. It is a plugin config value stored in `BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg`, not a core BepInEx setting.

The plugin can create a config automatically on first run, but BepInEx preserves existing values. The release archive includes the intended config so fresh installs get the correct Outbound values immediately. If a user has an old config, ask them to overwrite it or delete it.

Keep `DumpTranslations = false` for public builds. Ask testers to enable it only when reporting missing text.

## Nexus Description Notes

Mention:

- Requires BepInEx Unity IL2CPP x64 6.0.0 be.755 or newer.
- Install BepInEx first, run the game once, then extract the mod archive into the game folder.
- Select Ukrainian in-game; this mod replaces the Ukrainian language slot with Bulgarian.
- Steam build was tested.
- Microsoft Store / Xbox app builds may require extra BepInEx patching steps and are not guaranteed by this package.
- Compass/radar `N/E/S/W` is not part of the localization table and is not translated by this mod.
- The mod is MIT licensed; attribution is appreciated when using this project as a base.
