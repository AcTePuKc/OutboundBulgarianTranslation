# Unity IL2CPP Translation Workflow

This repository started as an Outbound Bulgarian translation mod, but the workflow is intentionally reusable for other Unity IL2CPP games that use a central translation manager.

The important rule: do not redistribute original game files, extracted assets, AssetRipper exports, or localization dumps from commercial games. Share only the plugin source, scripts, documentation, and your own translation file.

## Tools Used

- BepInEx Unity IL2CPP: loads the runtime plugin inside the game.
- AssetRipper: exports the Unity project structure so localization assets and reconstructed scripts can be inspected.
- PowerShell: parses extracted translation data and compares it with the current translation file.
- Roslyn `csc` or `dotnet build`: builds the BepInEx plugin.

UABEA was useful for early manual inspection, but the repeatable workflow uses AssetRipper and scripts.

## Game Setup

1. Install the IL2CPP BepInEx build into the game folder.
2. Start the game once so BepInEx generates `BepInEx/core`, `BepInEx/interop`, `BepInEx/plugins`, and config folders.
3. Confirm that `BepInEx/interop/Assembly-CSharp.dll` exists. The plugin build references this generated interop assembly.

For Outbound, the tested BepInEx package was `BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.755+3fab71a`.

## Extracting Translation Keys

AssetRipper should be pointed at the game folder, not a single asset file. For Outbound, exporting the full Unity project revealed the real localization table:

`ExportedProject/Assets/4 __Import txt/retrieved translations.txt`

Run:

```powershell
.\scripts\extract-assetripper-translations.ps1
```

This creates local helper files under `data/translation`:

- `labels-from-assetripper.txt`: all extracted `key=English text` pairs.
- `missing-from-bg.txt`: keys present in the game but missing from the current translation.
- `assetripper-translations.tsv`: extracted keys with English text and optional context.

These generated files are ignored by git because they may contain original game text.

### Outbound Patch Update Fast Path

For Outbound, the localization keys were not scattered across thousands of separate UI assets. The useful table was the single AssetRipper text export:

`data/assetripper-export-unity-project/ExportedProject/Assets/4 __Import txt/retrieved translations.txt`

For a future Outbound patch, try this order before doing another full investigative pass:

1. Export the game folder with AssetRipper again into a fresh local `data/assetripper-export-unity-project` folder.
2. Check whether `ExportedProject/Assets/4 __Import txt/retrieved translations.txt` still exists.
3. Run `.\scripts\extract-assetripper-translations.ps1`.
4. Review `data/translation/missing-from-labels.txt` for newly added keys.

If AssetRipper keeps the same path, this avoids searching the whole export manually again. A full scan is only needed if the file disappears, changes format, or the game starts showing untranslated runtime text that is not present in the table.

If the same table can be exported from a smaller source later, prefer that. For the first public version, the reliable method was full game-folder export because single-asset exports from `resources.assets` / `sharedassets0.assets` did not clearly expose the final localization table.

## Translation File

New projects should use:

`src/OutboundTranslationMod/translations/labels.txt`

Format:

```text
translation-key=Translated text
```

Keep placeholders and markup intact:

- `{0}`, `{1}`, etc.
- `<b>`, `<color=...>`, `</color>`, `</b>`
- escaped `\n` line breaks

Write escaped line breaks directly in the value without wrapping the whole label in quotes:

```text
tr-example=First paragraph.\n\nSecond paragraph.
```

The plugin still falls back to `labels-bg.txt` for the original Outbound Bulgarian project.

## Language Slot

Most games do not have a Bulgarian language enum value. The plugin therefore replaces one existing language slot. For Outbound we use `Ukrainian`, because it already exercises a Cyrillic-capable UI path.

The target slot is configured in the generated BepInEx config:

```ini
[General]
EnableTranslationOverrides = true
LabelsFileName = labels.txt
TargetLanguageName = Ukrainian
OverrideAllLanguages = false
AssumeTargetLanguageOnStartup = true
```

