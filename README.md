# Outbound Bulgarian Translation Mod

Български UI/текстов превод за `Outbound`, реализиран като BepInEx 6 IL2CPP плъгин.

Модът заменя украинския езиков слот в играта с български и зарежда превода от `translations/labels.txt`.

Текущата версия `0.1.4` е проверена с `Outbound 1.1.3-902` (Steam build `23857020`).

## За Играчи

1. Инсталирай BepInEx Unity IL2CPP x64 6.0.0 be.755 или по-нова версия в папката на Outbound.
2. Стартирай играта веднъж и я затвори, за да може BepInEx да създаде нужните папки и interop файлове.
3. Разархивирай мода в папката на Outbound.
4. Стартирай играта и избери `Ukrainian` от менюто за език. След като модът се зареди, този слот се показва като български.

Очаквани пътища след инсталация:

- `Outbound/BepInEx/plugins/OutboundTranslationMod/OutboundTranslationMod.dll`
- `Outbound/BepInEx/plugins/OutboundTranslationMod/translations/labels.txt`
- `Outbound/BepInEx/plugins/OutboundTranslationMod/translations/gnome-names.txt`
- `Outbound/BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg`

## Задължителна Конфигурация

Това е конфигурационният файл на самия плъгин, не основна BepInEx настройка:

`BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg`

Архивът включва правилната конфигурация за нормална игра:

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

`AssumeTargetLanguageOnStartup = true` е важна настройка за Outbound. Играта може да нарисува първите текстове в главното меню преди да съобщи запазения украински езиков слот на плъгина. Без тази настройка началното меню може да остане на украински, докато играчът не смени езика ръчно.

Ако вече си пускал по-стара версия на мода, BepInEx може да запази старите стойности. В такъв случай замени конфигурационния файл с този от архива или изтрий стария файл и пусни играта отново.

`DumpTranslations = false` е настройката за нормална игра. Включвай я само при търсене на липсващ или твърдо записан текст, защото записва открит текст от играта в локален dump файл.

`EnableGnomeNameOverrides = true` включва отделната таблица за имената на гномите от `translations/gnome-names.txt`.

`EnableCompassDirectionOverrides = true` превежда посоките на компаса от `N/E/S/W` на `С/И/Ю/З`. Тези надписи не са стандартни ключове за локализация, затова плъгинът ги обработва отделно само в интерфейса на компаса.

## Текущ Статус

- Всички извлечени ключове за локализация на Outbound са покрити в `labels.txt`.
- Тестваната версия е `Outbound 1.1.3-902` за Steam (build `23857020`).
- Новите архиви използват `translations/labels.txt`; `labels-bg.txt` е само резервен файл за съвместимост.
- Посоките на компаса `N/E/S/W` не са част от таблицата за локализация, но се превеждат отделно в интерфейса на компаса.
- Microsoft Store / Xbox app версиите може да изискват допълнителна BepInEx настройка и не са гарантирани от този пакет.

## Структура

- `src/OutboundTranslationMod`: изходният код на BepInEx IL2CPP плъгина.
- `src/OutboundTranslationMod/translations/labels.txt`: активният български превод.
- `release/`: README за Nexus и конфигурация за архива.
- `scripts/`: скриптове за build, пакетиране и проверка.
- `User.targets.example`: примерна локална build конфигурация за различни пътища до играта.

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

`User.targets` е игнориран от git, за да може всеки contributor да използва различен път до Steam библиотеката.

Build:

```powershell
.\scripts\build-plugin.ps1
```

Ако NuGet средата ти е настроена нормално, може да пробваш и:

```powershell
.\scripts\build-plugin.ps1 -Method dotnet
```

Създаване на архив за Nexus след build:

```powershell
.\scripts\package-release.ps1
```

Архивът се записва в `dist/` и включва само DLL файла на плъгина, `labels.txt`, `gnome-names.txt`, конфигурацията, README за играчи, лиценза и бележката за авторство.

GitHub Actions проверява файловете за превод и метаданните на архива, но не build-ва DLL-а. Публичен CI build би изисквал локални BepInEx interop/game assemblies от инсталирано копие на Outbound, които не трябва да се commit-ват или разпространяват.

При публикуване на GitHub Release workflow-ът `Publish Nexus From Release` качва неговия ZIP файл в Nexus Mods. Версията и описанието на файла се вземат директно от tag-а и release бележките в GitHub.

## Правила За Споделяне

Може да се споделя:

- Изходният код на плъгина.
- Скриптовете за build и пакетиране.
- Build шаблоните.
- Собственият български `labels.txt`.

Не трябва да се споделят:

- Извлечени game assets.
- Оригинални game dumps.
- Оригинални game assets или генерирани файлове, съдържащи оригинален текст за локализация.

## Лиценз

Кодът, скриптовете и българският превод са публикувани под MIT License. Ако използваш проекта като база за друг translation mod, запази copyright/license notice и credit-а към оригиналния проект, както е описано в `NOTICE.md`.

## Важна Бележка

Не копирай BepInEx папка от Mono Unity игра в IL2CPP Unity игра. `Outbound` изисква IL2CPP-съвместима BepInEx инсталация.
