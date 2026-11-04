# Firefox Butter Smooth

**A Firefox tuning guide that survived contact with reality.**

An AI handed me a list of "make Firefox fly" tweaks. I applied all of them, then checked every line against the
browser it was supposed to speed up. Of the ten prefs: three are dead, one is backwards, and one asks an 8 GB
card for 4 GB of VRAM. Two of the four CSS rules reference variables that do not exist. [The audit is here.](docs/08-what-not-to-do.md#appendix-the-exact-file-i-started-from)

What survived is in this repo: every step in order, with the pros and cons spelled out, what each change actually
does, and a one-command way back.

- Status: works, tested on the hardware below
- Scope: one laptop, one browser, no registry hacks, no cleaners, no snake oil
- Reversible: yes — [docs/10-revert.md](docs/10-revert.md)

---

## The machine

| | |
|---|---|
| Laptop | Dell G15 5530 |
| CPU | Intel Core i7-13650HX — 14 cores / 20 threads |
| GPU | NVIDIA GeForce RTX 4060 Laptop (8 GB) + Intel UHD Graphics |
| Display mode | **Automatic MUX / Advanced Optimus** (hybrid) |
| RAM | 16 GB |
| Panel | 1920 × 1080 *(5530 shipped with 120 Hz or 165 Hz panels — check yours)* |
| Browser | Firefox 160.0 Beta, x64 en-US, build 20261102 |
| Install path | `D:\Softwares\Firefox Beta\firefox.exe` |

> Why the GPU matters here: in hybrid mode the RTX renders and the iGPU hands the frames to the panel.
> Windows decides which GPU a program gets, and by default it may pick the Intel chip for a browser "to save
> power". That decision is the single biggest cause of the micro-stutter people blame Firefox for.

---

## Read this before you change anything

Three uncomfortable truths that shaped this guide:

1. **Refresh rate beats every pref.** If Windows is running your panel at 60 Hz, no `about:config` value will
   make scrolling feel like 165 Hz. Step 1 is one click and worth more than steps 5–9 combined.
2. **Most pref lists online are from 2019.** Firefox was rewritten underneath them (WebRender, Fission, GPU
   process isolation). Prefs like `layers.acceleration.force-enabled` were load-bearing once and are now no-ops.
   The browser silently ignores prefs that no longer exist — you get a placebo, not an error.
3. **"Smooth" is frame *pacing*, not average FPS.** A steady 60 feels better than 140 with hitches. Which is
   why [Step 10](#step-10--measure-instead-of-guessing) exists.

---

## What to expect

Ranked by how much it actually changed the feel of the browser on this machine:

| # | Change | Real impact | Risk | Time |
|---|--------|-------------|------|------|
| 1 | Run the panel at its true refresh rate | 🔥🔥🔥 biggest | none | 1 min |
| 2 | Point Firefox at the RTX 4060 | 🔥🔥 big on hybrid graphics | battery drain | 2 min |
| 3 | NVIDIA per-app profile | 🔥 medium, kills flicker | none | 2 min |
| 4 | Extension diet (uBlock Origin only) | 🔥 medium, removes jank | none | 5 min |
| 5 | Content processes 8 → 12 | 🌗 small, heavy tab sets only | RAM | 1 min |
| 6 | The 12 `about:config` prefs that still exist | 🌗 small but real | low | 5 min |
| 7 | Permanent `user.js` profile | = step 6, but sticky | locks your prefs | 2 min |
| 8 | `userChrome.css` snappy menus | 🌗 perceived only | cosmetic breakage | 5 min |
| 9 | Scroll physics | 🌗 pure taste | none | 2 min |
| 10 | Measuring | 0 impact, 100% honesty | none | 10 min |

Steps 1–4 are where the win is. Everything after that is polishing.

---

## Step 1 — Run the panel at its real refresh rate

**Why:** the compositor can only draw as fast as the panel is clocked. Windows frequently drops back to 60 Hz
after a driver update, a dock, or a display-mode switch, and nothing tells you.

**Do:**
1. `Win + I` → **System → Display → Advanced display**
2. **Choose a refresh rate** → pick the highest value offered (120 / 144 / 165)
3. While you're there: note the value, because this is the number you'll compare against later

**✅ Pros**
- Largest single improvement available, and it's free
- Fixes stutter in every application, not just Firefox
- Instantly reversible

**⚠️ Cons**
- Higher idle power; a 165 Hz panel on battery costs real wattage
- Some panels downclock themselves on battery anyway (that is the OEM's power policy, not a bug)

**Verdict:** do it now, before touching Firefox.

---

## Step 2 — Point Firefox at the RTX 4060

**Why:** with Advanced Optimus, Windows keeps a per-program GPU preference. A browser is usually assumed to be
a battery-friendly app and gets the iGPU. Forcing the dGPU gives Firefox the full fill rate for scrolling,
compositing, canvas and video decode.

**Do:**
1. `Win + I` → **System → Display → Graphics**
2. **Browse** → `D:\Softwares\Firefox Beta\firefox.exe`
3. Click **Firefox** → **Options** → **High performance** → **Save**
4. (Optional) **Change default graphics settings** → enable **Hardware-accelerated GPU scheduling**, reboot

**✅ Pros**
- Removes the biggest stutter source on hybrid laptops
- Makes hardware video decode and GPU rasterisation actually reachable
- No registry, no driver mods

**⚠️ Cons**
- Battery life drops noticeably — the 4060 idles at a higher floor than the iGPU
- More heat, so the fans spin up sooner on a chassis that is already thermally honest
- If you play on battery, your game now shares a busy GPU with the browser

**Verdict:** keep it while plugged in. On battery, set this back to **Let Windows decide** — see
[two profiles](#two-profiles-plugged-in-vs-battery).

---

## Step 3 — NVIDIA Control Panel: one profile, two fixes

**Why:** the Windows setting decides *which* GPU. The NVIDIA driver decides *how* that GPU behaves, and its
default power management lets the clock fall to idle between frames. On Optimus laptops it can also get the
present method wrong and flicker when Windows switches display modes.

**Do:** NVIDIA Control Panel → **Manage 3D Settings → Program Settings → Add → Mozilla Firefox**:

| Setting | Value | Why |
|---|---|---|
| Preferred graphics processor | High-performance NVIDIA processor | belted *and* braced with step 2 |
| Power management mode | Prefer maximum performance | stops clock ramping between scroll frames |
| Max Frame Rate | Off, or = panel Hz | never let a background app get capped to 20–30 |
| Vulkan/OpenGL present method | Prefer layered on DXGI Swapchain | the actual fix for the black-flash-on-alt-tab |

**✅ Pros**
- The DXGI present method is what kills the classic Optimus flicker
- Per-program: your other apps keep normal power behaviour
- Survives driver updates better than registry tweaks

**⚠️ Cons**
- "Prefer maximum performance" keeps the GPU clocked up — hotter idle, shorter battery
- Panel-specific: on some driver versions the DXGI option makes full-screen games worse, so keep it Firefox-only

**Verdict:** worth it for the flicker fix alone. Skip *power management mode* if you care about battery.

---

## Step 4 — Firefox's own Performance panel (the step everyone forgets)

**Why:** every list jumps straight to `about:config` and skips the GUI that actually controls the process model.

**Do:** `about:preferences` → **General → Performance**
1. Uncheck **Use recommended performance settings**
2. Make sure **Use hardware acceleration when available** is checked
3. **Content process limit** → `8` default, `12` on this CPU/RAM combo

**✅ Pros**
- The only supported, documented way to change the process limit
- Unchecking "recommended" is what makes the limit stick
- Costs nothing, breaks nothing

**⚠️ Cons**
- More content processes = more RAM. 12 processes on 16 GB is comfortable; 16 is not
- Turning hardware acceleration *off* here is a common self-own after a driver bug — remember to turn it back on

**Verdict:** do this before `about:config`, not after. Full detail: [docs/02](docs/02-firefox-performance-settings.md).

---

## Step 5 — The `about:config` prefs that still exist

**Why:** this is the part of the internet that is 60% placebo. These twelve are the ones I could actually
justify — each one is explained, with its default, in [docs/03-about-config.md](docs/03-about-config.md).

Type `about:config` in the address bar, accept the warning, search, change.

| Pref | Set to | What it does |
|---|---|---|
| `gfx.canvas.accelerated.cache-size` | `512` | VRAM budget for canvas surfaces (default 256 MB) |
| `gfx.webrender.software` | `false` | refuse software compositing |
| `gfx.direct2d.disabled` | `false` | keep Direct2D on |
| `dom.ipc.processCount` | `12` | content processes for 20 threads |
| `browser.tabs.unloadOnLowMemory` | `true` | collapse background tabs under pressure |
| `browser.sessionstore.interval` | `60000` | write session state every 60 s instead of 15 s |
| `nglayout.initialpaint.delay` | `0` | start painting immediately (default 5 ms) |
| `nglayout.initialpaint.delay.composite` | `0` | same, for the compositor path |
| `general.smoothScroll.msdPhysics.enabled` | `true` | the newer scroll physics model |
| `media.hardware-video-decoding.enabled` | `true` | use the GPU's decoders |
| `media.wmf.hevc.enabled` | `1` | HEVC through Media Foundation |
| `layers.acceleration.draw-fps` | `true` | **temporary** — on-screen frame counter, for step 10 |

**✅ Pros**
- Small, honest gains: a bit less latency at paint, a bit less disk churn, a way to *see* your frame rate
- All reversible in the same panel; nothing persists outside the profile

**⚠️ Cons**
- Some are marginal — you will not feel `browser.sessionstore.interval`
- `about:config` is unsupported surface: Mozilla can rename or drop any of these between releases
- Copy-pasting a stranger's list (including mine) is how people end up with a 300-line `user.js` they can't debug

**Verdict:** apply the table, skip the rest of the internet's list — and read
[docs/08](docs/08-what-not-to-do.md) for the eight prefs that do nothing.

---

## Step 6 — Make it permanent with `user.js` (optional)

**Why:** `about:config` edits live in `prefs.js` and survive updates, but a profile refresh wipes them. A
`user.js` in the profile folder re-applies a known-good set at every start, which is also how you move the
setup to a new machine.

**Do:** either run the script, or copy [`user.js`](user.js) into the profile folder
(`about:support` → **Profile Folder → Open Folder**).

```powershell
.\scripts\Install-FirefoxTune.ps1
```

**✅ Pros**
- Reproducible: same browser behaviour on any machine, in one file
- Self-documenting — every line says why it is there
- Delete the file and you are back to stock

**⚠️ Cons**
- **It overrides the UI.** Change a pref in `about:config` and it silently reverts next launch. This surprises
  everyone once.
- Adding prefs that don't exist in your build is harmless but useless
- One more thing to remember after a Firefox update

**Verdict:** use it if you reinstall often. Otherwise the manual table is less surprising.
Deep dive: [docs/04-user-js-profiles.md](docs/04-user-js-profiles.md).

---

## Step 7 — `userChrome.css`: snappier menus

**Why:** Firefox's panel and menu animations are tuned for 60 Hz displays. On 165 Hz they are pure latency.

**Do:**
1. `about:config` → `toolkit.legacyUserProfileCustomizations.stylesheets` → `true`
2. In the profile folder, create `chrome\userChrome.css` (this repo has one: [`chrome/userChrome.css`](chrome/userChrome.css))
3. Restart Firefox

**✅ Pros**
- Menus and panels open without the fade
- Tab open/close has no transition delay
- Pure CSS, no extension, no process

**⚠️ Cons**
- **Unsupported API.** It breaks silently after UI updates and nobody owes you a fix
- Only the first few milliseconds change; if menus feel slow, the cause is usually compositing, not animation
- A large stylesheet is parsed on every window open — this is the one tweak that can make startup *slower*

**Verdict:** small, safe if you keep the file tiny. Not a performance fix.
Detail: [docs/05-userchrome-css.md](docs/05-userchrome-css.md).

---

## Step 8 — Extension diet

**Why:** every extension is code injected into pages. Content blockers and style injectors are the two
categories that show up in scroll profiles.

**Do:**
- One blocker only: **uBlock Origin**. Remove AdBlock, AdBlock Plus, Ghostery, Privacy Badger —
  running two blockers means two full filter passes per request
- Delete anything that injects CSS or DOM into every page (dark-mode forcers, font replacers,
  "smooth scroll" extensions — those fight Firefox's native APZ and make things worse)
- Keep filter lists lean; each list is a matching pass on every request

**✅ Pros**
- Cheapest real CPU win in the whole list
- Fewer background timers, less memory, fewer mystery requests
- One blocker also means one place to debug

**⚠️ Cons**
- Losing redundancy feels wrong but is free — uBO alone covers what the duplicates did
- Some sites break without their ad-script and you'll blame the wrong thing

**Verdict:** do it. Detail: [docs/06-extensions.md](docs/06-extensions.md).

---

## Step 9 — Scroll feel (taste, not performance)

**Why:** Firefox's stock wheel curve is deliberately damped. If it feels heavy, this is the dial.

```js
general.smoothScroll.msdPhysics.enabled            true
general.smoothScroll.mouseWheel.durationMaxMS      300    // default 400
general.smoothScroll.mouseWheel.durationMinMS      100    // default 200
general.smoothScroll.currentVelocityWeighting      0      // no easing into the stop
general.smoothScroll.stopDecelerationWeighting     0.82
mousewheel.min_line_scroll_amount                  30
apz.overscroll.enabled                             true
```

**✅ Pros**
- Shorter, more direct scroll animation — feels like a native app
- Costs nothing: it's arithmetic in the compositor

**⚠️ Cons**
- **No default is universal.** These values are build- and taste-dependent; copy them and scrolling may feel
  twitchy on a 60 Hz panel
- Nothing here makes rendering faster — it changes the curve, not the frame budget

**Verdict:** adjust to taste, expect nothing in a benchmark. Detail: [docs/03](docs/03-about-config.md#scrolling).

---

## Step 10 — Measure instead of guessing

**Why:** otherwise you're tuning by vibes, and every placebo will feel like a win.

**Do:**
1. `about:config` → `layers.acceleration.draw-fps` = `true` → on-screen FPS/frame-time counter
2. `about:support` → **Graphics**: Compositing must say `WebRender`, not `WebRender (Software)`
3. `about:processes` → who is eating CPU right now
4. [profiler.firefox.com](https://profiler.firefox.com) → record 10 s of scrolling, look at the Compositor track

**✅ Pros**
- Turns "feels smoother" into a number you can compare
- Catches the real problems (software compositing, one runaway tab) in seconds
- Free, built in, no benchmark install

**⚠️ Cons**
- The FPS overlay itself costs a little; don't leave it on
- Numbers won't capture perceived latency — trust the profiler, then trust your hands

**Verdict:** do this first and last. Detail: [docs/07-measuring.md](docs/07-measuring.md).

---

## Two profiles: plugged in vs battery

Same laptop, two very different goals. Pick the column, not the compromise.

| Setting | 🔌 Plugged in | 🔋 On battery |
|---|---|---|
| Panel refresh | max (165 Hz) | 60 Hz, or let Windows decide |
| Windows GPU for Firefox | High performance (RTX) | Let Windows decide |
| NVIDIA power management | Prefer maximum performance | Optimal power |
| `dom.ipc.processCount` | 12 | 8 |
| `gfx.canvas.accelerated.cache-size` | 512 | 256 |
| uBlock Origin | on | on |
| `userChrome.css` | on | on |

Toggling steps 1–3 by hand is 30 seconds. Everything in steps 5–9 is cheap enough to leave alone.

---

## Install

```powershell
git clone https://github.com/morshedmilton/firefox-butter-smooth.git
cd firefox-butter-smooth
.\scripts\Install-FirefoxTune.ps1
```

The script finds your profile via `profiles.ini`, **backs up `prefs.js` first**, copies `user.js` and
`chrome\userChrome.css`, and refuses to run while Firefox is open. No admin rights, no registry writes.

## Uninstall

```powershell
.\scripts\Restore-FirefoxTune.ps1
```

Deletes `user.js`, disables `chrome\`, restores the newest `prefs.js` backup. Windows and NVIDIA settings are
manual by design — [docs/10-revert.md](docs/10-revert.md) has the exact clicks.

---

## Repo map

```
README.md                        this guide
user.js                          the tuned profile, ~50 commented lines
chrome/userChrome.css            snappy menus (optional)
scripts/Install-FirefoxTune.ps1  profile detection + backup + install
scripts/Restore-FirefoxTune.ps1  one-command undo
docs/01-windows-and-driver.md    refresh rate, GPU choice, HAGS, power plans
docs/02-firefox-performance-settings.md  the GUI step, done properly
docs/03-about-config.md          every pref: default, value, verdict
docs/04-user-js-profiles.md      how user.js works, and why it overrides you
docs/05-userchrome-css.md        what the CSS can and cannot do
docs/06-extensions.md            blocker hygiene, memory, tab pressure
docs/07-measuring.md             FPS overlay, about:processes, profiler
docs/08-what-not-to-do.md        the audit of the file I started from, plus every common no-op
docs/09-troubleshooting.md       flicker, software rendering, video, crashes
docs/10-revert.md                step-by-step undo
```

---

## What this repo is not

- Not a privacy guide. `user.js` here is about frames, not fingerprints.
- Not a benchmark. I did not A/B every pref under a stopwatch; the ranking above is what survived
  repeated use on one machine, plus what `about:support` and the profiler confirmed.
- Not permanent advice. Firefox 160 is a beta; prefs move. If a line here stops existing, delete that line.

If a step didn't help on your machine, that's useful data — open an issue with your `about:support`
**Graphics** block and panel refresh rate.

## Credits

- [Betterfox](https://github.com/yokoffing/Betterfox) — the profile that proved this approach can be
  maintained rather than copy-pasted; this repo's `user.js` is a much smaller, hardware-specific cousin
- Mozilla's [Firefox Profiler](https://profiler.firefox.com) and the `about:support` page
- NVIDIA's Advanced Optimus / DXGI present-method notes, which is where the flicker fix actually comes from

## License

MIT — see [LICENSE](LICENSE). Take it, cut it up, keep the parts that work for you.
