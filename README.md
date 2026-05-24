# Outbound Bulgarian Translation Mod

Bulgarian UI/text translation mod for `Outbound`, built as a BepInEx 6 IL2CPP plugin.

The player-facing release replaces the game's Ukrainian language slot with Bulgarian and loads text from a plain `translations/labels.txt` file. The repository also includes source code and workflow notes that can be reused as a small Unity IL2CPP translation hook toolkit.

## For Players

1. Install BepInEx Unity IL2CPP x64 6.0.0 be.755 or newer into the Outbound game folder.
2. Start the game once and close it so BepInEx can generate its folders and interop assemblies.
3. Extract the mod archive into the Outbound game folder.
4. Start the game and select `Ukrainian` in the language menu. After the mod loads, that slot is shown as Bulgarian.

Expected paths after installation:

- `Outbound/BepInEx/plugins/OutboundTranslationMod/OutboundTranslationMod.dll`
- `Outbound/BepInEx/plugins/OutboundTranslationMod/translations/labels.txt`
- `Outbound/BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg`

## Required Mod Config

This is the plugin's own BepInEx config file, not a core BepInEx setting:

`BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg`

The release archive includes the correct config for normal play:

```ini
[General]
DumpTranslations = false
EnableTranslationOverrides = true
LabelsFileName = labels.txt
TargetLanguageName = Ukrainian
OverrideAllLanguages = false
AssumeTargetLanguageOnStartup = true
```

`AssumeTargetLanguageOnStartup = true` is important for Outbound. The game can draw the first main menu texts before it reports the saved Ukrainian language slot to the plugin. Without this setting, the startup menu may remain Ukrainian until the player switches language away and back.

If you already ran an older version of the mod, BepInEx may keep your old config values. In that case, replace the config with the one from the release archive or delete the old config and run the game again.

`DumpTranslations = false` is the release setting. Enable it only when debugging missing or hardcoded text, because it writes discovered game text into a local dump file.

## Current Status

- All extracted Outbound localization keys are covered by `labels.txt`.
- The Steam IL2CPP build is the tested target.
- New translation releases use `translations/labels.txt`; `labels-bg.txt` is only a legacy fallback.
- Compass/radar `N/E/S/W` markings are not part of the localization table and are not translated by this mod.
- Microsoft Store / Xbox app builds may need extra BepInEx setup and are not guaranteed by this package.

## Project Layout

- `src/OutboundTranslationMod`: BepInEx IL2CPP plugin source.
- `src/OutboundTranslationMod/translations/labels.txt`: active Bulgarian translation file.
- `release/`: Nexus-style readme and release config.
- `scripts/`: build, package, and translation helper scripts.
- `docs/unity-il2cpp-translation-workflow.md`: reusable workflow notes for similar Unity IL2CPP games.
- `User.targets.example`: local build configuration template for game-specific paths.

In `labels.txt`, escaped line breaks such as `\n\n` are supported directly in values without wrapping the whole label in quotes.

## Build From Source

Create a local `User.targets` file:

```xml
<Project>
  <PropertyGroup>
    <BepInExGameDir>C:\Program Files (x86)\Steam\steamapps\common\Outbound</BepInExGameDir>
  </PropertyGroup>
</Project>
```

`User.targets` is ignored by git so every contributor can use a different Steam library path.

Build the plugin:

```powershell
.\scripts\build-plugin.ps1
```

If your NuGet environment is configured normally, you can also try:

```powershell
.\scripts\build-plugin.ps1 -Method dotnet
```

To create a Nexus-style archive after building:

```powershell
.\scripts\package-release.ps1
```

The archive is written under `dist/` and includes only the plugin DLL, `labels.txt`, release config, player readme, license, and attribution notice.

GitHub Actions validates the translation files and release metadata, but does not build the DLL. A public CI build would need local BepInEx interop/game assemblies from an installed copy of Outbound, which should not be committed or redistributed.

## Sharing Rules

Safe to share:

- Plugin source code.
- Scripts.
- Documentation.
- Build templates.
- Your own translated `labels.txt`.

Do not share:

- AssetRipper exports.
- UABEA dumps.
- Original game assets or generated files containing original localization text.

## License

Code, scripts, docs, and the Bulgarian translation are released under the MIT License. If you use this project as a base for another translation mod, please keep the copyright/license notice and credit the original project as described in `NOTICE.md`.

## Important Note

Do not copy a BepInEx folder from a Mono Unity game into an IL2CPP Unity game. `Outbound` needs an IL2CPP-compatible BepInEx setup.
