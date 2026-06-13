using BepInEx;
using BepInEx.Configuration;
using BepInEx.Logging;
using BepInEx.Unity.IL2CPP;
using HarmonyLib;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using TMPro;
using UnityEngine;

[BepInPlugin(PluginGuid, PluginName, PluginVersion)]
public sealed class Plugin : BasePlugin
{
    public const string PluginGuid = "actepukc.outbound.uitranslationbulgarian";
    public const string PluginName = "(UI) Outbound Bulgarian Translation";
    public const string PluginVersion = "0.1.2";

    internal static new ManualLogSource Log;
    internal static readonly Dictionary<string, string> Replacements = new Dictionary<string, string>(StringComparer.Ordinal);
    internal static readonly Dictionary<string, string> GnomeNameReplacements = new Dictionary<string, string>(StringComparer.Ordinal);
    internal static readonly HashSet<string> DumpedKeys = new HashSet<string>(StringComparer.Ordinal);
    internal static string DumpPath = string.Empty;
    internal static string LabelsPath = string.Empty;
    internal static string LegacyLabelsPath = string.Empty;
    internal static string GnomeNamesPath = string.Empty;
    internal static ConfigEntry<bool> DumpTranslations;
    internal static ConfigEntry<bool> EnableTranslationOverrides;
    internal static ConfigEntry<bool> LegacyEnableBulgarianOverrides;
    internal static ConfigEntry<bool> LegacyTreatUkrainianAsBulgarian;
    internal static ConfigEntry<bool> LegacyAssumeBulgarianOnStartup;
    internal static ConfigEntry<string> LabelsFileName;
    internal static ConfigEntry<string> TargetLanguageName;
    internal static ConfigEntry<bool> OverrideAllLanguages;
    internal static ConfigEntry<bool> AssumeTargetLanguageOnStartup;
    internal static ConfigEntry<bool> EnableGnomeNameOverrides;
    internal static Harmony HarmonyInstance;
    internal static Language CurrentLanguage = Language.English;
    internal static Language TargetLanguage = Language.Ukrainian;
    internal static bool IsApplyingTextOverride;

    public override void Load()
    {
        Log = base.Log;

        var pluginDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? AppContext.BaseDirectory;
        var dumpDir = Path.Combine(pluginDir, "dumps");
        Directory.CreateDirectory(dumpDir);

        LegacyLabelsPath = Path.Combine(pluginDir, "translations", "labels-bg.txt");
        GnomeNamesPath = Path.Combine(pluginDir, "translations", "gnome-names.txt");
        DumpPath = Path.Combine(dumpDir, "translation-dump.txt");

        DumpTranslations = Config.Bind("General", "DumpTranslations", false, "Dump discovered translation keys and resolved text to translation-dump.txt. Enable this only while developing or reporting missing translations.");
        EnableTranslationOverrides = Config.Bind("General", "EnableTranslationOverrides", false, "Replace translated strings from the configured labels file.");
        LegacyEnableBulgarianOverrides = Config.Bind("General", "EnableBulgarianOverrides", false, "Legacy option. Prefer EnableTranslationOverrides for new projects.");
        LegacyTreatUkrainianAsBulgarian = Config.Bind("General", "TreatUkrainianAsBulgarian", true, "Legacy option. Prefer TargetLanguageName for new projects.");
        LegacyAssumeBulgarianOnStartup = Config.Bind("General", "AssumeBulgarianOnStartup", false, "Legacy option. Prefer AssumeTargetLanguageOnStartup for new projects.");
        LabelsFileName = Config.Bind("General", "LabelsFileName", "labels.txt", "Translation file name inside the translations folder. Falls back to labels-bg.txt if labels.txt does not exist.");
        TargetLanguageName = Config.Bind("General", "TargetLanguageName", "Ukrainian", "Game language enum value that should be treated as the translated language slot.");
        OverrideAllLanguages = Config.Bind("General", "OverrideAllLanguages", false, "Apply replacements regardless of the currently selected game language.");
        AssumeTargetLanguageOnStartup = Config.Bind("General", "AssumeTargetLanguageOnStartup", false, "Assume the configured translated language slot is active before the game reports its saved language.");
        EnableGnomeNameOverrides = Config.Bind("General", "EnableGnomeNameOverrides", true, "Replace collectible gnome names from translations/gnome-names.txt after the game formats them into UI text.");
        LabelsPath = Path.Combine(pluginDir, "translations", LabelsFileName.Value);
        TargetLanguage = ResolveTargetLanguage(TargetLanguageName.Value);

        if (AssumeTargetLanguageOnStartup.Value || LegacyAssumeBulgarianOnStartup.Value)
        {
            CurrentLanguage = TargetLanguage;
        }

        LoadReplacements();
        LoadGnomeNameReplacements();

        HarmonyInstance = new Harmony(PluginGuid);
        HarmonyInstance.PatchAll(typeof(Plugin).Assembly);

        Log.LogInfo($"{PluginName} {PluginVersion} loaded");
        Log.LogInfo($"translation entries: {Replacements.Count}");
        Log.LogInfo($"gnome name entries: {GnomeNameReplacements.Count}");
        Log.LogInfo($"target language slot: {TargetLanguage}");
        Log.LogInfo($"dump path: {DumpPath}");
    }

