# 09 — Troubleshooting

Symptoms first, causes second. Every fix here is reversible; if it doesn't help, undo it before trying the next.

---

## Firefox says `WebRender (Software)` in about:support

The browser has fallen back to CPU compositing. Nothing else you tune will matter until this is fixed.

1. **Driver.** Update the GPU driver from the vendor directly, not through Windows Update. Use a
   clean install ("Perform a clean installation" in the installer) if the version has been the same for a year.
2. **GPU blocklisted by Firefox.** `about:support` → **Decision Log** will name the reason
   (`FEATURE_FAILURE_...`). The log is the diagnosis; don't guess.
3. **Safe mode.** `firefox.exe -safe-mode` (or Help → Troubleshoot Mode). If compositing works there, an
   extension or `user.js` is the cause.
4. **Only then, as a diagnostic:** `media.hardware-video-decoding.force-enabled = true` or
   `gfx.webrender.all = true`. If these "fix" it, the real fix is the driver.

---

## Black flash / brief flicker when a game opens, or on alt-tab

This is Optimus, not Firefox.

1. NVIDIA Control Panel → Firefox profile → **Vulkan/OpenGL present method = Prefer layered on DXGI Swapchain**
2. Confirm Windows Graphics is set to *High performance* for `firefox.exe` ([01](01-windows-and-driver.md))
3. If the whole screen flashes (not just Firefox), it's the display mode switch — check
   `Display → Change resolution` for "Perform a scaling on: GPU" vs "Display", and try the other one
4. Still flashing: G-Sync in **windowed** mode. Turn windowed off.

---

## Video: green frames, black video, or "software decoding"

| Symptom | Likely cause | Fix |
|---|---|---|
| Green/pink blocks | driver + hardware decode mismatch | `media.hardware-video-decoding.enabled = false` to confirm, then update the driver |
| HEVC won't play | missing codec pack | install **HEVC Video Extension** from the Store, keep `media.wmf.hevc.enabled = 1` |
| AV1 choppy at 4K | no hardware AV1 decode, or dav1d on a busy CPU | check `about:support` → **Media**; close other CPU-heavy tabs |
| Video fine, page janky | the page, not the codec | profiler ([07](07-measuring.md)) |

Check the codec actually in use: YouTube → right-click → **Stats for nerds** → `avc1` (H.264), `vp09` (VP9),
`av01` (AV1), plus a "dropped frames" counter.

---

## High idle CPU, or the fan spins up while reading

1. `about:processes` → sort by CPU. One tab, or an extension?
2. Kill the obvious: a dashboard, a video paused in a background tab, a chat app.
3. If the **GPU process** is the busy one at idle, that's a driver bug — update, or roll back one version.
4. If nothing is busy but the fan still runs, it's the dGPU idle floor from step 2. That's the cost of the
   plugged-in profile; the battery profile removes it.

---

## Scrolling stutters on one specific site

1. Does it stutter in a private window with extensions disabled? → an extension ([06](06-extensions.md))
2. Does it stutter at 60 Hz but not at the panel's max? → refresh rate
3. Profile the scroll: long **Frame** markers with the page's own JS on the stack means the site, not you.
4. Sites with sticky headers, `backdrop-filter`, and scroll-linked animations are simply expensive. Nothing in
   `about:config` fixes them.

---

## Firefox won't start, or starts to a blank window

1. `firefox.exe -safe-mode` — if it starts, disable extensions and check `user.js`
2. Rename `user.js` out of the profile folder and retry
3. Rename `chrome/` to `chrome.disabled` and retry
4. `about:support` → **Refresh Firefox** — keeps bookmarks/passwords, resets everything else

---

## Menus still feel slow after the CSS

Check, in order:

1. `toolkit.legacyUserProfileCustomizations.stylesheets` is `true`
2. The file is at `<profile>/chrome/userChrome.css` — lowercase `chrome`, exact filename
3. Firefox was fully restarted (all windows closed)
4. Compositing is `WebRender`, not software
5. If those four are true and it still feels slow, the CSS wasn't the problem — [07](07-measuring.md)

---

## After a Firefox update, things got worse

The most common causes, in order:

1. **A pref was renamed or removed.** Compare [03](03-about-config.md) against `about:config`; delete dead lines.
2. **A UI update broke `userChrome.css`.** Disable `chrome/` and see if the "problem" was the theme.
3. **The driver got reinstalled** by Windows Update → back to the iGPU, back to software composition. Check
   `about:support` first, always.

**Beta channel note:** if you run a Beta build, prefs get renamed there first. If a step
worked one release and stopped the next, suspect the pref, not the hardware.

---

## The nuclear options, in increasing order of destruction

| Option | Keeps | Loses |
|---|---|---|
| `Restore-FirefoxTune.ps1` | everything | this repo's prefs |
| `about:support` → **Refresh Firefox** | bookmarks, passwords, extensions | all prefs, `user.js` (not `chrome/`) |
| New profile (`about:profiles` → Create) | the old profile, intact | nothing — you just start clean |
| Delete the profile folder | nothing | everything, unless you backed up `bookmarks.html` and `logins.json` |

Try them top to bottom. People jump to the last one and then spend an evening re-logging-in to things.
