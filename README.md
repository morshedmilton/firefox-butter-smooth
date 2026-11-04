<div align="center">
  <img src="assets/hero.svg" width="100%" alt="Firefox, but butter-smooth — a tuning guide for a Dell G15 5530 with a 360 Hz panel and an RTX 4060">
</div>

<div align="center">

![Firefox](https://img.shields.io/badge/Firefox-160_Beta-FF7139?style=for-the-badge&logo=firefoxbrowser&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-11-0078D4?style=for-the-badge&logo=windows11&logoColor=white)
![GPU](https://img.shields.io/badge/RTX-4060_Laptop-76B900?style=for-the-badge&logo=nvidia&logoColor=white)
![Display](https://img.shields.io/badge/display-360_Hz-8B5CF6?style=for-the-badge&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-3FB950?style=for-the-badge)

</div>

<br>

<div align="center">
  <b>Ten steps, ranked by what actually moved the needle.</b><br>
  <sub>Each with pros, cons, an honest impact rating and a one-line undo. Plus the audit of the pref list I started with — six of its ten lines never ran.</sub>
</div>

---

## ⚡ The 30-second version

| | Do this | Where | Gain |
|:-:|:--|:--|:--|
| **1** | Confirm **360 Hz** — not 240, not 60 | `Settings → Display → Advanced display` | 🔥🔥🔥 |
| **2** | Point `firefox.exe` at the **RTX 4060** | `Settings → Display → Graphics` | 🔥🔥 |
| **3** | **DXGI swapchain** present method | NVIDIA Control Panel → Firefox | 🔥 kills the flicker |
| **4** | **One** content blocker — uBlock Origin | Firefox → Add-ons | 🔥 less jank |

> **If you only do one thing:** make sure the panel is really running at 360 Hz. Everything else on this page is polishing a **2.78 ms** frame budget.

### What a 2.78 ms budget actually means

At 360 Hz the compositor has 2.78 ms per frame. Miss it and you drop a frame — and at 360 Hz a dropped frame is twice as visible as at 180, because the interval you missed is half as long.

That reframes the whole guide:

- An extension that blocks the main thread for 4 ms used to be invisible at 60 Hz. Here it is a stutter.
- Twelve content processes matter more than they look: less per-process work means less chance of a 3 ms hitch.
- `layout.frame_rate` must stay at `-1`. Pinning it to 360 takes the compositor off the vsync path, which is where judder and tearing come from.

---

## 📊 What actually moved the needle

<div align="center">
  <img src="assets/impact.svg" width="100%" alt="Bar chart ranking the ten tweaks by impact: refresh rate, GPU choice and the NVIDIA profile at the top; userChrome.css and scroll physics at the bottom">
</div>

---

## 🧭 Where the frames go

This is the whole reason steps 1–3 exist. In hybrid (Advanced Optimus) mode, Windows picks the GPU per program, and a browser usually gets the iGPU:

```mermaid
flowchart LR
    A["Firefox content process"] --> B["Compositor · WebRender"]
    B --> C{"Windows picks the GPU"}
    C -->|"default: save power"| D["Intel UHD"]
    C -->|"High performance"| E["RTX 4060"]
    D --> F["Panel · 360 Hz"]
    E --> F
    classDef neutral fill:#141d2f,stroke:#55647e,color:#c9d2e3
    classDef bad fill:#3b1620,stroke:#E5484D,color:#ffd7da
    classDef good fill:#0f2a18,stroke:#3FB950,color:#d6f5de
    class A,B,C,F neutral
    class D bad
    class E good
```

And when it still stutters, this is the order that finds the cause:

```mermaid
flowchart TD
    S["It feels stuttery"] --> R{"Panel at 360 Hz?"}
    R -->|no| R1["Display → Advanced display"]:::fix
    R -->|yes| C{"about:support: WebRender?"}
    C -->|"WebRender (Software)"| C1["Driver + blocklist log"]:::fix
    C -->|yes| G{"GPU #1 is the RTX?"}
    G -->|no| G1["Graphics → High performance"]:::fix
    G -->|yes| X{"Clean profile, no extensions?"}
    X -->|no| X1["Extension diet · docs/06"]:::fix
    X -->|yes| P["Profile the scroll · docs/07"]:::last
    classDef fix fill:#3b1620,stroke:#E5484D,color:#ffd7da
    classDef last fill:#0f2a18,stroke:#3FB950,color:#d6f5de
```

---

## 🖥️ The machine

| | |
|:--|:--|
| **Laptop** | Dell G15 5530 |
| **CPU** | Intel Core i7-13650HX — 14 cores / 20 threads |
| **GPU** | NVIDIA GeForce RTX 4060 Laptop (8 GB) + Intel UHD Graphics |
| **Display mode** | Automatic MUX / Advanced Optimus (hybrid) |
| **Panel** | AUO, 1920 × 1080, **360 Hz** (max = current = 360) |
| **RAM** | 16 GB |
| **Browser** | Firefox 160.0 Beta, x64 en-US, build 20261102 |
| **Install** | `D:\Softwares\Firefox Beta\firefox.exe` |

> 1080p at 360 Hz needs DisplayPort 1.4 with DSC, or the internal eDP link. If Windows only offers 240 Hz, that's a cable or link-bandwidth limit — not a Firefox problem, and no pref will fix it.

---

## 🪜 The ten steps

Each step carries two badges: **impact** on this machine, and **risk** to you.

### 01 · Run the panel at 360 Hz

![impact](https://img.shields.io/badge/impact-highest-FF5C2B?style=flat-square) ![risk](https://img.shields.io/badge/risk-none-3FB950?style=flat-square)

**Why:** the compositor can only draw as fast as the panel is clocked. Windows drops back to 60 Hz after driver updates, dock changes and display-mode switches, and it never tells you.

**Do:** `Win + I` → **System → Display → Advanced display** → **Choose a refresh rate** → `360 Hz`.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Biggest single improvement available, and free | More idle power; a 360 Hz panel is thirsty |
| Fixes stutter in *every* app, not just Firefox | Some panels downclock on battery by design |
| One click, instantly reversible | You will notice 60 Hz forever afterwards |

**↩️ Undo:** pick `60 Hz` in the same dropdown.

---

### 02 · Point Firefox at the RTX 4060

![impact](https://img.shields.io/badge/impact-big-FF8A3D?style=flat-square) ![risk](https://img.shields.io/badge/risk-battery-E2A336?style=flat-square)

**Why:** a browser is assumed to be a battery-friendly app and gets the iGPU. Forcing the dGPU gives Firefox the fill rate for compositing, canvas and video decode.

**Do:** `Win + I` → **System → Display → Graphics** → **Browse** → `D:\Softwares\Firefox Beta\firefox.exe` → **Options** → **High performance** → **Save**.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Removes the biggest stutter source on hybrid laptops | Battery life drops — the 4060 idles higher than the UHD |
| Makes hardware decode and GPU raster actually reachable | More heat, fans sooner |
| No registry, no driver mods | Games now share a busier GPU |

**↩️ Undo:** same screen → **Let Windows decide**.

---

### 03 · NVIDIA Control Panel: one profile, two fixes

![impact](https://img.shields.io/badge/impact-medium-8B5CF6?style=flat-square) ![risk](https://img.shields.io/badge/risk-none-3FB950?style=flat-square)

**Why:** Windows decides *which* GPU; the driver decides *how*. Its default power management lets clocks fall between frames, and on Optimus it can pick the wrong present path and flicker.

**Do:** `Manage 3D Settings → Program Settings → Add → Mozilla Firefox`:

| Setting | Value | Why |
|:--|:--|:--|
| Preferred graphics processor | High-performance NVIDIA processor | belt and braces with step 2 |
| Power management mode | Prefer maximum performance | stops clock ramping between frames |
| Max Frame Rate | Off, or `360` | never let a background app get capped to 20–30 |
| Vulkan/OpenGL present method | **Prefer layered on DXGI Swapchain** | the actual fix for black-flash-on-alt-tab |
| Vertical sync | Use the 3D application setting | forcing Off tears |

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| The DXGI present method kills the classic Optimus flicker | Max-performance keeps the GPU clocked up: hotter idle |
| Per-program, so other apps keep normal power behaviour | On some driver branches DXGI breaks full-screen games — keep it Firefox-only |
| Survives driver updates better than registry hacks | One more thing to redo after a clean install |

**↩️ Undo:** NVIDIA CP → Firefox → **Remove**.

---

### 04 · Firefox's own Performance panel

![impact](https://img.shields.io/badge/impact-small-55647E?style=flat-square) ![risk](https://img.shields.io/badge/risk-none-3FB950?style=flat-square)

**Why:** every pref list jumps to `about:config` and skips the GUI that actually owns the process model. `dom.ipc.processCount` is ignored while "Use recommended performance settings" is ticked.

**Do:** `about:preferences` → **General → Performance** → uncheck **Use recommended performance settings** → keep **Use hardware acceleration when available** checked → **Content process limit = 12**.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| The only supported way to change the process limit | More processes = more RAM (~3 GB of content at 12) |
| Costs nothing, breaks nothing | Turning hardware accel *off* here is a common self-own |
| Makes the limit survive a restart | 16 is past the point of returns on 16 GB |

**↩️ Undo:** re-tick **Use recommended performance settings**.

---

### 05 · The `about:config` dozen

![impact](https://img.shields.io/badge/impact-small-55647E?style=flat-square) ![risk](https://img.shields.io/badge/risk-low-3FB950?style=flat-square)

**Why:** this is the 60%-placebo part of the internet. These twelve are the ones that still exist *and* do something. Full table with defaults and verdicts: **[docs/03](docs/03-about-config.md)**.

| Pref | Set to | What it does |
|:--|:-:|:--|
| `gfx.canvas.accelerated.cache-size` | `512` | VRAM budget for canvas, MB (default 256) |
| `gfx.webrender.software` | `false` | refuse software compositing |
| `gfx.direct2d.disabled` | `false` | keep Direct2D on |
| `dom.ipc.processCount` | `12` | content processes for 20 threads |
| `browser.tabs.unloadOnLowMemory` | `true` | collapse background tabs under pressure |
| `browser.sessionstore.interval` | `60000` | session writes every 60 s, not 15 s |
| `nglayout.initialpaint.delay` | `0` | paint immediately (default 5 ms) |
| `nglayout.initialpaint.delay.composite` | `0` | same, compositor path |
| `general.smoothScroll.msdPhysics.enabled` | `true` | newer scroll physics |
| `media.hardware-video-decoding.enabled` | `true` | use the GPU's decoders |
| `media.wmf.hevc.enabled` | `1` | HEVC via Media Foundation |
| `layers.acceleration.draw-fps` | `true` | **temporary** — FPS overlay, for step 10 |

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Small honest gains: less paint latency, less disk churn | Several are unfeelable — you will not notice sessionstore |
| All reversible in the same panel | Unsupported surface: Mozilla renames these freely |
| One gives you a frame counter | Copying a stranger's list is how 300-line junk files happen |

**↩️ Undo:** right-click each row → **Reset**.

---

### 06 · Make it permanent with `user.js`

![impact](https://img.shields.io/badge/impact-convenience-39465C?style=flat-square) ![risk](https://img.shields.io/badge/risk-locks_prefs-E2A336?style=flat-square)

**Why:** `about:config` edits survive updates but not a profile refresh. A `user.js` re-applies a known-good set at every start — and moves your setup to a new machine in one file.

**Do:**

```powershell
.\scripts\Install-FirefoxTune.ps1
```

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Reproducible: same browser on any machine | **It overrides the UI** — change a pref and it reverts next launch |
| Self-documenting: every line says why | One more thing to remember after a Firefox update |
| Delete the file and you are back to stock | Dead prefs pile up silently |

**↩️ Undo:** delete `user.js` from the profile folder (or run `Restore-FirefoxTune.ps1`).

---

### 07 · `userChrome.css`: snappier menus

![impact](https://img.shields.io/badge/impact-perceived-39465C?style=flat-square) ![risk](https://img.shields.io/badge/risk-cosmetic-E2A336?style=flat-square)

**Why:** panel and menu animations are tuned for 60 Hz. On 360 Hz that fade *is* the latency.

**Do:** `about:config` → `toolkit.legacyUserProfileCustomizations.stylesheets` = `true`, then drop [`chrome/userChrome.css`](chrome/userChrome.css) into the profile's `chrome/` folder and restart.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Menus open on the frame you click | **Unsupported API** — breaks silently after UI updates |
| Tabs stop fading | Parsed per window: a big stylesheet slows startup |
| Pure CSS, no extension, no process | Can break panel positioning on mixed-DPI multi-monitor |

**↩️ Undo:** delete the file, restart.

---

### 08 · Extension diet

![impact](https://img.shields.io/badge/impact-real-FF8A3D?style=flat-square) ![risk](https://img.shields.io/badge/risk-none-3FB950?style=flat-square)

**Why:** every extension injects code into pages. Content blockers and style injectors are the two that show up in scroll profiles.

**Do:**

- **One** blocker: uBlock Origin. Remove AdBlock, AdBlock Plus, Ghostery, Privacy Badger — two blockers means two filter passes per request.
- Delete anything that injects CSS/DOM into every page: dark-mode forcers, font replacers, **"smooth scroll" extensions** (those reimplement scrolling in JS, outside APZ — always worse).
- Keep filter lists lean.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Cheapest real CPU win in the list | One site will break and you'll blame the wrong thing |
| Less memory, fewer timers, fewer mystery requests | Losing "redundancy" feels wrong and is free |

**↩️ Undo:** reinstall whatever you removed.

---

### 09 · Scroll feel (taste, not performance)

![impact](https://img.shields.io/badge/impact-taste-39465C?style=flat-square) ![risk](https://img.shields.io/badge/risk-taste-E2A336?style=flat-square)

**Why:** Firefox's wheel curve is deliberately damped. Nothing here renders a frame faster — it changes the curve.

```js
general.smoothScroll.msdPhysics.enabled          true
general.smoothScroll.mouseWheel.durationMaxMS    300   // default 400
general.smoothScroll.mouseWheel.durationMinMS    100   // default 200
general.smoothScroll.currentVelocityWeighting    0
general.smoothScroll.stopDecelerationWeighting   0.82
mousewheel.min_line_scroll_amount                30
```

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Shorter, more direct animation — feels native | No universal default; these are build- and taste-dependent |
| Free: it's arithmetic in the compositor | On a 60 Hz laptop screen it can feel twitchy |

**↩️ Undo:** right-click → **Reset** per pref.

---

### 10 · Measure instead of guessing

![impact](https://img.shields.io/badge/impact-zero_frames,_all_the_truth-39465C?style=flat-square) ![risk](https://img.shields.io/badge/risk-none-3FB950?style=flat-square)

**Why:** otherwise every placebo feels like a win. At 360 Hz you can see a single dropped frame, so the tools pay for themselves.

**Do:** `layers.acceleration.draw-fps = true` for an on-screen frame counter → `about:support` → **Graphics** must say `WebRender` → `about:processes` for the culprit tab → [profiler.firefox.com](https://profiler.firefox.com) for the *why*.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Turns "feels smoother" into a number | The overlay costs a little — don't leave it on |
| Catches software compositing in seconds | Average FPS hides frame pacing; the profiler doesn't |
| Free and built in | Numbers still can't measure perceived latency |

**↩️ Undo:** `layers.acceleration.draw-fps = false`.

---

## 🔌 Two profiles: plugged in vs battery

Same laptop, two different goals. Pick a column, not a compromise.

| Setting | 🔌 Plugged in | 🔋 On battery |
|:--|:--|:--|
| Panel refresh | **360 Hz** | 60 Hz, or let Windows decide |
| GPU for Firefox | High performance (RTX) | Let Windows decide |
| NVIDIA power management | Prefer maximum performance | Optimal power |
| `dom.ipc.processCount` | 12 | 8 |
| `gfx.canvas.accelerated.cache-size` | 512 | 256 |
| uBlock Origin | on | on |
| `userChrome.css` | on | on |

Steps 1–3 flip by hand in about 30 seconds. Everything in 5–9 is cheap enough to leave alone.

---

## 🧪 The audit (why this repo exists)

<div align="center">
  <img src="assets/audit.svg" width="100%" alt="Audit of ten prefs: one backwards, one harmful, three dead, two noise, three useful">
</div>

The `user.js` actually running on this laptop was 13 lines labelled "Betterfox". Six of its ten prefs never ran a line of code, one made launching slower, and one asked an 8 GB card for a 4 GB canvas cache.

It still felt faster — because the same session also set the GPU preference and the refresh rate. **The pref list took the credit.** The full line-by-line audit, plus every common no-op, is in **[docs/08](docs/08-what-not-to-do.md#appendix-the-exact-file-i-started-from)**.

---

## 📦 Install

```powershell
git clone https://github.com/morshedmilton/firefox-butter-smooth.git
cd firefox-butter-smooth
.\scripts\Install-FirefoxTune.ps1
```

The script finds your profile via `profiles.ini` (respecting the `[Install…]` binding, not just `Default=1`), refuses to run while Firefox is open, **backs up `prefs.js` first**, then copies `user.js` and `chrome\userChrome.css`.

See what it would touch, without touching it:

```powershell
.\scripts\Install-FirefoxTune.ps1 -List
```

## ↩️ Uninstall

```powershell
.\scripts\Restore-FirefoxTune.ps1
```

Renames `user.js` and the stylesheet aside, restores the newest `prefs.js` backup. Windows and NVIDIA settings are manual by design — **[docs/10](docs/10-revert.md)** has the exact clicks, in reverse order.

---

## 🗂️ Repo map

| File | What's in it |
|:--|:--|
| [`README.md`](README.md) | this page |
| [`user.js`](user.js) | ~50 commented lines — the tuned profile |
| [`chrome/userChrome.css`](chrome/userChrome.css) | 4 rules that actually exist in Firefox |
| [`scripts/`](scripts) | install + restore, with backup and a running-Firefox guard |
| [`assets/`](assets) | the hero, impact and audit graphics (hand-written SVG) |
| [`docs/01`](docs/01-windows-and-driver.md) | refresh rate, GPU choice, HAGS, power plans |
| [`docs/02`](docs/02-firefox-performance-settings.md) | the GUI step, done properly |
| [`docs/03`](docs/03-about-config.md) | every pref: default, value, verdict |
| [`docs/04`](docs/04-user-js-profiles.md) | how `user.js` works, and why it overrides you |
| [`docs/05`](docs/05-userchrome-css.md) | what the CSS can and cannot do |
| [`docs/06`](docs/06-extensions.md) | blocker hygiene, memory, tab pressure |
| [`docs/07`](docs/07-measuring.md) | FPS overlay, `about:processes`, profiler |
| [`docs/08`](docs/08-what-not-to-do.md) | the audit + every common no-op |
| [`docs/09`](docs/09-troubleshooting.md) | flicker, software rendering, video, crashes |
| [`docs/10`](docs/10-revert.md) | step-by-step undo |

---

## 🚫 What this is not

- **Not a privacy guide.** `user.js` here is about frames, not fingerprints.
- **Not a benchmark.** The ranking is what survived repeated use on one machine, plus what `about:support` and the profiler confirmed. No stopwatches were harmed.
- **Not permanent.** Firefox 160 is a beta; prefs move. If a line stops existing, delete that line.

If a step didn't help on your machine, that's useful data — open an issue with your `about:support` **Graphics** block and your panel refresh rate.

## 🙏 Credits

- [Betterfox](https://github.com/yokoffing/Betterfox) — proof that a `user.js` can be maintained rather than copy-pasted. This repo's profile is a much smaller, hardware-specific cousin.
- Mozilla's [Firefox Profiler](https://profiler.firefox.com) and the `about:support` page.
- NVIDIA's Advanced Optimus notes, where the DXGI present-method fix actually comes from.

## 📄 License

MIT — see [LICENSE](LICENSE). Take it, cut it up, keep the parts that work for you.
