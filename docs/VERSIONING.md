# Версионирование и релизы

Этот документ описывает, как назначать версии Safe Screen, как выпускать DMG и как поддерживать историю изменений.

## Текущая схема

Safe Screen использует SemVer-подход:

```text
MAJOR.MINOR.PATCH
```

Примеры:

- `0.2.7` - текущий стабильный выпуск;
- `0.2.8` - patch-релиз с небольшим исправлением;
- `0.3.0` - minor-релиз с новой пользовательской возможностью;
- `1.0.0` - первый стабильный публичный релиз с зафиксированным поведением.

Пока проект находится в серии `0.x`, minor-версии могут включать заметные изменения поведения. После `1.0.0` breaking changes должны попадать только в major-релизы.

## Где хранится версия

Единственный источник публичной версии - файл `VERSION` в корне репозитория.

```text
0.2.7
```

Это одна строка в формате `MAJOR.MINOR.PATCH`. Версию не редактируют вручную ни в `VERSION`, ни в `Info.plist` - её разносит скрипт `scripts/set_version.sh` (см. ниже).

Скрипт `set_version.sh` зеркалит `VERSION` в `Resources/Info.plist`:

```xml
<key>CFBundleShortVersionString</key>
<string>0.2.7</string>
<key>CFBundleVersion</key>
<string>10</string>
```

| Поле | Источник | Назначение |
| --- | --- | --- |
| `VERSION` (файл) | редактируется через `set_version.sh` | единственный источник публичной версии |
| `CFBundleShortVersionString` | зеркало `VERSION`, ставит `set_version.sh` | публичная версия в бандле |
| `CFBundleVersion` | инкрементит `set_version.sh` | монотонно растущий build number |

При сборке `build_app.sh` дополнительно проставляет `CFBundleShortVersionString` в собираемом бандле прямо из `VERSION`, поэтому готовый `.app` всегда совпадает с `VERSION`, даже если `Info.plist` оказался рассинхронизирован.

DMG-скрипт читает `VERSION` и создает файл:

```text
dist/Safe-Screen-<version>.dmg
```

Например:

```text
dist/Safe-Screen-0.2.7.dmg
```

## Как менять версию

Версию меняет только скрипт:

```bash
./scripts/set_version.sh 0.2.8
```

Скрипт:

- проверяет формат `MAJOR.MINOR.PATCH`;
- записывает новое значение в `VERSION`;
- проставляет `CFBundleShortVersionString` в `Resources/Info.plist`;
- увеличивает `CFBundleVersion` на единицу;
- печатает дальнейшие шаги (commit, tag, push).

Не редактируйте `VERSION` или `Info.plist` вручную - это снова создаст рассинхрон, ради устранения которого скрипт и существует.

## Когда повышать версию

### Patch

Повышайте `PATCH`, если изменение исправляет баг или улучшает стабильность без изменения основного поведения.

Примеры:

- приложение не открывалось;
- ручная активация сразу скрывала overlay;
- исправлена сборка DMG;
- обновлена документация без изменения приложения.

Пример:

```text
0.2.7 -> 0.2.8
```

### Minor

Повышайте `MINOR`, если добавлена новая пользовательская возможность или заметно изменено поведение.

Примеры:

- добавлен новый режим анимации;
- добавлена настройка таймера в UI;
- добавлена notarized-сборка;
- изменена модель autostart/login behavior.

Пример:

```text
0.2.7 -> 0.3.0
```

### Major

Повышайте `MAJOR`, если изменение несовместимо с прежними ожиданиями пользователя или требует миграции.

Примеры:

- переход с обычного `.app` на системный `.saver`;
- изменение bundle identifier;
- удаление menu-bar/control-panel модели;
- значительное изменение release/install workflow.

Пример:

```text
1.2.3 -> 2.0.0
```

## Build number

`CFBundleVersion` - монотонно растущий build number. `scripts/set_version.sh` увеличивает его на единицу при каждом запуске, поэтому вручную его трогать не нужно.

Пример:

```text
0.2.7 build 10
0.2.8 build 11
0.3.0 build 12
```

Не переиспользуйте build number для разных релизов.

## Git tags

Релизные теги имеют формат:

```text
vMAJOR.MINOR.PATCH
```

Примеры:

```text
v0.2.7
v0.2.8
v0.3.0
```

Tag должен совпадать с файлом `VERSION` (с префиксом `v`). GitHub Actions проверяет это перед сборкой: если `VERSION` содержит `0.2.8`, релизный tag обязан быть `v0.2.8`, иначе workflow падает.

## Release checklist

1. Убедиться, что рабочее дерево чистое:

```bash
git status --short --branch
```

2. Обновить версию одним скриптом:

```bash
./scripts/set_version.sh <version>
```

Скрипт сам запишет `VERSION` и синхронизирует `Resources/Info.plist`.

3. Обновить `CHANGELOG.md`.

4. Запустить тесты:

```bash
swift test
```

5. Проверить release build:

```bash
swift build -c release
```

6. Собрать DMG локально:

```bash
bash ./scripts/build_dmg.sh
```

7. Проверить DMG:

```bash
hdiutil verify dist/Safe-Screen-<version>.dmg
```

8. Закоммитить изменения:

```bash
git add VERSION Resources/Info.plist CHANGELOG.md README.md docs/VERSIONING.md
git commit -m "Release v<version>"
git push origin main
```

9. Создать и отправить tag:

```bash
git tag v<version>
git push origin v<version>
```

10. Проверить GitHub Actions и GitHub Release:

```text
https://github.com/LexorCrypto/safe_screen/actions
https://github.com/LexorCrypto/safe_screen/releases
```

## GitHub Actions

Workflow:

```text
.github/workflows/release.yml
```

Он запускается при push tag вида `v*` и делает следующее:

1. checkout репозитория;
2. проверка, что tag совпадает с файлом `VERSION` (иначе workflow падает);
3. `swift test`;
4. `bash ./scripts/build_dmg.sh`;
5. upload workflow artifact;
6. `gh release create ...`;
7. прикрепление DMG к GitHub Release.

## Локальная сборка DMG

Скрипт:

```text
scripts/build_dmg.sh
```

Особенности:

- использует `scripts/build_app.sh`;
- копирует `.app` во временную staging-папку (`$TMPDIR`);
- чистит xattrs и переподписывает `.app` ad-hoc подписью в staging;
- добавляет symlink `Applications`;
- создает сжатый `UDZO` образ через `hdiutil`;
- запускает `hdiutil verify`.

## Важные ограничения

- DMG сейчас не notarized.
- Подпись `.app` ad-hoc, не Developer ID.
- При первом запуске macOS может показать Gatekeeper warning.
- Для публичного распространения за пределами личного использования желательно добавить Developer ID signing и notarization.

## Что обновлять при каждом релизе

Минимальный набор:

- `VERSION` (через `scripts/set_version.sh`, он же синхронизирует `Resources/Info.plist`);
- `CHANGELOG.md`;
- tag `v<version>`.

Если меняется release process, также обновляйте:

- `README.md`;
- `docs/VERSIONING.md`;
- `.github/workflows/release.yml`;
- `scripts/build_dmg.sh`.
