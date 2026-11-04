<div align="center">
  <img src="assets/hero.svg" width="100%" alt="Firefox, but butter-smooth — a tuning guide for Windows machines with two GPUs">
</div>

<div align="center">

![Firefox](https://img.shields.io/badge/Firefox-115%2B-FF7139?style=for-the-badge&logo=firefoxbrowser&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-10_%2F_11-0078D4?style=for-the-badge&logo=windows11&logoColor=white)
![GPU](https://img.shields.io/badge/GPU-hybrid_iGPU_%2B_dGPU-76B900?style=for-the-badge&logo=nvidia&logoColor=white)
![Refresh](https://img.shields.io/badge/refresh-set_to_your_max-8B5CF6?style=for-the-badge&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-3FB950?style=for-the-badge)

</div>

<br>

<div align="center">
  <b>Ten steps, ranked by what actually moved the needle.</b><br>
  <sub>Written so anyone can follow it: every step says <b>where</b> to go and <b>what</b> to click, on any Windows machine.<br>
  Each one has pros, cons, an honest impact rating and a one-line undo — plus a line-by-line audit of a generated pref list.</sub>
</div>

---

## ⚡ The 30-second version

| | Do this | Where | Gain |
|:-:|:--|:--|:--|
| **1** | Set the panel to **its own highest refresh rate** | `Settings → Display → Advanced display` | 🔥🔥🔥 |
| **2** | Point `firefox.exe` at the **dedicated GPU** | `Settings → Display → Graphics` | 🔥🔥 |
| **3** | **DXGI swapchain** present method *(NVIDIA only)* | NVIDIA Control Panel → Firefox | 🔥 kills the flicker |
| **4** | **One** content blocker — uBlock Origin | Firefox → Add-ons | 🔥 less jank |

> **If you only do one thing:** find your panel's maximum refresh rate and make sure Windows is actually using it. Everything else here is polishing a frame budget measured in single-digit milliseconds.

### Your frame budget: find your number

You can't choose your refresh rate — your panel has a maximum, and Windows may simply not be using it. Look yours up:

| Your panel | Milliseconds per frame | How tight is it? |
|:-:|:-:|:--|
| 60 Hz | 16.7 ms | lots of slack — most tweaks are invisible |
| 75 Hz | 13.3 ms | |
| 120 Hz | 8.3 ms | |
| 144 Hz | 6.9 ms | |
| 165 Hz | 6.1 ms | |
| 240 Hz | 4.2 ms | a 4 ms hitch costs you a frame |
| 360 Hz | 2.8 ms | a 4 ms hitch is a visible stutter |

The higher the number, the less room you have. On a 60 Hz laptop an extension that blocks for 4 ms is invisible; on a 240 Hz monitor it is most of a frame. **That ratio, not the hardware, decides how much the rest of this guide matters to you.**

Three consequences, straight from that table:

- A few-millisecond stall in an extension or a content process is invisible at 60 Hz and obvious at 240 Hz.
- Content process count matters more than it looks: less work per process, smaller chance of a multi-millisecond hitch.
- `layout.frame_rate` must stay at `-1`. Pinning it to a number takes the compositor off the vsync path — judder and tearing follow.

---

## 📊 What actually moved the needle

<div align="center">
  <img src="assets/impact.svg" width="100%" alt="Bar chart ranking the ten tweaks by impact: refresh rate, GPU choice and the NVIDIA profile at the top; userChrome.css and scroll physics at the bottom">
</div>

---

## 🧭 Where the frames go

If your machine has two GPUs (an Intel/AMD integrated chip *and* an NVIDIA/AMD dedicated one), Windows decides per program which one renders Firefox — and the default choice is usually the power-saving one:

<div align="center">
  <img src="assets/frame-path.svg" width="100%" alt="Frame path: Firefox content process to the compositor, then Windows chooses the GPU — the integrated one by default, the dedicated one when set to High performance, both feeding the panel">
</div>

And when it still stutters, this is the order that finds the cause:

<div align="center">
  <img src="assets/triage.svg" width="100%" alt="Triage order: check the panel's max refresh rate, then WebRender, then which GPU Firefox uses, then extensions, then profile the scroll">
</div>

---

## 🖥️ Where the numbers come from

Every rating here was measured on one machine — a gaming laptop with a 1080p 360 Hz panel, 16 GB and a dGPU + iGPU pair. Treat it as a datapoint, not a requirement: nothing in this guide is tuned to that hardware, and each step says how to size it for yours (or to skip it if it doesn't apply).

> **Refresh rate and link bandwidth.** Higher rates need more bandwidth. 1080p at 360 Hz needs DisplayPort 1.4 or internal eDP — HDMI 2.0 tops out near 240 Hz at that resolution. If Windows offers less than your panel's spec, suspect the cable or port.

---

## 🪜 The ten steps

**How to read a step:** **Where** is where to go. **Do** is the exact clicks, in order. **Skip** it if it doesn't apply to your machine — no second GPU, AMD instead of NVIDIA, and so on. Nothing here is mandatory except step 1.

### 01 · Run your panel at its own maximum refresh rate

![impact](https://img.shields.io/badge/impact-highest-FF5C2B?style=flat-square) ![risk](https://img.shields.io/badge/risk-none-3FB950?style=flat-square)

**Why:** the compositor can only draw as fast as the panel is clocked. Windows drops back to 60 Hz after driver updates, dock changes and display-mode switches — and never tells you.

**Where:** `Win + I` → **System → Display → Advanced display**.

**Do:**
1. Click the **Choose a refresh rate** dropdown.
2. Read the list. It only shows modes your panel *and* current cable actually support — 60, 120, 144, 165, 240, 360, whatever yours is.
3. Pick the **highest** one. That number is now your frame budget (see the table above).

**If you only see 60 Hz:** the driver is usually the reason. Open the GPU vendor's control panel (**NVIDIA Control Panel → Change resolution**, or AMD Software → Display) and set the refresh rate there, or reinstall the GPU driver. A second monitor may also be capped by the cable.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Biggest single improvement available, and free | More idle power — high-refresh panels are thirsty |
| Fixes stutter in *every* app, not just Firefox | Some laptops deliberately downclock on battery |
| One click, instantly reversible | You will notice 60 Hz forever afterwards |

**↩️ Undo:** pick `60 Hz` in the same dropdown.

---

### 02 · Point Firefox at the dedicated GPU

![impact](https://img.shields.io/badge/impact-big-FF8A3D?style=flat-square) ![risk](https://img.shields.io/badge/risk-battery-E2A336?style=flat-square)

**Why:** a browser is assumed to be a battery-friendly app and gets the integrated GPU. Forcing the dedicated one gives Firefox the fill rate for compositing, canvas and video decode.

**Skip if:** your PC has a single GPU (most desktops with one card, most cheap laptops). Nothing to choose.

**Where:** `Win + I` → **System → Display → Graphics**.

**Do:**
1. Under *Custom options for apps*, click **Browse**.
2. Find `firefox.exe` — usually `C:\Program Files\Mozilla Firefox\firefox.exe`.
   *Can't find it?* Open Firefox, press `Ctrl + Shift + Esc`, right-click **Firefox** in Task Manager → **Open file location**.
3. Firefox now appears in the list — click it → **Options**.
4. Choose **High performance** → **Save**.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Removes the biggest stutter source on hybrid laptops | Battery life drops — the dGPU idles higher than the iGPU |
| Makes hardware decode and GPU raster actually reachable | More heat, fans sooner |
| No registry, no driver mods | Games now share a busier GPU |

**↩️ Undo:** same screen → **Let Windows decide**.

---

### 03 · NVIDIA Control Panel: one profile, two fixes

![impact](https://img.shields.io/badge/impact-medium-8B5CF6?style=flat-square) ![risk](https://img.shields.io/badge/risk-none-3FB950?style=flat-square)

**Why:** Windows decides *which* GPU; the driver decides *how*. Its default power management lets clocks fall between frames, and on Optimus laptops it can pick the wrong present path and flicker.

**Skip if:** you have an AMD or Intel GPU — the equivalent lives in AMD Software → Gaming → Graphics, but the specific settings differ.

**Where:** right-click the desktop → **NVIDIA Control Panel**. *Missing?* Install it from the Microsoft Store ("NVIDIA Control Panel"), then reboot.

**Do:**
1. **Manage 3D Settings** → tab **Program Settings**.
2. **Add** → select **Mozilla Firefox** from the list.
3. Set these:

| Setting | Value | Why |
|:--|:--|:--|
| Preferred graphics processor | High-performance NVIDIA processor | belt and braces with step 2 |
| Power management mode | Prefer maximum performance | stops clock ramping between frames |
| Max Frame Rate | Off, or = your panel Hz | never let a background app get capped to 20–30 |
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

**Why:** every pref list jumps to `about:config` and skips the settings page that owns the process model. `dom.ipc.processCount` is ignored while "Use recommended performance settings" is ticked.

**Where:** Firefox → **☰ menu → Settings → General**, scroll down to **Performance**.

**Do:**
1. Uncheck **Use recommended performance settings** — this unlocks the two controls under it.
2. Keep **Use hardware acceleration when available** checked.
3. Set **Content process limit**: `8` is the default and fine on 8–16 GB. On 16 GB or more you can try `12`.

*How much RAM do you have?* `Win + I` → System → About → Installed RAM.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| The only supported way to change the process limit | More processes = more RAM (~3 GB of content at 12) |
| Costs nothing, breaks nothing | Turning hardware accel *off* here is a common self-own |
| Makes the limit survive a restart | 16+ is past the point of returns on 16 GB |

**↩️ Undo:** re-tick **Use recommended performance settings**.

---

### 05 · The `about:config` dozen

![impact](https://img.shields.io/badge/impact-small-55647E?style=flat-square) ![risk](https://img.shields.io/badge/risk-low-3FB950?style=flat-square)

**Why:** this is the 60%-placebo part of the internet. These twelve still exist *and* do something. Full table with defaults and verdicts: **[docs/03](docs/03-about-config.md)**.

**Where:** type `about:config` in the **address bar** (the same box you type websites in) → press Enter → click **Accept the Risk and Continue**.

**Do:**
1. Use the **search box at the top** of that page to find each pref by name.
2. Click the **pencil** (number/text) or **double-click** the row (true/false) to edit, type the value, press Enter or the ✓.
3. If a pref isn't there, it doesn't exist in your build — skip it. (Nothing breaks.)

| Pref | Set to | What it does |
|:--|:-:|:--|
| `gfx.canvas.accelerated.cache-size` | `512` | VRAM budget for canvas, MB (256 default; keep 256 on 4 GB cards) |
| `gfx.webrender.software` | `false` | refuse software compositing |
| `gfx.direct2d.disabled` | `false` | keep Direct2D on |
| `dom.ipc.processCount` | `12` | content processes (only if you have 16 GB+) |
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

**Would rather click than copy files?** Skip this step entirely; step 5 already did the work. This one is for people who reinstall often.

**Where:** your Firefox profile folder — type `about:support` in the address bar, find the **Profile Folder** row, click **Open Folder**.

**Do:**
1. Close Firefox completely (`Ctrl + Shift + Esc`, check no `firefox.exe` remains — a background process rewrites `prefs.js` on exit).
2. Copy [`user.js`](user.js) from this repo into that folder.
3. Start Firefox.

Or let the script do it (it backs up `prefs.js` first):

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

**Why:** panel and menu animations are tuned for 60 Hz. On a fast panel that fade *is* the latency.

**Where:** the same **Profile Folder** from step 6 (`about:support` → Open Folder).

**Do:**
1. In `about:config`, set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`. Without this, Firefox never reads the file.
2. Inside the profile folder, create a folder named exactly `chrome` (lowercase).
3. Put [`chrome/userChrome.css`](chrome/userChrome.css) inside it.
4. Restart Firefox completely — all windows closed, not just a new window.

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

**Where:** `about:addons` in the address bar, or **☰ menu → Add-ons and themes** (`Ctrl + Shift + A`).

**Do:**
- **One** blocker: uBlock Origin. Remove AdBlock, AdBlock Plus, Ghostery, Privacy Badger — two blockers means two filter passes per request.
- Delete anything that injects CSS/DOM into every page: dark-mode forcers, font replacers, **"smooth scroll" extensions** (they reimplement scrolling in JS, outside APZ — always worse).
- Keep filter lists lean: if you can't name a site the list fixed, it's costing you more than it earns.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Cheapest real CPU win in the list | One site will break and you'll blame the wrong thing |
| Less memory, fewer timers, fewer mystery requests | Losing "redundancy" feels wrong and is free |

**↩️ Undo:** reinstall whatever you removed.

---

### 09 · Scroll feel (taste, not performance)

![impact](https://img.shields.io/badge/impact-taste-39465C?style=flat-square) ![risk](https://img.shields.io/badge/risk-taste-E2A336?style=flat-square)

**Why:** Firefox's wheel curve is deliberately damped. If scrolling feels heavy, these are the dials. Nothing here renders a frame faster — it changes the curve.

**Where:** `about:config` again (address bar → `about:config` → **Accept the Risk and Continue**).

**Do — one pref at a time:**
1. Type the name in the search box at the top.
2. If the row exists, click its value and change it. If it doesn't exist, right-click anywhere in the list → **New** → pick the type noted below → paste the name → enter the value.
3. Restart is not needed; scrolling changes immediately.

| Pref | Type | Value | Default | What it does |
|:--|:-:|:-:|:-:|:--|
| `general.smoothScroll.msdPhysics.enabled` | Boolean | `true` | build-dependent | the newer physics model |
| `general.smoothScroll.mouseWheel.durationMaxMS` | Integer | `300` | `400` | longest animation for one wheel notch |
| `general.smoothScroll.mouseWheel.durationMinMS` | Integer | `100` | `200` | shortest |
| `mousewheel.min_line_scroll_amount` | Integer | `30` | small, varies | pixels per "line" on line-scrolled pages |
| `general.smoothScroll.currentVelocityWeighting` | decimal¹ | `0` | `0.25` | 0 = track the wheel 1:1 |
| `general.smoothScroll.stopDecelerationWeighting` | decimal¹ | `0.82` | `0.4` | how hard it brakes at the end |
| `apz.overscroll.enabled` | Boolean | `true` | `true` | rubber-band overscroll |

¹ Decimals are stored as text and already exist in most builds. **If one is missing, don't create it** — you get most of the effect from the first four lines.

**Start with only the two `duration` values.** They're the ones you actually feel; add the rest one at a time so you know what did what.

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Shorter, more direct animation — feels native | No universal default; these are build- and taste-dependent |
| Free: it's arithmetic in the compositor | On a 60 Hz panel or a trackpad it can feel twitchy |
| Instant feedback, no restart | Easy to over-tune and blame Firefox later |

**↩️ Undo:** right-click → **Reset** on each pref. (Or delete the lines from `user.js` if you used step 6.)

---

### 10 · Measure instead of guessing

![impact](https://img.shields.io/badge/impact-zero_frames,_all_the_truth-39465C?style=flat-square) ![risk](https://img.shields.io/badge/risk-none-3FB950?style=flat-square)

**Why:** otherwise every placebo feels like a win. On a high-refresh panel you can see a single dropped frame, so the tools pay for themselves.

**Where / Do — three tools, all built in:**

| Tool | How to open it | What it tells you |
|:--|:--|:--|
| FPS overlay | `about:config` → `layers.acceleration.draw-fps` = `true` | live compositor frame rate, in the corner |
| GPU status | `about:support` → **Graphics** | `Compositing` must say `WebRender`, not `WebRender (Software)` |
| Per-tab cost | `about:processes` | which tab or extension is eating CPU and RAM |
| Profiler | [profiler.firefox.com](https://profiler.firefox.com) → Start recording → scroll → Capture | *why* a frame was missed |

| ✅ Pros | ⚠️ Cons |
|:--|:--|
| Turns "feels smoother" into a number | The overlay costs a little — don't leave it on |
| Catches software compositing in seconds | Average FPS hides frame pacing; the profiler doesn't |
| Free and built in | Numbers still can't measure perceived latency |

**↩️ Undo:** `layers.acceleration.draw-fps` = `false`.

---

## 🔌 Two profiles: plugged in vs battery

Same machine, two different goals. Pick a column, not a compromise.

| Setting | 🔌 Plugged in | 🔋 On battery |
|:--|:--|:--|
| Panel refresh | your panel's max | 60 Hz, or let Windows decide |
| GPU for Firefox | High performance (dGPU) | Let Windows decide |
| NVIDIA power management | Prefer maximum performance | Optimal power |
| `dom.ipc.processCount` | 12 (16 GB+) / 8 | 8 |
| `gfx.canvas.accelerated.cache-size` | 512 | 256 |
| uBlock Origin | on | on |
| `userChrome.css` | on | on |

Steps 1–3 flip by hand in about 30 seconds. Everything in 5–9 is cheap enough to leave alone.

---

## 🧪 The audit (why this repo exists)

<div align="center">
  <img src="assets/audit.svg" width="100%" alt="Audit of ten prefs: one backwards, one harmful, three dead, two noise, three useful">
</div>

A 13-line `user.js` labelled "Betterfox" turned up in a Firefox beta profile. Six of its ten prefs never ran a line of code, one made launching slower, and one asked an 8 GB card for a 4 GB canvas cache.

It still felt faster — because the same session also set the GPU preference and the refresh rate. **The pref list took the credit.** The full line-by-line audit, plus every common no-op, is in **[docs/08](docs/08-what-not-to-do.md#appendix-a-real-generated-userjs-audited)**.

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
| [`assets/`](assets) | hero, impact, audit, frame-path and triage graphics (hand-written SVG) |
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
- **Not a benchmark.** The ranking is what survived repeated use on one machine, plus what `about:support` and the profiler confirmed.
- **Not permanent.** Firefox renames prefs between releases. If a line stops existing, delete that line.

If a step didn't help on your machine, that's useful data — open an issue with your `about:support` **Graphics** block and your panel's refresh rate.

## 🙏 Credits

- [Betterfox](https://github.com/yokoffing/Betterfox) — proof that a `user.js` can be maintained rather than copy-pasted. This repo's profile is a much smaller, hardware-agnostic cousin.
- Mozilla's [Firefox Profiler](https://profiler.firefox.com) and the `about:support` page.
- NVIDIA's Advanced Optimus notes, where the DXGI present-method fix actually comes from.

## 📄 License

MIT — see [LICENSE](LICENSE). Take it, cut it up, keep the parts that work for you.
