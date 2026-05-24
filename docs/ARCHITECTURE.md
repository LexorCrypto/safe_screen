# Архитектура

Этот документ описывает, как устроен Safe Screen внутри: из каких модулей он
состоит, как данные идут от обнаружения простоя до отрисовки overlay, и почему
анимационное ядро отделено от слоя AppKit.

## Обзор

Safe Screen собирается из двух SwiftPM-таргетов (`Package.swift`):

| Таргет | Тип | Зависимости | Назначение |
| --- | --- | --- | --- |
| `SafeScreenCore` | library | только `Foundation` | детерминированная модель Matrix-анимации |
| `SafeScreenApp` | executable | `SafeScreenCore`, `AppKit` | macOS-приложение: idle-мониторинг, overlay, UI |

Граница между ними намеренная: `SafeScreenCore` не знает про AppKit, экраны,
таймеры и системное время. Это набор чистых функций над value-типами.
`SafeScreenApp` поставляет реальный мир (время, дисплеи, поверхность рисования)
и вызывает ядро.

```text
                    SafeScreenApp  (AppKit, @MainActor)
  ┌──────────────────────────────────────────────────────────────┐
  │  main.swift → AppDelegate (composition root)                  │
  │                                                               │
  │  IdleMonitor ──onIdleThresholdReached──▶ OverlayController     │
  │      │                                       │                │
  │  CGEventSource                         SafeScreenWindow ×N     │
  │  (секунды простоя)                           │                │
  │                                          MatrixView (30 fps)   │
  │  ControlWindowController                     │                │
  │  MainMenuController        ──show(.manual)──▶ │                │
  │  StatusMenuController                        │                │
  └──────────────────────────────────────────────┼────────────────┘
                                                  │ renderLayers(elapsed, size)
                    SafeScreenCore  (Foundation)  ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  MatrixAnimationModel ── layout(for:in:) ──▶ SeededGenerator   │
  │         │                                                     │
  │  MatrixCanvasSize / MatrixStream / MatrixLayout / RenderLayer  │
  │  SafeScreenConfiguration                                       │
  └──────────────────────────────────────────────────────────────┘
```

## SafeScreenCore

Чистое ядро. Все типы — value-типы, `Equatable` и `Sendable`. Нет глобального
состояния, нет обращений к часам или AppKit. Время всегда приходит явным
параметром.

| Файл | Что внутри |
| --- | --- |
| `SafeScreenConfiguration.swift` | параметры поведения и их нормализация |
| `SeededGenerator.swift` | детерминированный ГПСЧ (SplitMix64-стиль) |
| `MatrixGeometry.swift` | value-типы: canvas size, stream, layout, render layer |
| `MatrixAnimationModel.swift` | модель анимации: время + размер → слои для отрисовки |

### SafeScreenConfiguration

Хранит параметры поведения. Дефолты:

| Поле | Значение | Смысл |
| --- | --- | --- |
| `idleThreshold` | `60` | секунд простоя до автовключения |
| `layoutChangeInterval` | `20` | секунд между сменами расположения потоков |
| `transitionDuration` | `4` | длительность плавного перехода |
| `streamCount` | `5` | количество вертикальных Matrix-потоков |
| `minimumColumnInset` | `28` | минимальный горизонтальный отступ потока от края |

Свойство `normalized` приводит значения в безопасный диапазон: интервалы не
меньше `1`, `transitionDuration` зажимается в `0.1...layoutChangeInterval * 0.75`
(переход всегда успевает завершиться до следующей ротации), `streamCount` не
меньше `1`. Ядро вызывает `normalized` само, поэтому некорректный конфиг не
ломает анимацию.

### SeededGenerator

`RandomNumberGenerator` на основе SplitMix64. Из одного и того же seed всегда
получается одна и та же последовательность. Это то, что делает раскладку
потоков воспроизводимой и тестируемой.

### MatrixAnimationModel

Сердце ядра. Две функции:

- `layout(for:in:)` — для номера поколения (`generation`) и размера холста
  детерминированно строит `MatrixLayout`: набор `MatrixStream` со
  случайными, но воспроизводимыми позицией `x`, скоростью, фазой, размером и
  числом глифов. Каждое поколение получает свой seed
  (`seed ^ generation ...`), поэтому раскладки разные, но повторяемые. Холст
  делится на `streamCount` вертикальных «корзин», по одному потоку в каждой —
  потоки не накладываются.

