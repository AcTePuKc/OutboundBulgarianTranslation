Outbound Bulgarian Translation
==============================

This mod adds a Bulgarian UI/text translation for Outbound through BepInEx 6 IL2CPP.

Install
-------

1. Install BepInEx Unity IL2CPP x64 6.0.0 be.755 or newer into the Outbound game folder.
2. Start the game once and close it so BepInEx can generate its folders and interop assemblies.
3. Extract this archive into the Outbound game folder.
4. Start the game and select Ukrainian in the language menu. The mod replaces the Ukrainian language slot with Bulgarian.

Expected paths after installation:

- Outbound/BepInEx/plugins/OutboundTranslationMod/OutboundTranslationMod.dll
- Outbound/BepInEx/plugins/OutboundTranslationMod/translations/labels.txt
- Outbound/BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg

Recommended Config
------------------

The archive includes this plugin config for normal play:

Outbound/BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg

- DumpTranslations = false
- EnableTranslationOverrides = true
- LabelsFileName = labels.txt
- TargetLanguageName = Ukrainian
- OverrideAllLanguages = false
- AssumeTargetLanguageOnStartup = true

Important: AssumeTargetLanguageOnStartup = true is required for Outbound's startup menu when replacing Ukrainian. Without it, the first menu may remain Ukrainian until the language is switched away and back.

If you already ran an older version of the mod, BepInEx may keep your old config values. Replace the config with the one from this archive or delete the old config and run the game again.

Notes
-----

- The compass/radar N/E/S/W markings are not part of the game's localization table and are not translated by this mod.
- Some collectible names may come from game asset names rather than translation keys.
- Runtime dumping is disabled in the release package because all extracted translation keys are currently covered. Enable DumpTranslations only if you want to report newly discovered missing text.

Credits
-------

Bulgarian translation: AcTePuKc / Щерян Николаев
Localization hook/tooling: AcTePuKc
License: MIT
