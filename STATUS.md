# Статус проекта

Снимок текущего состояния Safe Screen и план дальнейших работ.

- **Дата:** 2026-05-22
- **Версия:** 0.2.6 (build 9)
- **Ветка:** `main`
- **Репозиторий:** https://github.com/LexorCrypto/safe_screen

## Текущее состояние

Safe Screen — рабочее нативное macOS-приложение (Swift / AppKit) для защиты
OLED-экрана MacBook Pro от статичной картинки. Приложение собирается,
подписывается ad-hoc подписью и распространяется через GitHub Releases в виде
DMG.

Кодовая база разделена на два SwiftPM-таргета:

- `SafeScreenCore` — детерминированная модель Matrix-анимации, покрыта unit-тестами;
- `SafeScreenApp` — слой AppKit: idle-мониторинг, overlay, окно управления, menu-bar.

Подробности — в [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Структурные изменения

### Документация

- Добавлен `docs/ARCHITECTURE.md`: модули `SafeScreenCore` / `SafeScreenApp`,
  поток данных (idle → overlay, ручная активация, выключение overlay), оконные
  уровни, потоки и состояние, design rationale, карта файлов.
- `README.md` и `CHANGELOG.md` обновлены под актуальное состояние проекта.

### Версионирование — единый источник правды

- Добавлен файл `VERSION` в корне репозитория — единственный источник публичной
  версии в формате `MAJOR.MINOR.PATCH`.
- Добавлен скрипт `scripts/set_version.sh <version>`: записывает `VERSION`,
  зеркалит `CFBundleShortVersionString` в `Info.plist`, инкрементит build number
  `CFBundleVersion`.
- `scripts/build_app.sh` проставляет версию в собираемый бандл прямо из `VERSION`.
- `scripts/build_dmg.sh` берёт имя DMG из `VERSION`.
- `.github/workflows/release.yml` падает, если релизный tag не совпадает с
  файлом `VERSION`.
- Правила описаны в [docs/VERSIONING.md](docs/VERSIONING.md).

### Сборка

- `scripts/build_app.sh` повторяет `codesign` (до 3 попыток) — защита от гонки с
  FileProvider-демоном, который возвращает `com.apple.FinderInfo` xattrs во время
  подписи бандла.
- `scripts/build_dmg.sh` чистит xattrs и переподписывает бандл в staging-папке
  (`$TMPDIR`, вне зоны FileProvider) — DMG получает детерминированно чистую
  подпись независимо от состояния `build/`.

## Будущие наработки

- **Developer ID signing + notarization.** Сейчас сборка подписана ad-hoc
  подписью, DMG не notarized — при первом запуске macOS показывает предупреждение
  Gatekeeper. Для публичного распространения за пределами личного использования
  нужны Developer ID и notarization.
- **UI-настройка таймера простоя.** Порог автовключения (`60s`) зашит в конфиг и
  переопределяется только через env-переменные. Стоит вынести в окно управления.
- **Тесты для слоя `SafeScreenApp`.** Unit-тестами покрыт только `SafeScreenCore`.
  Слой AppKit (idle-мониторинг, логика выключения overlay, grace-период ручной
  активации) пока не тестируется.
- **Дорога к 1.0.0.** Первый стабильный публичный релиз с зафиксированным
  поведением — после notarization и стабилизации UI.

## Известные ограничения и контекст

- Репозиторий лежит в синхронизируемой папке `~/Documents` (FileProvider). Демон
  периодически возвращает `com.apple.FinderInfo` xattrs на собранный бандл.
  Сборочные скрипты с этим справляются (retry + переподпись в staging), но при
  переносе репозитория за пределы синхронизируемой папки этот класс проблем
  исчезнет полностью.
- `origin` использует SSH (`git@github.com:LexorCrypto/safe_screen.git`): HTTPS-токен
  не имеет scope `workflow` и отклоняет push с правками `.github/workflows/`.
- DMG не notarized, подпись ad-hoc (не Developer ID).

## История

Полная история версий — в [CHANGELOG.md](CHANGELOG.md). Решения по архитектуре и
релизам — в git-логе и [docs/VERSIONING.md](docs/VERSIONING.md).
