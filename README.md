# Outbound Bulgarian Translation Mod

Български UI/текстов превод за `Outbound`, реализиран като BepInEx 6 IL2CPP plugin.

Модът заменя украинския езиков слот в играта с български и зарежда превода от `translations/labels.txt`.

## За Играчи

1. Инсталирай BepInEx Unity IL2CPP x64 6.0.0 be.755 или по-нова версия в папката на Outbound.
2. Стартирай играта веднъж и я затвори, за да може BepInEx да създаде нужните папки и interop файлове.
3. Разархивирай мода в папката на Outbound.
4. Стартирай играта и избери `Ukrainian` от менюто за език. След като модът се зареди, този слот се показва като български.

Очаквани пътища след инсталация:

- `Outbound/BepInEx/plugins/OutboundTranslationMod/OutboundTranslationMod.dll`
- `Outbound/BepInEx/plugins/OutboundTranslationMod/translations/labels.txt`
- `Outbound/BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg`

## Задължителен Config

Това е config файлът на самия plugin, не основна BepInEx настройка:

`BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg`

Release архивът включва правилния config за нормална игра:

```ini
[General]
DumpTranslations = false
EnableTranslationOverrides = true
EnableGnomeNameOverrides = true
EnableCompassDirectionOverrides = true
LabelsFileName = labels.txt
TargetLanguageName = Ukrainian
OverrideAllLanguages = false
AssumeTargetLanguageOnStartup = true
```

`AssumeTargetLanguageOnStartup = true` е важна настройка за Outbound. Играта може да нарисува първите текстове в главното меню преди да съобщи запазения украински езиков слот на plugin-а. Без тази настройка началното меню може да остане на украински, докато играчът не смени езика ръчно.

Ако вече си пускал по-стара версия на мода, BepInEx може да запази старите config стойности. В такъв случай замени config файла с този от release архива или изтрий стария config и пусни играта отново.

`DumpTranslations = false` е release настройката. Включвай я само при debug на липсващ или hardcoded текст, защото записва открит текст от играта в локален dump файл.

`EnableGnomeNameOverrides = true` включва отделната таблица за имената на гномите от `translations/gnome-names.txt`.

`EnableCompassDirectionOverrides = true` превежда посоките на компаса от `N/E/S/W` на `С/И/Ю/З`. Тези надписи не са стандартни localization ключове, затова plugin-ът ги обработва с отделен тесен hook само за compass UI.

## Текущ Статус

- Всички извлечени localization ключове на Outbound са покрити в `labels.txt`.
- Тестваната версия е Steam IL2CPP build-ът.
- Новите release-и използват `translations/labels.txt`; `labels-bg.txt` е само legacy fallback.
- Посоките на компаса `N/E/S/W` не са част от localization таблицата, но се превеждат чрез отделен compass UI hook.
- Microsoft Store / Xbox app build-овете може да изискват допълнителна BepInEx настройка и не са гарантирани от този пакет.

## Структура

- `src/OutboundTranslationMod`: source код на BepInEx IL2CPP plugin-а.
- `src/OutboundTranslationMod/translations/labels.txt`: активният български превод.
- `release/`: Nexus README и release config.
- `scripts/`: build, package и validation scripts.
- `User.targets.example`: примерен локален build config за различни game paths.

В `labels.txt` escaped нови редове като `\n\n` се поддържат директно в стойностите, без целият текст да се слага в кавички.

## Build От Source

Създай локален `User.targets` файл:

```xml
<Project>
  <PropertyGroup>
    <BepInExGameDir>C:\Program Files (x86)\Steam\steamapps\common\Outbound</BepInExGameDir>
  </PropertyGroup>
</Project>
```

`User.targets` е игнориран от git, за да може всеки contributor да използва различен Steam library path.

Build:

```powershell
.\scripts\build-plugin.ps1
```

Ако NuGet средата ти е настроена нормално, може да пробваш и:

```powershell
.\scripts\build-plugin.ps1 -Method dotnet
```

Създаване на Nexus-style архив след build:

```powershell
.\scripts\package-release.ps1
```

Архивът се записва в `dist/` и включва само plugin DLL, `labels.txt`, `gnome-names.txt`, release config, player README, license и attribution notice.

GitHub Actions валидира translation файловете и release metadata, но не build-ва DLL-а. Публичен CI build би изисквал локални BepInEx interop/game assemblies от инсталирано копие на Outbound, които не трябва да се commit-ват или разпространяват.

## Правила За Споделяне

Може да се споделя:

- Source кодът на plugin-а.
- Build/package scripts.
- Build templates.
- Собственият български `labels.txt`.

Не трябва да се споделят:

- Извлечени game assets.
- Оригинални game dumps.
- Оригинални game assets или generated файлове, съдържащи оригинален localization текст.

## License

Кодът, scripts и българският превод са публикувани под MIT License. Ако използваш проекта като база за друг translation mod, запази copyright/license notice и credit-а към оригиналния проект, както е описано в `NOTICE.md`.

## Важна Бележка

Не копирай BepInEx папка от Mono Unity игра в IL2CPP Unity игра. `Outbound` изисква IL2CPP-съвместима BepInEx инсталация.
