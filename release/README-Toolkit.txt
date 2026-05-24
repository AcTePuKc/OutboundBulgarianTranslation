Outbound Translation Hook Toolkit
=================================

This repository can also be used as a starting point for translation mods for Unity IL2CPP games that use an Outbound-like localization flow.

What this is:

- A BepInEx 6 IL2CPP Harmony hook for replacing translation keys from a plain labels.txt file.
- A workflow for extracting translation keys with AssetRipper.
- Scripts for comparing extracted keys with the current translation file.
- Documentation for replacing an existing language slot, such as Ukrainian, when the game has no Bulgarian language enum.

What this is not:

- A general-purpose Outbound content modding framework.
- A replacement for OutboundModLib.
- A universal Unity translator. Other games may use different TranslationManager, Language, or UI component names and may require code changes.

Do not redistribute:

- AssetRipper exports.
- UABEA dumps.
- Game DLLs, assets, bundles, or original localization dumps.

Safe to redistribute:

- Plugin source code.
- Scripts.
- Documentation.
- Your own translated labels.txt.
