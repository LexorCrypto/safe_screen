# Safe Screen

Safe Screen - нативное macOS-приложение для защиты OLED-экрана MacBook Pro от статичной картинки, когда ноутбук подключен к питанию и используется удаленно.

Приложение открывает темный полноэкранный overlay со слабыми зелеными Matrix-потоками после 1 минуты локальной неактивности. Потоки меняют позиции каждые 20 секунд через плавный crossfade/slide-переход, чтобы на экране не оставалась статичная картинка.

## Возможности

- Автовключение после `60` секунд без локального ввода.
- Ручной запуск через `Активировать сейчас`.
- Полноэкранный черный overlay на всех дисплеях.
- 5 вертикальных Matrix-потоков символов.
- Смена расположения потоков каждые `20` секунд.
- Плавный переход между позициями за `4` секунды.
- Выключение только от явного ввода: клавиша, клик/тап, scroll, drag или движение мыши поверх Safe Screen.
- Окно управления и menu-bar item `Safe`.
- Опциональный автозапуск при входе в macOS.
- DMG-релизы через GitHub Releases.

## Требования

- macOS 13 или новее.
- Apple Silicon или современный Mac с AppKit.
- Для разработки: Xcode Command Line Tools и SwiftPM.

## Скачать

Актуальный релизный DMG публикуется на GitHub Releases:

[Safe Screen Releases](https://github.com/LexorCrypto/safe_screen/releases)

Текущий релиз:

[Safe-Screen-0.2.6.dmg](https://github.com/LexorCrypto/safe_screen/releases/download/v0.2.6/Safe-Screen-0.2.6.dmg)

## Установка

1. Скачайте `.dmg` из GitHub Releases.
2. Откройте `.dmg`.
3. Перетащите `Safe Screen.app` в `Applications`.
4. Запустите `Safe Screen` из `Applications`.

Сборка подписывается ad-hoc подписью, поэтому macOS может показать предупреждение Gatekeeper при первом запуске. Это не App Store/notarized build.

## Использование

При запуске открывается окно управления. В нем можно:

- включить или выключить защиту;
- нажать `Активировать сейчас`;
- включить `Открывать при входе в macOS`;
- скрыть окно;
- выйти из приложения.

Если окно закрыто, его можно открыть снова:

- через Dock icon;
- через меню приложения `Safe Screen`;
- через зеленый menu-bar item `Safe`.

Safe Screen не является lock screen и не блокирует доступ к Mac. Это OLED-friendly экранная защита, а не security-механизм.

## Поведение

Production defaults:

| Настройка | Значение |
| --- | --- |
| Автовключение | `60s` без локального ввода |
| Количество потоков | `5` |
| Ротация позиций | каждые `20s` |
| Плавный переход | `4s` |
| Цвет | низкая яркость, зеленый Matrix-style |

Overlay остается активным, пока пользователь явно не сделает действие. Фоновые события удаленной сессии не должны сами выключать Safe Screen.

## Сборка

Собрать `.app` локально:

```bash
./scripts/build_app.sh
```

Результат:

```text
build/Safe Screen.app
```

Установить свежую сборку в `/Applications`:

```bash
./scripts/install_app.sh
```

Собрать релизный DMG:

```bash
bash ./scripts/build_dmg.sh
```

Результат:

```text
dist/Safe-Screen-<version>.dmg
```

## Debug Timing

Для быстрой локальной проверки можно переопределить интервалы через environment variables:

```bash
SAFE_SCREEN_IDLE_SECONDS=5 SAFE_SCREEN_LAYOUT_SECONDS=4 SAFE_SCREEN_TRANSITION_SECONDS=1 swift run SafeScreenApp
```

Переменные:

| Переменная | Что меняет |
| --- | --- |
| `SAFE_SCREEN_IDLE_SECONDS` | порог неактивности до включения |
| `SAFE_SCREEN_LAYOUT_SECONDS` | интервал смены позиций Matrix-потоков |
| `SAFE_SCREEN_TRANSITION_SECONDS` | длительность плавного перехода |

## Тесты

```bash
swift test
swift build -c release
```

Перед релизом также полезно проверить:

```bash
bash ./scripts/build_dmg.sh
hdiutil verify dist/Safe-Screen-*.dmg
```

## Версионирование

Проект использует SemVer-подход для пользовательской версии:

```text
MAJOR.MINOR.PATCH
```

Текущая версия приложения хранится в `Resources/Info.plist`:

- `CFBundleShortVersionString` - публичная версия, например `0.2.6`;
- `CFBundleVersion` - build number, например `9`.

GitHub Release создается по tag вида:

```text
v0.2.6
```

Подробные правила описаны в [docs/VERSIONING.md](docs/VERSIONING.md).

## GitHub Release

Чтобы выпустить новый DMG:

1. Обновите версию в `Resources/Info.plist`.
2. Обновите `CHANGELOG.md`.
3. Прогоните тесты и локальную сборку DMG.
4. Создайте и отправьте tag:

```bash
git tag v0.2.6
git push origin v0.2.6
```

Workflow `.github/workflows/release.yml` сам:

- запускает `swift test`;
- собирает `dist/Safe-Screen-<version>.dmg`;
- загружает DMG как workflow artifact;
- создает GitHub Release;
- прикрепляет DMG к релизу.

## Структура проекта

```text
Sources/SafeScreenApp/       macOS AppKit application
Sources/SafeScreenCore/      deterministic Matrix animation model
Tests/                       unit tests
Resources/Info.plist         bundle metadata and version
docs/                        project documentation
scripts/build_app.sh         .app build script
scripts/install_app.sh       install to /Applications
scripts/build_dmg.sh         release DMG build script
scripts/generate_icon.swift  app icon generator
.github/workflows/release.yml GitHub Release automation
```

## Документация

- [CHANGELOG.md](CHANGELOG.md) - история версий.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - архитектура: модули, поток данных, design rationale.
- [docs/VERSIONING.md](docs/VERSIONING.md) - правила версионирования и релизов.
