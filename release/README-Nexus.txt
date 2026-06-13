Outbound Bulgarian Translation
==============================

Този мод добавя български UI/текстов превод за Outbound чрез BepInEx 6 IL2CPP.

Инсталация
----------

1. Инсталирай BepInEx Unity IL2CPP x64 6.0.0 be.755 или по-нова версия в папката на Outbound.
2. Стартирай играта веднъж и я затвори, за да може BepInEx да създаде нужните папки и interop файлове.
3. Разархивирай този архив в папката на Outbound.
4. Стартирай играта и избери Ukrainian от менюто за език. Модът заменя украинския езиков слот с български.

Очаквани пътища след инсталация:

- Outbound/BepInEx/plugins/OutboundTranslationMod/OutboundTranslationMod.dll
- Outbound/BepInEx/plugins/OutboundTranslationMod/translations/labels.txt
- Outbound/BepInEx/plugins/OutboundTranslationMod/translations/gnome-names.txt
- Outbound/BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg

Препоръчителна конфигурация
---------------------------

Архивът включва тази конфигурация на плъгина за нормална игра:

Outbound/BepInEx/config/actepukc.outbound.uitranslationbulgarian.cfg

- DumpTranslations = false
- EnableTranslationOverrides = true
- EnableGnomeNameOverrides = true
- EnableCompassDirectionOverrides = true
- LabelsFileName = labels.txt
- TargetLanguageName = Ukrainian
- OverrideAllLanguages = false
- AssumeTargetLanguageOnStartup = true

Важно: AssumeTargetLanguageOnStartup = true е нужна настройка за началното меню на Outbound при замяна на Ukrainian. Без нея първото меню може да остане на украински, докато езикът не бъде сменен ръчно.

EnableGnomeNameOverrides = true включва отделната таблица за имената на гномите от translations/gnome-names.txt.

EnableCompassDirectionOverrides = true превежда посоките на компаса от N/E/S/W на С/И/Ю/З. Тези надписи не са част от стандартната таблица за локализация, затова се обработват отделно само в интерфейса на компаса.

Ако вече си пускал по-стара версия на мода, BepInEx може да запази старите стойности. Замени конфигурационния файл с този от архива или изтрий стария файл и пусни играта отново.

Бележки
-------

- Посоките на компаса N/E/S/W не са част от таблицата за локализация на играта, но този мод ги превежда отделно в интерфейса на компаса.
- Някои collectible имена идват от game asset имена, а не от стандартни ключове за превод.
- Runtime dumping е изключен в пакета. Включвай DumpTranslations само ако искаш да докладваш новооткрит липсващ текст.

Автори
------

Български превод и мод: AcTePuKc / Щерян Николаев
Лиценз: MIT
