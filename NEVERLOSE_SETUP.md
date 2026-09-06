# UTG + NeverLose UI

UTG now uses the **4lpaca-pin/NeverLose** UI library API instead of the custom UI from v2.

## Studio setup

1. Open the official NeverLose repository:
   https://github.com/4lpaca-pin/NeverLose
2. Open `source.luau`.
3. Copy the full source into a Roblox **ModuleScript** named `NeverLose`.
4. Put that ModuleScript beside `UTG.lua` under `StarterPlayer > StarterPlayerScripts` (or adapt the parent location if you prefer).
5. Run the experience.

`UTG.lua` calls:

```lua
local NeverLose = require(script:WaitForChild("NeverLose"))
```

and uses the library's documented window, tab, section, toggle, slider, dropdown, keybind, watermark, notification, and configuration APIs.

## UTG features wired into the library

- Mobile-sized NeverLose window
- Draggable floating `U` launcher button
- Tap launcher to show/hide the menu
- RightShift desktop menu keybind
- Home / Player / Visuals tabs
- Speed + configurable speed amount
- Sprint + configurable sprint speed
- High jump + configurable jump power
- Local noclip testing for your own experience
- Fullbright
- FPS + ping watermark
- Menu scale selector
- Accent selector
- Optional 3D menu setting
- Respawn-safe character handling

The NeverLose project is MIT licensed. Check its repository/license for the upstream license terms.