For another game, `TargetLanguageName` must match a value from that game's `Language` enum. AssetRipper's reconstructed scripts often reveal the enum names, and BepInEx logs can help confirm what `SetLanguage` receives.

`AssumeTargetLanguageOnStartup` is important when replacing an existing language slot. Some games initialize visible menu text before they report the saved language through `SetLanguage`. If this is `false`, the plugin may still think the current language is English during the first UI pass and leave the main menu in the original slot language until the player switches languages manually. For Outbound, setting this to `true` fixed the startup case where the menu stayed Ukrainian until Ukrainian was reselected.

Keep `OverrideAllLanguages = false` for normal releases. It is useful only for diagnostics because it replaces text even when the player selects another language.

## Build Configuration

The project imports local machine settings from `User.targets` if present. Copy the example:

```powershell
Copy-Item .\User.targets.example .\User.targets
```

Then edit `User.targets`:

```xml
<Project>
  <PropertyGroup>
    <BepInExGameDir>C:\Path\To\Game</BepInExGameDir>
  </PropertyGroup>
</Project>
```

`BepInExGameDir` must point to the folder that contains `BepInEx`.

## Runtime Discovery

The plugin patches:

- `TranslationManager.SetLanguage`
- `TranslationManager.Translate`
- `Translate.UpdateText`

It also writes discovered runtime keys to:

`BepInEx/plugins/OutboundTranslationMod/dumps/translation-dump.txt`

Runtime dumps are useful when a key is generated dynamically or missing from the extracted table. They should be treated as local working data, not redistributed.

For public releases, keep runtime dumping disabled:

```ini
DumpTranslations = false
```

Enable it only for development builds or bug reports. If a tester reports untranslated text, ask them to enable dumping temporarily, reproduce the issue, then share only the relevant lines needed for diagnosis.

## Startup Translation Timing

The stable fix for Outbound is configuration, not brute force:

```ini
EnableTranslationOverrides = true
TargetLanguageName = Ukrainian
AssumeTargetLanguageOnStartup = true
```

Avoid repeated global refresh loops such as scanning every `Translate` component for several seconds after startup. In IL2CPP games this can fight scene teardown, language switching, or UI destruction and may cause delayed shutdowns or noisy BepInEx logs.

If startup text remains untranslated, check the BepInEx log for the order of events:

1. Plugin loaded.
2. Translation entries loaded.
3. First `Translate.UpdateText` dumps.
4. First `SetLanguage => ...`.

If `Translate.UpdateText` happens before `SetLanguage`, enable `AssumeTargetLanguageOnStartup`. If it still fails, the next safer direction is to add narrow hooks to the text framework actually used by the game, such as TextMeshPro `TMP_Text.text` or component `OnEnable`, rather than broad repeated refreshes.

## Porting To Another Unity IL2CPP Game

The current plugin assumes the game has Outbound-like types:

- `Language`
- `TranslationManager`
- `Translate`
- `Translate.translationKey`
- `Translate.UpdateText()`

For a different game, these names may differ. The extraction scripts can still be useful, but the Harmony patches may need small game-specific edits.

Recommended porting order:

1. Install BepInEx IL2CPP and run the game once.
2. Export the game folder with AssetRipper.
3. Locate localization classes/assets in the export.
4. Set `BepInExGameDir` in `User.targets`.
5. Adjust Harmony patch type and member names if the game does not match Outbound.
6. Create `translations/labels.txt`.
7. Enable runtime dumping first, then enable overrides after confirming keys.
8. If replacing an existing language slot, set `AssumeTargetLanguageOnStartup = true` and keep `OverrideAllLanguages = false`.

## What To Share

Safe to share:

- Plugin source code.
- PowerShell extraction/comparison scripts.
- Build configuration templates.
- Documentation.
- Your own `labels.txt` translation.

Do not share:

- AssetRipper exports.
- UABEA dumps.
- Raw `.assets`, `.dat`, `.bytes`, `.bundle`, or game DLL files.
- Generated files containing original localization text, unless the game license explicitly allows it.
