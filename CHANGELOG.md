# Changelog

Все заметные изменения Safe Screen фиксируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), версии следуют SemVer-подходу.

## [Unreleased]

### Added

- Расширенная проектная документация в `README.md`.
- Документ `docs/ARCHITECTURE.md` с описанием модулей, потока данных и design rationale.
- Отдельный документ `docs/VERSIONING.md` с правилами версионирования и релизов.
- Этот `CHANGELOG.md` для истории изменений.

## [0.2.6] - 2026-05-22

### Added

- GitHub Release `v0.2.6` с DMG-asset `Safe-Screen-0.2.6.dmg`.
- Workflow `.github/workflows/release.yml` для автоматической сборки DMG на tag `v*`.
- Скрипт `scripts/build_dmg.sh` для локальной сборки релизного DMG.

### Changed

- Автовключение Safe Screen изменено на `60` секунд локальной неактивности.

## [0.2.5] - 2026-05-22

### Changed

- Автовключение временно было переведено на `20` секунд локальной неактивности.
- Overlay стал выключаться только от явного пользовательского ввода.

### Fixed

- Убрано самопроизвольное выключение overlay из-за polling-таймера.
- Глобальные фоновые `mouseMoved`-события удаленной сессии больше не выключают Safe Screen.

## [0.2.1] - 2026-05-22

### Fixed

- Исправлено поведение `Активировать сейчас`, когда overlay исчезал почти сразу после нажатия кнопки.
- Добавлен короткий grace period для ручной активации, чтобы стартовый клик не считался действием для скрытия Safe Screen.

## [0.2.0] - 2026-05-22

### Changed

- Приложение переведено из скрытого menu-bar-only режима в обычное macOS app с Dock icon.
- Удален `LSUIElement` из `Info.plist`.
- Добавлен явный `main.swift`, который создает `NSApplication`, назначает `AppDelegate` и запускает event loop.

### Added

- Главное меню приложения `Safe Screen`.
- Видимое окно управления при запуске.

### Fixed

- Исправлен сценарий, когда приложение запускалось как процесс, но не показывало окно и меню.

## [0.1.0] - 2026-05-22

### Added

- Первый рабочий Swift/AppKit прототип Safe Screen.
- Idle detection через CoreGraphics.
- Полноэкранные overlay-окна на всех дисплеях.
- Matrix-анимация с 5 вертикальными потоками.
- Плавная смена позиций потоков каждые 20 секунд.
- Menu-bar item `Safe`.
- Сборка `.app` через `scripts/build_app.sh`.
- Установка в `/Applications` через `scripts/install_app.sh`.
- Unit tests для deterministic Matrix animation model.

[Unreleased]: https://github.com/LexorCrypto/safe_screen/compare/v0.2.6...HEAD
[0.2.6]: https://github.com/LexorCrypto/safe_screen/releases/tag/v0.2.6
[0.2.5]: https://github.com/LexorCrypto/safe_screen/compare/b9964e4...56b7fd6
[0.2.1]: https://github.com/LexorCrypto/safe_screen/commit/b9964e4
[0.2.0]: https://github.com/LexorCrypto/safe_screen/commit/3102edc
[0.1.0]: https://github.com/LexorCrypto/safe_screen/commit/5fd2827
