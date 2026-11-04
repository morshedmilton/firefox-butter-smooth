# 03 — `about:config`, with verdicts

The only `about:config` page you should trust is the one that tells you which prefs are *not* worth setting.
This is that page.

Type `about:config` in the address bar → **Accept the Risk and Continue** → search → double-click a boolean, or
click the pencil for a number/string.

**Read your current value before changing anything.** Defaults move between releases. If a pref is not in your
`about:config`, your build does not have it — skip the line, nothing is broken.

**Verdict legend**

| | Meaning |
|---|---|
| 🟢 | real effect you can measure or feel |
| 🟡 | real but small, or a matter of taste |
| 🔴 | does nothing on current builds, or does harm — see [08](08-what-not-to-do.md) |

---

## Compositing and GPU

| Pref | Default | Set to | Effect | |
|---|---|---|---|---|
| `gfx.webrender.software` | `false` | `false` | forces software rendering when `true`. The most common self-inflicted slowdown | 🟢 |
| `gfx.direct2d.disabled` | `false` | `false` | Direct2D canvas acceleration off when `true` | 🟢 |
| `layers.acceleration.disabled` | `false` | `false` | kills the GPU compositing path when `true` | 🟢 |
| `gfx.canvas.accelerated` | `true` | `true` | GPU-backed `<canvas>` | 🟢 |
| `gfx.canvas.accelerated.cache-size` | `256` | `512` | MB of VRAM reserved for canvas surfaces. Helps maps/dashboards; irrelevant on 4 GB cards | 🟡 |
| `gfx.webrender.all` | `true` | — | WebRender is the only compositor now. Setting it is a no-op | 🔴 |
| `layers.acceleration.force-enabled` | — | — | belongs to the removed Layers compositor | 🔴 |

These are not "tuning" prefs. They are the four switches that decide whether you are on the GPU at all, and
they are already correct in a healthy install. Check them with `about:support` rather than flipping them.

---

## Processes and memory

