# Research Notes

## Confirmed So Far

- Game path:
  - `C:\Program Files (x86)\Steam\steamapps\common\Outbound`
- Main runtime:
  - `GameAssembly.dll`
  - `Outbound_Data\il2cpp_data\Metadata\global-metadata.dat`
- Candidate text assets:
  - `Outbound_Data\sharedassets0.assets`
  - `Outbound_Data\resources.assets`
- Addressables are present under:
  - `Outbound_Data\StreamingAssets\aa`

## Useful Findings

- `sharedassets0.assets` contains visible UI strings such as:
  - `Continue`
  - `Settings`
  - `Reset`
  - `Rebind`
- It also contains language keys such as:
  - `tr-language-german`
  - `tr-language-polish`
  - `tr-language-ukrainian`
- It references methods / classes that strongly suggest runtime language refresh paths:
  - `SettingsUI, Assembly-CSharp`
  - `OnApplyLanguage`
  - `MenuItemUI, Assembly-CSharp`
  - `MapUI, Assembly-CSharp`
- Runtime dump through the BepInEx plugin produced 1022 unique translation keys.
- `TranslationManager.Translate(string, bool, Language)` is the safest replacement point for keyed strings.
- `Translate.UpdateText()` is useful for UI labels that refresh after the manager call, but it should only run in the chosen Bulgarian carrier language to avoid noisy global overrides.

## Current Runtime Approach

- Use `labels-bg.txt` as the external replacement table.
- Treat `Language.Ukrainian` as the Bulgarian carrier slot.
- Keep `OverrideAllLanguages` disabled for normal testing.
- Select Ukrainian in the game's language menu to activate Bulgarian replacements.

## Asset Layout Hypothesis

`Outbound` stores a mix of:

- visible UI text in serialized assets / prefabs,
- language identifiers in asset data,
- and language handling logic in IL2CPP metadata / generated code.

## Next Reverse-Engineering Steps

1. Expand `labels-bg.txt` from the generated key list.
2. Identify the language menu label key for Ukrainian and rename it to Bulgarian if possible.
3. Test a longer gameplay session with Ukrainian selected and watch `BepInEx\LogOutput.log`.
4. Reduce or disable runtime dumping once the translation key list is stable.