- `renderLayers(elapsedTime:canvasSize:)` — главный вход для слоя отрисовки.
  Считает `generation = floor(elapsed / layoutChangeInterval)`. Если время
  попадает внутрь окна перехода (`transitionDuration` в начале поколения),
  возвращает **два** `MatrixRenderLayer` — уходящую и приходящую раскладки с
  противоположными `opacity` и `verticalOffset` (crossfade + slide). Иначе
  возвращает **один** слой. Прогресс перехода сглаживается функцией
  smoothstep (`3x² − 2x³`).

Никаких таймеров и состояния: тот же `elapsedTime` всегда даёт тот же
результат.

## SafeScreenApp

Слой AppKit. Все типы помечены `@MainActor`. Здесь живут таймеры, окна,
системные события и UI.

### Composition root

`main.swift` создаёт `NSApplication`, ставит `AppDelegate` и
activation policy `.regular` (обычное приложение с Dock-иконкой, не
menu-bar-only).

`AppDelegate.applicationDidFinishLaunching` — единственное место, где
собираются все компоненты и связываются замыканиями. Зависимости передаются
через инициализаторы, общих синглтонов нет.

### Компоненты

| Файл | Роль |
| --- | --- |
| `AppConfiguration.swift` | читает env-переменные `SAFE_SCREEN_*` поверх дефолтов `SafeScreenConfiguration` |
| `SettingsStore.swift` | `protectionEnabled` в `UserDefaults` (по умолчанию `true`) |
| `LoginItemController.swift` | автозапуск через `SMAppService.mainApp` |
| `IdleMonitor.swift` | таймер простоя, читает системный idle |
| `CGEventType+SafeScreen.swift` | sentinel-тип события «любой ввод» |
| `OverlayController.swift` | показ/скрытие overlay, мониторы ввода, логика выключения |
| `SafeScreenWindow.swift` | borderless-окно overlay на уровне screen saver |
| `MatrixView.swift` | `NSView`, рисует слои из `MatrixAnimationModel` на 30 fps |
| `ControlWindowController.swift` | окно управления |
| `MainMenuController.swift` | верхнее меню macOS `Safe Screen` |
| `StatusMenuController.swift` | menu-bar item `Safe` и его меню |
| `UpdateController.swift` | ручная проверка GitHub Releases, сравнение версий и загрузка DMG в Downloads |
| `StatusIcon.swift` | рисует иконку (зелёные столбики) |

### Обнаружение простоя

`IdleMonitor` запускает повторяющийся `Timer` с интервалом `1` секунда. На
каждом тике:

1. Пропускает тик, если защита выключена (`SettingsStore.protectionEnabled`)
   или overlay уже активен.
2. Спрашивает системное время простоя через
   `CGEventSource.secondsSinceLastEventType`.
3. Если простой `>= idleThreshold`, вызывает `onIdleThresholdReached`.

«Любой ввод» закодирован как `CGEventType.safeScreenAnyInput` —
`CGEventType(rawValue: UInt32.max)`. Это sentinel, который заставляет
CoreGraphics вернуть время с момента последнего HID-события любого типа
(клавиатура, мышь, трекпад).

## Поток данных: автоматическое включение

```text
Timer (1 s)
  └─ IdleMonitor.tick
       └─ простой >= idleThreshold ?
            └─ onIdleThresholdReached()            (связано в AppDelegate)
                 └─ OverlayController.show(.idle)
                      ├─ создаёт один MatrixAnimationModel
                      ├─ на каждый NSScreen: SafeScreenWindow + MatrixView
                      ├─ MatrixView.start() → Timer 30 fps
                      └─ installInputMonitors()
```

`MatrixView` на каждом кадре берёт `systemUptime - startTime`, вызывает
`model.renderLayers(elapsedTime:canvasSize:)` и рисует получившиеся слои:
падающие глифы, голова потока ярче хвоста, во время перехода — два
crossfade-слоя.

## Поток данных: ручная активация

Кнопка `Активировать сейчас` в окне управления, пункт меню приложения или
пункт menu-bar item вызывают `OverlayController.show(reason: .manual)`.

Отличие от `.idle`: для ручного запуска ставится grace-период `1.25` секунды
(`dismissalInputGraceUntil`). Стартовый клик и связанные с ним события в этом
окне не считаются «выключающим вводом», иначе overlay исчезал бы сразу после
нажатия кнопки.

## Поток данных: выключение overlay

`OverlayController` ставит два монитора `NSEvent`:

- **локальный** — события внутри приложения: нажатия кнопок мыши, движение
  мыши, drag, scroll, `keyDown`;
- **глобальный** — тот же набор, но **без** `mouseMoved`.

Событие выключает overlay (`hide()`) только если `shouldDismiss` вернёт `true`:

- идёт grace-период ручной активации → игнорируем;
- `mouseMoved` → считаем выключающим только если курсор сместился достаточно
  далеко от точки активации (порог квадрата расстояния `64`, ≈ `8` точек);
- клик, drag, scroll, `keyDown` → выключают сразу.

Так фоновые `mouseMoved`-события удалённой сессии (которые приходят без
реального участия человека) не гасят Safe Screen — нужен явный ввод.

При `hide()` мониторы снимаются, окна закрываются, фокус возвращается
приложению, которое было активным до показа overlay.

## Окна и уровни

| Окно | Класс | Уровень | Поведение |
| --- | --- | --- | --- |
| Overlay | `SafeScreenWindow` | `.screenSaver` | borderless, чёрное, по одному на каждый `NSScreen`, на всех Spaces |
| Управление | `NSWindow` в `ControlWindowController` | `.floating` | titled, закрываемое; закрытие прячет окно, а не завершает приложение |

`applicationShouldTerminateAfterLastWindowClosed` возвращает `false`:
после закрытия окна управления приложение продолжает работать в фоне.
Окно открывается снова через Dock, меню `Safe Screen` или menu-bar item
`Safe` (`applicationShouldHandleReopen`, `showControlPanel`).

## Потоки и состояние

- Весь `SafeScreenApp` — `@MainActor`. Таймеры, события и UI выполняются на
  главном потоке.
- `SafeScreenCore` — `Sendable` value-типы без изменяемого глобального
  состояния.
- Постоянное состояние минимально: `protectionEnabled` в `UserDefaults` и
  статус автозапуска в `SMAppService`. Между запусками больше ничего не
  хранится.

## Тесты

Тестируется `SafeScreenCore` — именно потому, что он детерминирован и не
зависит от AppKit. `Tests/SafeScreenCoreTests/MatrixAnimationModelTests.swift`
проверяет:

- дефолтный конфиг совпадает с продуктовым планом (`60` / `20` / `5`);
- сгенерированные потоки не выходят за пределы холста;
- раскладка меняется после `layoutChangeInterval`;
- во время перехода возвращаются два слоя и их `opacity` в сумме дают `1`;
- после `transitionDuration` остаётся один слой.

Слой AppKit (`SafeScreenApp`) намеренно тонкий: он переносит время и размеры
в ядро и рисует результат, поэтому отдельных unit-тестов для него нет.

## Почему ядро отделено от AppKit

Анимация Matrix — это математика: где потоки, с какой скоростью падают, как
два поколения смешиваются во время перехода. Если эта математика живёт внутри
`NSView` и зависит от системных часов, её нельзя проверить, не запустив
отрисовку.

`SafeScreenCore` выносит всю математику в чистые функции. Время — это
параметр, не `Date()`. Случайность — это seed, не `arc4random`. Из этого
следует:

- поведение проверяется точно: «на `19.9` с поколение `0`, на `20.1` с —
  поколение `1`» — это обычное равенство в тесте;
- одинаковый ввод всегда даёт одинаковый вывод — никаких флака от таймингов;
- слой AppKit остаётся тонким и скучным: получить время и размер экрана,
  позвать `renderLayers`, нарисовать слои.

Граница проходит ровно там, где заканчивается детерминированная логика и
начинается работа с системой.

## Карта файлов

```text
Package.swift                              описание двух таргетов SwiftPM
Resources/Info.plist                       метаданные бандла и версия

Sources/SafeScreenCore/                    детерминированное ядро
  SafeScreenConfiguration.swift            параметры поведения + нормализация
  SeededGenerator.swift                    детерминированный ГПСЧ
  MatrixGeometry.swift                     value-типы геометрии анимации
  MatrixAnimationModel.swift               модель: время + размер → слои

Sources/SafeScreenApp/                     приложение AppKit
  main.swift                               точка входа, NSApplication
  AppDelegate.swift                        composition root
  AppConfiguration.swift                   env-переменные → конфиг
  SettingsStore.swift                      состояние защиты в UserDefaults
  LoginItemController.swift                автозапуск через SMAppService
  IdleMonitor.swift                        таймер простоя
  CGEventType+SafeScreen.swift             sentinel «любой ввод»
  OverlayController.swift                  показ/скрытие overlay, ввод
  SafeScreenWindow.swift                   окно overlay
  MatrixView.swift                         отрисовка слоёв на 30 fps
  ControlWindowController.swift            окно управления
  MainMenuController.swift                 верхнее меню macOS
  StatusMenuController.swift               menu-bar item Safe
  UpdateController.swift                   GitHub Releases → DMG в Downloads
  StatusIcon.swift                         иконка приложения

Tests/SafeScreenCoreTests/                 unit-тесты ядра
```