| Pref | Default | Set to | Effect | |
|---|---|---|---|---|
| `dom.ipc.processCount` | `8` | `12` | content processes. Ignored while "Use recommended performance settings" is ticked | 🟢 |
| `fission.autostart` | `true` | `true` | site isolation. Disabling is a security downgrade, not an optimisation | 🟢 |
| `browser.tabs.unloadOnLowMemory` | `true` (Windows) | `true` | collapse background tabs under memory pressure instead of swapping | 🟢 |
| `browser.sessionstore.interval` | `15000` | `60000` | how often session state hits disk, ms. Fewer writes; you lose ≤60 s of state on a hard crash | 🟡 |
| `dom.ipc.processCount.extension` | — | — | pre-Fission, and on Beta a modified value can empty the extensions panel — [09](09-troubleshooting.md#extensions-panel-is-empty) | 🔴 |
| `browser.tabs.remote.autostart` | `true` | — | multiprocess is mandatory. No-op | 🔴 |

**Process maths:** 12 processes on 20 threads is fine. On 16 GB, 12 keeps ~3 GB of content resident, leaving
room for the GPU driver, the OS and whatever you actually opened the browser to do. 16+ is where tab reloads
and swap start appearing, and tab reloads are the opposite of smooth.

---

## Paint latency

| Pref | Default | Set to | Effect | |
|---|---|---|---|---|
| `nglayout.initialpaint.delay` | `5` | `0` | ms to wait before first paint. Zero draws sooner; can show a reflow on slow pages | 🟡 |
| `nglayout.initialpaint.delay.composite` | `5` | `0` | same, for the compositor path | 🟡 |

Both are single-digit milliseconds. You will not feel them individually; they matter on a page that repaints
often. The 250 ms figure you'll see quoted everywhere is from Firefox 3-era builds.

---

## Scrolling

This is where the "as smooth as possible" lists live, and they are describing **feel**, not performance. Nothing
here renders a frame faster.

| Pref | Default | Set to | Effect | |
|---|---|---|---|---|
| `general.smoothScroll.msdPhysics.enabled` | `true` (recent) | `true` | newer physics model, closer to native | 🟡 |
| `general.smoothScroll.mouseWheel.durationMaxMS` | `400` | `300` | longest animation for one wheel notch | 🟡 |
| `general.smoothScroll.mouseWheel.durationMinMS` | `200` | `100` | shortest | 🟡 |
| `general.smoothScroll.currentVelocityWeighting` | `0.25` | `0` | how much current velocity influences the new step; 0 = track the wheel 1:1 | 🟡 |
| `general.smoothScroll.stopDecelerationWeighting` | `0.4` | `0.82` | how hard it brakes at the end; higher = stops sooner | 🟡 |
| `mousewheel.min_line_scroll_amount` | `5`-ish | `30` | px per "line" on line-scrolled pages. The single most taste-dependent value here | 🟡 |
| `apz.overscroll.enabled` | `true` | `true` | rubber-band overscroll | 🟡 |
| `layout.frame_rate` | `-1` | `-1` | **leave it.** `-1` = follow the display and vsync. Pinning it to 240/360 is how people get judder and tearing on high-Hz panels | 🔴 if changed |

Order of operations if scrolling feels wrong:

1. Is the panel actually at its maximum refresh rate? ([01](01-windows-and-driver.md))
2. Is `about:support` showing `WebRender`?
3. Is an extension injecting CSS into every page? ([06](06-extensions.md))
4. Only then start moving the numbers above, one at a time.

---

## Video decode

| Pref | Default | Set to | Effect | |
|---|---|---|---|---|
| `media.hardware-video-decoding.enabled` | `true` | `true` | use the GPU's fixed-function decoders | 🟢 |
| `media.wmf.hevc.enabled` | `1` | `1` | HEVC through Media Foundation; needs the HEVC Video Extension to matter | 🟡 |
| `media.hardware-video-decoding.force-enabled` | `false` | *leave off* | bypasses the driver blocklist. Only as a diagnostic — green frames are the usual result | 🔴 |
| `media.ffvpx.enabled` | `true` | **true** | `false` disables Firefox's bundled decoders. It does **not** turn on hardware decode, and VP9/AV1 often fall back to them | 🔴 if changed |

Verify with the video's own stats: right-click the player → **Stats for nerds** on YouTube shows the codec
(`avc1` / `vp09` / `av01`) and whether frames are dropped. `about:support` → **Media** lists hardware decode
support per codec.

---

## Background noise

No measurable frame-rate effect on 20 threads. Every line removes a timer, a request or a disk write you did
not ask for. Keep or skip freely.

| Pref | Set to | Removes |
|---|---|---|
| `toolkit.telemetry.enabled` | `false` | telemetry upload |
| `toolkit.telemetry.unified` | `false` | the unified telemetry pipeline |
| `datareporting.policy.dataSubmissionEnabled` | `false` | data submission |
| `datareporting.healthreport.uploadEnabled` | `false` | health report |
| `app.shield.optoutstudies.enabled` | `false` | Shield studies |
| `browser.discovery.enabled` | `false` | recommended-add-on lookups |
| `browser.newtabpage.activity-stream.showSponsored` | `false` | new-tab sponsored tile |
| `browser.newtabpage.activity-stream.showSponsoredTopSites` | `false` | sponsored shortcuts |
| `browser.urlbar.quicksuggest.enabled` | `false` | address-bar suggestions (skip if you use them) |
| `extensions.pocket.enabled` | `false` | Pocket (may already be gone) |
| `browser.ping-centre.telemetry` | — | removed from the product years ago | 🔴 |

---

## UI and startup

| Pref | Set to | Effect | |
|---|---|---|---|
| `toolkit.legacyUserProfileCustomizations.stylesheets` | `true` | required for `userChrome.css` to load at all | 🟢 |
| `browser.compactmode.show` | `true` | expose compact density in Customize Toolbar | 🟡 |
| `browser.uidensity` | `1` | compact by default (0 normal, 1 compact, 2 touch) | 🟡 |
| `browser.startup.preXULSkeletonUI` | `true` | **keep true.** `false` removes the Windows skeleton window and makes launch *slower* | 🔴 if changed |
| `content.notify.interval` | `120000` | content reflow batching, microseconds. Moving it to 100000 is unmeasurable | 🔴 |
| `gfx.content.azure.backends` | — | Azure was removed; this string pref does nothing | 🔴 |

---

## Apply all of it at once

[`user.js`](../user.js) in this repo is exactly the 🟢 and 🟡 rows above, with a comment on every line and an
explicit list of the 🔴 ones at the bottom. Copy it into the profile folder, or:

```powershell
.\scripts\Install-FirefoxTune.ps1
```

**Remember:** `user.js` wins over `about:config` at every start. If a value keeps reverting, that file is the
reason — see [04](04-user-js-profiles.md).