    internal static Language ResolveTargetLanguage(string value)
    {
        if (Enum.TryParse(value, true, out Language language))
        {
            return language;
        }

        Log.LogWarning($"Unknown TargetLanguageName '{value}', falling back to Ukrainian.");
        return Language.Ukrainian;
    }

    internal static void LoadReplacements()
    {
        Replacements.Clear();

        if (!File.Exists(LabelsPath) && File.Exists(LegacyLabelsPath))
        {
            LabelsPath = LegacyLabelsPath;
            Log.LogInfo("Using legacy translation file labels-bg.txt. Rename it to labels.txt for new projects.");
        }

        if (!File.Exists(LabelsPath))
        {
            Log.LogWarning($"Translation file not found: {LabelsPath}");
            return;
        }

        foreach (var rawLine in File.ReadAllLines(LabelsPath, Encoding.UTF8))
        {
            var line = rawLine.Trim();
            if (line.Length == 0 || line.StartsWith("#") || line.StartsWith("//"))
            {
                continue;
            }

            var separatorIndex = line.IndexOf('=');
            if (separatorIndex <= 0)
            {
                continue;
            }

            var key = line[..separatorIndex].Trim();
            var value = DecodeLabelValue(line[(separatorIndex + 1)..]);

            if (key.Length != 0)
            {
                Replacements[key] = value;
            }
        }
    }

    internal static void LoadGnomeNameReplacements()
    {
        GnomeNameReplacements.Clear();

        if (!File.Exists(GnomeNamesPath))
        {
            Log.LogInfo($"Gnome name file not found: {GnomeNamesPath}");
            return;
        }

        foreach (var rawLine in File.ReadAllLines(GnomeNamesPath, Encoding.UTF8))
        {
            var line = rawLine.Trim();
            if (line.Length == 0 || line.StartsWith("#") || line.StartsWith("//"))
            {
                continue;
            }

            var separatorIndex = line.IndexOf('=');
            if (separatorIndex <= 0)
            {
                continue;
            }

            var original = line[..separatorIndex].Trim();
            var replacement = DecodeLabelValue(line[(separatorIndex + 1)..].Trim());

            if (original.Length != 0 && replacement.Length != 0 && !string.Equals(original, replacement, StringComparison.Ordinal))
            {
                GnomeNameReplacements[original] = replacement;
            }
        }
    }

    internal static string ReplaceGnomeNames(string text)
    {
        if (string.IsNullOrEmpty(text) || !EnableGnomeNameOverrides.Value || GnomeNameReplacements.Count == 0)
        {
            return text;
        }

        if (!IsTargetLanguageMode(CurrentLanguage))
        {
            return text;
        }

        if (TryReplaceStandaloneGnomeName(text, out var standaloneReplacement))
        {
            return standaloneReplacement;
        }

        if (!LooksLikeGnomeNameText(text))
        {
            return text;
        }

        var result = text;
        foreach (var pair in GnomeNameReplacements)
        {
            if (result.IndexOf(pair.Key, StringComparison.Ordinal) >= 0)
            {
                result = result.Replace(pair.Key, pair.Value, StringComparison.Ordinal);
            }
        }

        return result;
    }

    internal static bool TryReplaceStandaloneGnomeName(string text, out string replacement)
    {
        var prefix = string.Empty;
        var suffix = string.Empty;
        var candidate = text.Trim();

        if (candidate.Length != text.Length)
        {
            var start = text.IndexOf(candidate, StringComparison.Ordinal);
            prefix = text[..start];
            suffix = text[(start + candidate.Length)..];
        }

        if (GnomeNameReplacements.TryGetValue(candidate, out var mapped))
        {
            replacement = prefix + mapped + suffix;
            return true;
        }

        replacement = text;
        return false;
    }

    internal static bool LooksLikeGnomeNameText(string text)
    {
        return text.IndexOf("Носи името", StringComparison.OrdinalIgnoreCase) >= 0
            || text.IndexOf("Зветься", StringComparison.OrdinalIgnoreCase) >= 0
            || text.IndexOf("It goes by the name", StringComparison.OrdinalIgnoreCase) >= 0;
    }

    internal static string DecodeLabelValue(string value)
    {
        return value
            .Replace("\\r\\n", "\n")
            .Replace("\\n", "\n")
            .Replace("\\r", "\n")
            .Replace("\\t", "\t");
    }

    internal static bool IsTargetLanguageMode(Language language)
    {
        return OverrideAllLanguages.Value || language == TargetLanguage || (LegacyTreatUkrainianAsBulgarian.Value && language == Language.Ukrainian);
    }

    internal static bool AreTranslationOverridesEnabled()
    {
        return EnableTranslationOverrides.Value || LegacyEnableBulgarianOverrides.Value;
    }

