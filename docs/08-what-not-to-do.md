# 08 — What not to do

The most useful page in this repo. Every row below is a tweak that circulates widely, is applied by thousands of
people, and either does nothing or makes things worse.

They are grouped by *how* they fail.

---

## Class 1 — The pref no longer exists

Firefox will happily store a pref that no code reads. No error, no warning, no effect. These were real, once.

| Pref | Why it's dead |
|---|---|
| `gfx.webrender.all` | WebRender became the only Windows compositor; there is nothing to "enable" |
| `layers.acceleration.force-enabled` | belonged to the Layers compositor, replaced by WebRender |
| `layers.acceleration.draw-fps` *(except the overlay)* | still exists — but as a measurement tool, not a speed-up; don't leave it on |
| `dom.ipc.processCount.extension` | pre-Fission. Extensions already run isolated |
| `browser.tabs.remote.autostart` | multiprocess is mandatory since Fission |
| `gfx.content.azure.backends` | the Azure canvas backend was removed (now Skia/WebRender) |
| `browser.ping-centre.telemetry` | the Ping Centre component was removed years ago |
| `image.mem.decode_on_draw` | not present in current builds; image decoding is handled elsewhere |

**Pattern:** nearly every "Firefox speed" list on the internet was written between 2016 and 2019 and copied
forward. The prefs were correct then. Firefox is now a different engine.

---

## Class 2 — Backwards: it does the opposite of the claim

| Claim | Reality |
|---|---|
| `browser.startup.preXULSkeletonUI = false` "speeds up launch" | That pref *enables* the Windows skeleton window, which draws a cheap frame while the real UI loads. Turning it off makes launch feel **slower**, because there's no early paint. **Keep it `true`.** |
| `media.ffvpx.enabled = false` "forces GPU decoding" | It disables Firefox's bundled FFmpeg decoders for VP8/VP9/AV1 and some audio. On Windows, VP9 doesn't route through the OS decoder in the general case, so you mostly lose your fallback path — you do not gain hardware decode. **Leave it `true`.** |
| `layout.frame_rate = 360` "matches your monitor" | `-1` already means "follow the display". Pinning an integer takes the compositor off the vsync/VRR path, which produces judder and tearing on high-refresh panels — and caps you at whatever number you typed. **Leave it `-1`.** |
| "Disable all animations to speed up rendering" | CSS animations run on the compositor; they cost the GPU almost nothing. Killing them changes *feel*, not frame budget. Fine as a taste choice — dishonest as a performance claim. |

The skeleton-UI one is the giveaway that a list was generated rather than tested: it reads as "disable early
paint to start faster", which isn't a thing.

---

## Class 3 — Real pref, wrong value for your machine

| Advice | Problem here |
|---|---|
| `dom.ipc.processCount = 16` (or "as high as possible") | 16 GB RAM. More content processes means more resident memory, more tab reloads, and swap. 12 is the ceiling on 16 GB. |
| `gfx.canvas.accelerated.cache-size = 4096` (MB) | That's 4 GB of VRAM reserved for canvas on an 8 GB card — it starves textures and video decode. 512 is the sane ceiling. |
| `mousewheel.min_line_scroll_amount = 30` as a universal truth | Taste, and panel-dependent. On a 60 Hz panel it feels twitchy. Keep it, but know what it is. |
| "Set every smooth-scroll value to the maximum" | `durationMaxMS = 0` removes smoothing entirely; `currentVelocityWeighting = 1` makes it feel laggy. These values interact. |
| "Turn off `gfx.direct2d.disabled` / force everything on" | Forcing acceleration past the blocklist is how you get green video and GPU-process crashes. |

---

## Class 4 — Category errors (not prefs at all)

| Advice | Why it's wrong |
|---|---|
| Registry "gaming tweaks" for browser smoothness | Nothing in `HKLM`/`HKCU` changes Firefox's frame pacing. At best neutral. |
| Disabling Windows Defender real-time scanning "for speed" | Measurably slower page loads in practice, and a security hole. |
| "RAM cleaners" / "memory optimisers" | They force working sets out to the pagefile; the next page load has to read them back. Slower, not faster. |
| Clearing the cache on a schedule | Every cleared cache is a cold cache. The disk cache exists to make repeat loads fast. |
| Disabling Superfetch/SysMain | That's the prefetcher that makes app launch fast. |
| Installing a "gaming booster" that kills background processes | It kills the ones Windows needs, including the compositor helpers. |
| "Smooth scrolling" extensions | They reimplement scrolling in JS, outside APZ. Always worse than native. See [06](06-extensions.md). |

