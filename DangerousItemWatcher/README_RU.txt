# Dangerous Item Watcher — Barotrauma / LuaCs

Серверный LuaCs-мод, который выводит в консоль хоста события с предметами из списка `WATCHED_ITEMS`.
Сообщения в игровой чат не отправляются.

## Установка

1. Убедитесь, что LuaCs for Barotrauma установлен и работает на сервере.
2. Распакуйте папку `DangerousItemWatcher` в папку `LocalMods` Barotrauma.
   Обычно это: `%LOCALAPPDATA%\Daedalic Entertainment GmbH\Barotrauma\LocalMods\`
   Если папки `LocalMods` нет, проверьте путь, указанный в документации вашей сборки LuaCs.
3. Убедитесь, что структура выглядит так:
   `LocalMods/DangerousItemWatcher/filelist.xml`
   `LocalMods/DangerousItemWatcher/Lua/Autorun/dangerous_item_watcher.lua`
4. Включите мод в списке модификаций/content packages, если ваша конфигурация LuaCs требует включения пакета.
5. Запустите/перезагрузите сервер. Для повторной загрузки LuaCs обычно поддерживает консольную команду `reloadlua`.
6. Проверьте консоль на сообщение `[DangerousItemWatcher] загружен...`.

## Настройка предметов

Откройте `Lua/Autorun/dangerous_item_watcher.lua` и измените таблицу `WATCHED_ITEMS`:

```lua
local WATCHED_ITEMS = {
    ["c4"] = "C-4",
    ["detonator"] = "Детонатор",
    ["wire"] = "Провод",
}
```

Слева указывается prefab Identifier, справа — подпись для журнала. Identifier обычно не зависит от языка интерфейса. Если предмет не отслеживается, проверьте его реальный Identifier в контенте игры/мода.

## Пример вывода

`[DangerousItemWatcher] Игрок «Alex» взял/переместил в инвентарь: Детонатор x1 [id=detonator]`
`[DangerousItemWatcher] Игрок «Alex» положил в контейнер: C-4 x1 [id=c4]`
`[DangerousItemWatcher] Игрок «Alex» положил/выбросил: C-4 x1 [id=c4]`

## Ограничения и проверка

- Это начальная реализация на основе хуков LuaCs `inventoryPutItem` и `item.drop`.
- Хук `inventoryPutItem` может вызываться при разных перемещениях внутри инвентаря; в зависимости от сборки могут появляться повторные записи. Проверьте подбор с пола, взятие из шкафа, перестановку в собственном инвентаре и помещение предмета в контейнер.
- Название действия `положил/выбросил` намеренно не утверждает, что предмет помещён в конкретный шкаф: `item.drop` означает событие выбрасывания/сброса.
- Количество выводится из доступного свойства размера стопки, если оно предоставляется данной сборкой; иначе выводится `x1`. Для предметов, которые Barotrauma представляет отдельными объектами, это корректно.
- Скрипт пишет через `print`, то есть в консоль/серверный лог LuaCs; он не отправляет сообщения игрокам.

Документация LuaCs:
https://github.com/evilfactory/LuaCsForBarotrauma/blob/master/luacs-docs/lua/manual/getting-started.md
https://github.com/evilfactory/LuaCsForBarotrauma/blob/master/luacs-docs/lua/manual/how-to-use-hooks.md


## Исправление ошибки загрузки filelist.xml

В filelist.xml нельзя объявлять Lua-файл как `<Item ... />`: Barotrauma пытается загрузить его как игровой предмет. В исправленной версии filelist.xml оставлен без элемента Item. LuaCs сам находит и выполняет скрипты в `Lua/Autorun` у включённых content package.