    internal static void RefreshVisibleTranslations()
    {
        if (!AreTranslationOverridesEnabled())
        {
            return;
        }

        try
        {
            var components = UnityEngine.Object.FindObjectsOfType<Translate>(true);
            var refreshed = 0;

            foreach (var component in components)
            {
                if (component == null)
                {
                    continue;
                }

                try
                {
                    component.UpdateText();
                    refreshed++;
                }
                catch (Exception ex)
                {
                    Log.LogWarning($"Failed to refresh Translate component: {ex.Message}");
                }
            }

            Log.LogInfo($"Refreshed {refreshed} Translate components for {CurrentLanguage}");
        }
        catch (Exception ex)
        {
            Log.LogWarning($"Failed to refresh visible translations: {ex.Message}");
        }
    }

    internal static void RefreshVisibleTranslationsIfTargetLanguage()
    {
        if (!IsTargetLanguageMode(CurrentLanguage))
        {
            return;
        }

        RefreshVisibleTranslations();
    }

    internal static void Dump(string key, string text, string source)
    {
        if (!DumpTranslations.Value)
        {
            return;
        }

        if (key == null)
        {
            key = string.Empty;
        }
        if (text == null)
        {
            text = string.Empty;
        }

        var normalized = $"{key}\t{text}";
        lock (DumpedKeys)
        {
            if (!DumpedKeys.Add(normalized))
            {
                return;
            }
        }

        try
        {
            File.AppendAllText(DumpPath, $"{source}\t{key}\t{text}{Environment.NewLine}", Encoding.UTF8);
        }
        catch (Exception ex)
        {
            Log.LogWarning($"Failed to append dump entry: {ex.Message}");
        }
    }
}

[HarmonyPatch]
internal static class TranslationPatches
{
    [HarmonyPatch(typeof(TranslationManager), nameof(TranslationManager.SetLanguage))]
    [HarmonyPostfix]
    internal static void TranslationManager_SetLanguage_Postfix(Language language)
    {
        Plugin.CurrentLanguage = language;
        Plugin.Log.LogInfo($"SetLanguage => {language}");
        Plugin.RefreshVisibleTranslationsIfTargetLanguage();
    }

    [HarmonyPatch(typeof(TranslationManager), nameof(TranslationManager.Translate), typeof(string), typeof(bool), typeof(Language))]
    [HarmonyPostfix]
    internal static void TranslationManager_Translate_Postfix(string __0, bool __1, Language __2, ref string __result)
    {
        var key = __0 ?? string.Empty;
        var resolved = __result ?? string.Empty;

        Plugin.Dump(key, resolved, "TranslationManager.Translate");

        if (!Plugin.AreTranslationOverridesEnabled())
        {
            return;
        }

        if (!Plugin.IsTargetLanguageMode(__2) && !Plugin.IsTargetLanguageMode(Plugin.CurrentLanguage))
        {
            return;
        }

        string replacement;
        if (Plugin.Replacements.TryGetValue(key, out replacement))
        {
            __result = replacement;
            Plugin.Dump(key, replacement, "BG.Override");
        }
        else if (Plugin.Replacements.TryGetValue(resolved, out replacement))
        {
            __result = replacement;
            Plugin.Dump(key, replacement, "BG.OverrideByResolvedText");
        }

        __result = Plugin.ReplaceGnomeNames(__result);
    }

    [HarmonyPatch(typeof(Translate), "UpdateText")]
    [HarmonyPostfix]
    internal static void Translate_UpdateText_Postfix(Translate __instance)
    {
        if (__instance == null)
        {
            return;
        }

        if (Plugin.IsApplyingTextOverride)
        {
            return;
        }

        string key;
        string text;

        try
        {
            key = __instance.translationKey ?? string.Empty;
        }
        catch
        {
            key = string.Empty;
        }

        try
        {
            text = __instance.cachedText ?? __instance.GetText() ?? string.Empty;
        }
        catch
        {
            text = string.Empty;
        }

        Plugin.Dump(key, text, "Translate.UpdateText");

        if (!Plugin.AreTranslationOverridesEnabled())
        {
            return;
        }

        if (!Plugin.IsTargetLanguageMode(Plugin.CurrentLanguage))
        {
            return;
        }

        string replacement;
        if (Plugin.Replacements.TryGetValue(key, out replacement) || Plugin.Replacements.TryGetValue(text, out replacement))
        {
            try
            {
                Plugin.IsApplyingTextOverride = true;
                __instance.SetText(replacement);
                __instance.cachedText = replacement;
                Plugin.Dump(key, replacement, "Translate.SetTextOverride");
            }
            catch (Exception ex)
            {
                Plugin.Log.LogWarning($"Failed to override Translate text for key '{key}': {ex.Message}");
            }
            finally
            {
                Plugin.IsApplyingTextOverride = false;
            }
        }
    }

    [HarmonyPatch(typeof(TMP_Text), "set_text")]
    [HarmonyPrefix]
    internal static void TMP_Text_set_text_Prefix(ref string value)
    {
        try
        {
            value = Plugin.ReplaceGnomeNames(value);
        }
        catch (Exception ex)
        {
            Plugin.Log.LogWarning($"Failed to override gnome name in TMP text: {ex.Message}");
        }
    }
}
