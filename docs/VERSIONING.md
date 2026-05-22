# Версионирование и релизы

Этот документ описывает, как назначать версии Safe Screen, как выпускать DMG и как поддерживать историю изменений.

## Текущая схема

Safe Screen использует SemVer-подход:

```text
MAJOR.MINOR.PATCH
```

Примеры:

- `0.2.6` - текущий стабильный выпуск;
- `0.2.7` - patch-релиз с небольшим исправлением;
- `0.3.0` - minor-релиз с новой пользовательской возможностью;
- `1.0.0` - первый стабильный публичный релиз с зафиксированным поведением.

Пока проект находится в серии `0.x`, minor-версии могут включать заметные изменения поведения. После `1.0.0` breaking changes должны попадать только в major-релизы.

## Где хранится версия

Главный источник версии - `Resources/Info.plist`.

```xml
<key>CFBundleShortVersionString</key>
<string>0.2.6</string>
<key>CFBundleVersion</key>
<string>9</string>
```

Поля:

| Поле | Назначение |
| --- | --- |
| `CFBundleShortVersionString` | публичная версия приложения в формате `MAJOR.MINOR.PATCH` |
| `CFBundleVersion` | монотонно растущий build number |

DMG-скрипт читает `CFBundleShortVersionString` и создает файл:

```text
dist/Safe-Screen-<version>.dmg
```

Например:

```text
dist/Safe-Screen-0.2.6.dmg
```

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
0.2.6 -> 0.2.7
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
0.2.6 -> 0.3.0
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

`CFBundleVersion` должен увеличиваться при каждом релизе, даже если публичная версия меняется только на patch.

Пример:

```text
0.2.6 build 9
0.2.7 build 10
0.3.0 build 11
```

Не переиспользуйте build number для разных релизов.

## Git tags

Релизные теги имеют формат:

```text
vMAJOR.MINOR.PATCH
```

Примеры:

```text
v0.2.6
v0.2.7
v0.3.0
```

Tag должен совпадать с `CFBundleShortVersionString` в `Resources/Info.plist`.

## Release checklist

1. Убедиться, что рабочее дерево чистое:

```bash
git status --short --branch
```

2. Обновить версию в `Resources/Info.plist`:

- `CFBundleShortVersionString`;
- `CFBundleVersion`.

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
git add Resources/Info.plist CHANGELOG.md README.md docs/VERSIONING.md
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
2. `swift test`;
3. `bash ./scripts/build_dmg.sh`;
4. upload workflow artifact;
5. `gh release create ...`;
6. прикрепление DMG к GitHub Release.

## Локальная сборка DMG

Скрипт:

```text
scripts/build_dmg.sh
```

Особенности:

- использует `scripts/build_app.sh`;
- подписывает `.app` ad-hoc подписью;
- копирует `.app` во временную staging-папку;
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

- `Resources/Info.plist`;
- `CHANGELOG.md`;
- tag `v<version>`.

Если меняется release process, также обновляйте:

- `README.md`;
- `docs/VERSIONING.md`;
- `.github/workflows/release.yml`;
- `scripts/build_dmg.sh`.
