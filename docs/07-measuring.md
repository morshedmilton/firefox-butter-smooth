# 07 — Measuring instead of guessing

Without this page you are tuning by vibes, and every placebo will feel like a win. With it, you can tell the
difference in ten minutes.

---

## 7.1 The on-screen frame counter

`about:config` → `layers.acceleration.draw-fps` → `true`.

A small green overlay appears in a corner of the content area while scrolling/compositing:

```
FPS 163  ...
```

- It reads the **compositor's** frame rate, not the page's animation rate. That's exactly what you want: it's the
  number that corresponds to "does this feel smooth".
- Related: `layers.acceleration.draw-fps.print-period` (seconds between updates, default 1).
- **Turn it off when you're done.** It costs a little, and it is drawn on top of everything including video.

**How to read it:** ignore the peak. Watch whether it *sits at* your panel rate and whether it drops in the
same place every time. A drop on one site is a page problem. Constant 60 on a high-refresh panel is a
configuration problem — go back to [01](01-windows-and-driver.md).

---

## 7.2 `about:support` → Graphics

The ground truth for "am I actually on the GPU". Check before and after step 2:

| Field | Before | After |
|---|---|---|
| `Compositing` | `WebRender` | `WebRender` |
| `GPU #1` | the iGPU | the dGPU |
| `Vendor ID` | `0x8086` (Intel) | `0x10de` (NVIDIA) |
| `WebRender` | `true` | `true` |

If `Compositing` says `WebRender (Software)`, stop tuning and fix that first — [09](09-troubleshooting.md).

---

## 7.3 `about:processes`

Everything Firefox is running, one row per process: **CPU %**, **memory**, **IPC calls**.

- Sort by CPU while the page feels slow. Usually one tab, sometimes an extension, sometimes the GPU process.
- Sort by memory after a long session. If content processes total near your RAM ceiling, drop the process limit
  in [02](02-firefox-performance-settings.md).
- A permanently busy GPU process at idle is a driver problem, not a Firefox problem.

---

## 7.4 The Firefox Profiler — the actual instrument

[profiler.firefox.com](https://profiler.firefox.com) is built into Firefox (`Ctrl + Shift + I` → Performance
tab, or the `about:profiling` page).

**A 10-minute protocol:**

1. Open the page that feels bad. Scroll it once to warm caches.
2. Start recording, scroll the same way for 10 seconds, stop.
3. In the profile, find the **Compositor** track and the **Frame** markers.
4. Look for:
   - **long Frame markers** — the compositor missed its budget
   - **`VsyncObserver` gaps** — dropped frames, not slow frames
   - **Style/layout stacks during scroll** — the page, not the browser
   - **Long tasks attributed to an extension's URL** — that's your culprit
5. Compare two recordings (before/after a change) rather than eyeballing one.

The profiler is the only tool here that tells you *why*, and it's free.

---

## 7.5 An A/B protocol that is worth the effort

Smoothness comparisons are destroyed by noise (background Windows tasks, thermal state, a tab reloading).

1. **Same conditions:** plugged in, thermal mode fixed, no other apps, 10 minutes after boot.
2. **Same page, same scroll:** a long article or a heavy dashboard, scrolled top-to-bottom at a steady speed.
3. **Three runs each side**, alternating A/B/A/B — not five A's then five B's (thermal drift will fake a result).
4. Record: median FPS from the overlay, worst drop, and whether the profiler shows missed frames.
5. Change **one** thing.

If a change does not survive that, it is not a change. That's how the twelve prefs in [03](03-about-config.md)
were chosen and the eight in [08](08-what-not-to-do.md) were rejected.

---

## 7.6 Battery, if you care what the dGPU profile costs

```powershell
powercfg /batteryreport /output "$env:USERPROFILE\battery.html"
```

Gives design capacity, current capacity, and estimated life. Compare a normal 30-minute browsing session on the
plugged-in profile vs the battery profile.

Rough expectation: forcing the dGPU for a browser costs a visible chunk of battery — its
idle floor is simply higher than the iGPU's. That's the trade, and it's why the README has two profiles instead
of one "best" list.

---

## 7.7 What you cannot measure (and should stop trying to)

- **"Responsiveness" after a single pref.** Below ~10 ms it is inside the noise.
- **Startup time after adding CSS.** You can see it in `about:support` → Startup, but only above a few hundred KB
  of stylesheet.
- **Perceived latency.** The profiler says 6 ms; your hands say "sluggish". Trust your hands *after* the profiler
  rules out the obvious — but never let a number overrule a real stutter you can reproduce.