---

## Class 5 — The CSS that never existed

```css
:root { --animation-speed: 50ms !important; }
```

No such variable in Firefox. The snippet works because of the rules next to it, not this one. Similar fossils:
`#nav-bar[collapsed="true"]`, `-moz-os-version: windows-*` selectors, `@namespace url(...)` wrappers.

---

## Why these lists fail

1. **They are copied, not measured.** Nobody A/B'd them; they were true on someone's 2019 build.
2. **They optimize the wrong layer.** Browsers are GPU-composited now. Pref tweaks that mattered when rendering
   was single-threaded CPU work no longer move anything.
3. **They ignore the actual bottleneck.** On a hybrid-graphics laptop, the panel refresh rate and the GPU choice
   account for most of the difference. Prefs are rounding error.
4. **They look authoritative.** A table with 16 rows and no sources is indistinguishable from a tested list —
   until you check whether the prefs still exist.

That's why this repo has a [measuring page](07-measuring.md) and a revert page. A tweak you can't measure and
can't undo is a rumour.

---

## Appendix: a real generated user.js, audited

This is a `user.js` that turned up in a Firefox beta profile — ten prefs, four comments, no
source. It is labelled Betterfox; Betterfox is 700+ lines maintained by someone who tracks Mozilla's changes.
This is a ten-line imitation of it.

```js
// BETTERFOX SPEED & SMOOTHNESS PROFILE
user_pref("browser.startup.preXULSkeletonUI", false);            // Speed up launch sequence
user_pref("content.notify.interval", 100000);                    // Optimize rendering intervals
user_pref("gfx.canvas.accelerated.cache-size", 4096);             // Boost GPU canvas cache for RTX 4060
user_pref("gfx.content.azure.backends", "direct2d,skia,cairo");   // Force fast Windows rendering

// PREVENT CPU TRASH & BACKGROUND LAG
user_pref("browser.tabs.remote.autostart", true);
user_pref("browser.ping-centre.telemetry", false);               // Stop background reporting junk
user_pref("toolkit.telemetry.unified", false);                   // Kill telemetry CPU cycles
user_pref("toolkit.telemetry.enabled", false);
user_pref("experiments.supported", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
```

Line by line:

| # | Pref | Verdict | Why |
|---|------|---------|-----|
| 2 | `browser.startup.preXULSkeletonUI = false` | ❌ **backwards** | disables the skeleton window, so launch feels slower |
| 3 | `content.notify.interval = 100000` | ⚪ noise | default is 120000; reflow batching in microseconds |
| 4 | `gfx.canvas.accelerated.cache-size = 4096` | ❌ **harmful value** | it is megabytes: 4 GB of VRAM on an 8 GB card |
| 5 | `gfx.content.azure.backends = "direct2d,skia,cairo"` | 💀 dead | the Azure backend was removed; the string is never read |
| 8 | `browser.tabs.remote.autostart = true` | 💀 dead | multiprocess is mandatory, and this was already the default |
| 9 | `browser.ping-centre.telemetry = false` | 💀 dead | that component was removed years ago |
| 10 | `toolkit.telemetry.unified = false` | ✅ fine | |
| 11 | `toolkit.telemetry.enabled = false` | ✅ fine | |
| 12 | `experiments.supported = false` | ⚪ near-no-op | the pref exists; studies off; no frame effect |
| 13 | `datareporting.healthreport.uploadEnabled = false` | ✅ fine | |

**Score: 10 prefs → 3 dead, 1 backwards, 1 harmful, 2 noise, 3 useful.**

And the stylesheet that came with it:

| Rule | Verdict |
|---|---|
| `--animation-speed: 50ms` | 💀 no such variable in Firefox |
| `--panel-transition-duration: 0ms` | 💀 no such variable (the real one is `--panelui-subview-transition-duration`) |
| `menupopup, panel { animation-duration: 0s }` | ✅ works |
| `#titlebar { will-change: auto }` | ✅ works, marginal |

So the "optimisation" was: one setting that made things slower, one that over-allocated VRAM, five that did
nothing at all, and two CSS rules naming variables that have never existed. It still felt faster — because the
same session also set the GPU preference and the refresh rate, which is where the gain actually came from.

That is the whole argument of this repo: **the win was in four system settings, and the pref list took the
credit.**

---

## The short version

Things that genuinely helped: refresh rate, GPU choice, driver present method, extension diet,
12 content processes, and a handful of paint/scroll prefs.

Everything else in the list I started from was either dead, backwards, or noise.
