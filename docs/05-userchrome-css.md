# 05 — `userChrome.css`: snappy menus, no magic

## What it can do

`userChrome.css` styles the browser's own UI — the chrome, hence the name. It is the only supported-ish way to
change how menus, tabs and toolbars animate without an extension.

It cannot make pages render faster. It changes the browser's interface, not the page engine.

---

## Enabling it (two steps, both required)

1. `about:config` → `toolkit.legacyUserProfileCustomizations.stylesheets` → `true`
2. Put the file at:

```
<profile>/chrome/userChrome.css
```

`about:support` → **Profile Folder → Open Folder** → create `chrome` if missing. Restart Firefox completely —
a new window is not enough.

If nothing changes, the pref from step 1 is missing. Firefox reads the file only when that switch is on, and
gives no warning when it isn't.

---

## What actually works

[`chrome/userChrome.css`](../chrome/userChrome.css) in this repo does four things:

| Rule | Effect |
|---|---|
| `--panelui-subview-transition-duration: 0ms` | the hamburger menu opens without the 200 ms slide |
| `menupopup, panel { animation-duration: 0ms }` | context menus appear on the same frame as the click |
| `.tabbrowser-tab { transition: none }` | no fade on tab open/close/move |
| `#titlebar { will-change: auto }` | stop the compositor reserving a layer for the titlebar |

All four are real, current variables in Firefox. That matters, because most snippets you'll find are not.

## What does not work (but circulates widely)

```css
:root { --animation-speed: 50ms !important; }
```

There is no `--animation-speed` variable in Firefox. That line — from a popular "instant UI" snippet — has never
done anything. It looks like it works because the *other* rules in the same snippet are doing the work.

Same for `-moz-os-version` selectors, `@namespace`-wrapped rules from Firefox 3 era, and anything targeting
`#nav-bar[collapsed]`, which no longer exists.

---

## Honest costs

**1. It is unsupported.** Mozilla does not test it, does not document the internals, and renames variables
whenever a UI refresh lands. When that happens your rules silently stop applying — no error, no warning, just
the old slow menus back.

**2. Every window parses it.** The stylesheet is loaded per browser window. A 20 KB file is free; the 500 KB
"ultimate Firefox theme" files people share are not. If startup got slower after you added CSS, this is why —
measure with `about:support` → **Startup** timings.

**3. It can break layout you didn't target.** Rules on `panel` or `menupopup` occasionally break popup
positioning on multi-monitor DPI-mixed setups (a 4K external next to the 1080p laptop panel). If a dropdown
starts appearing in the wrong place, delete the CSS before you blame Firefox.

**4. It survives profile refresh.** `about:support` → Refresh Firefox keeps `chrome/`, so a broken stylesheet
survives the repair that was supposed to fix things.

---

## What it will not fix

Menus that feel slow because of *rendering*, not animation:

| Symptom | Real cause | Where to look |
|---|---|---|
| Every interaction lags ~100 ms | software compositing | `about:support` → Compositing |
| Lag only at 60 Hz but not at its max | panel refresh rate | [01](01-windows-and-driver.md) |
| A panel shows empty content (extensions, bookmarks) | usually a pref, not this CSS | [09](09-troubleshooting.md#extensions-panel-is-empty) |
| Lag only with 30 tabs open | process/RAM pressure | `about:processes` |
| Lag only after waking from sleep | GPU driver after resume | [09](09-troubleshooting.md) |

Killing a 200 ms animation on the happy path does nothing if the compositor is already 8 frames behind.

---

## A minimal version, if you want to start smaller

```css
:root { --panelui-subview-transition-duration: 0ms !important; }
menupopup, panel { animation-duration: 0ms !important; }
```

Two lines, ~90% of the perceived win, nothing that can break panel positioning. Add the rest only if you
actually notice the difference.

## Undo

Delete `chrome/userChrome.css` (or run `Restore-FirefoxTune.ps1`, which renames it), restart. Optionally set
`toolkit.legacyUserProfileCustomizations.stylesheets` back to `false`.
