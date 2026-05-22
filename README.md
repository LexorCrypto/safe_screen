# Safe Screen

Safe Screen is a native macOS menu-bar app that protects an OLED screen from a static desktop while a MacBook is connected to power and used remotely.

After 5 minutes of local input inactivity, it opens black full-screen overlay windows on all displays and renders five low-brightness Matrix-style vertical streams. Every 20 seconds the streams move to new random screen positions through a smooth crossfade/slide transition.

## Build

```bash
./scripts/build_app.sh
```

The app bundle is created at:

```text
build/Safe Screen.app
```

## Run

```bash
open "build/Safe Screen.app"
```

Safe Screen appears only in the menu bar. From the menu you can:

- activate the screen manually with `Activate Now`;
- turn protection on or off;
- enable `Open at Login`;
- quit the app.

## Debug Timing

For quick local checks without waiting 5 minutes:

```bash
SAFE_SCREEN_IDLE_SECONDS=5 SAFE_SCREEN_LAYOUT_SECONDS=4 SAFE_SCREEN_TRANSITION_SECONDS=1 swift run SafeScreenApp
```

The production defaults are:

- idle threshold: `300s`;
- stream position rotation: `20s`;
- smooth transition duration: `4s`;
- stream count: `5`.

## Tests

```bash
swift test
swift build -c release
```
