# 02 — Firefox's own Performance settings

`about:preferences` — or for normal humans: **☰ menu → Settings → General**, then scroll to **Performance**.

This panel controls the process model. Every pref list online skips it and jumps to `about:config`, which is
backwards: `dom.ipc.processCount` in `about:config` is ignored while "Use recommended performance settings" is
ticked, because the UI overwrites it.

---

## 2.1 The three controls

| Control | Set to | Why |
|---|---|---|
| **Use recommended performance settings** | **unchecked** | unlocks the two below |
| **Use hardware acceleration when available** | **checked** | without it, everything renders on the CPU |
| **Content process limit** | `8` default, `12` here | parallel pages, without swapping |

If **Use hardware acceleration when available** is missing entirely, Firefox has blocklisted your GPU driver.
That is not a setting problem — see [09-troubleshooting](09-troubleshooting.md).

---

## 2.2 How many content processes?

Each content process costs roughly 120–250 MB resident once a page is loaded, more on heavy sites. Firefox's
default is 8. The reference machine had 20 threads and 16 GB — an ordinary gaming laptop.

| Limit | Processes | Rough RAM ceiling | Verdict |
|---|---|---|---|
| 4 | 4 | ~1 GB | for 8 GB machines, or battery saving |
| 8 | 8 | ~2 GB | **default; correct for most people** |
| 12 | 12 | ~3 GB | **16 GB or more, plugged in** |
| 16+ | 16+ | ~4 GB+ | returns nothing; raises the chance of swap |

Processes are not threads: 12 processes on 20 threads still leaves the compositor and GPU process room. Past
12 you are mostly paying RAM for the ability to keep 16 tabs unloaded-but-alive, which
`browser.tabs.unloadOnLowMemory` already handles more cheaply.

**How to check the real number:** `about:processes` lists every process with its own memory column. If the
total sits near your RAM ceiling while you browse normally, drop the limit.

---

## 2.3 Reading `about:support` → Graphics

This block is the ground truth. Open `about:support`, scroll to **Graphics**.

| Field | Good | Bad |
|---|---|---|
| `Compositing` | `WebRender` | `WebRender (Software)` |
| `WebRender` | `true` | `false` |
| `GPU #1` | your dGPU | only the iGPU |
| `GPU #2` | Intel UHD | absent |
| `Driver Version` | current branch | anything from 2024 |
| `Failure Log` / `Decision Log` | empty or informative | `blocklisted`, `ANGLE_...`, `NO_CONSTANT_BUFFER_OFFSETTING` |

`WebRender (Software)` means: no GPU compositing, every frame rasterised on the CPU. On a modern HX-class CPU that still
works, which is why people live with it for months without noticing — the browser just feels heavy. If you see
it, fix that before touching a single pref.

---

## 2.4 Things in this panel nobody should change

- **"Use recommended performance settings" back on** — it will silently undo your process limit. Fine as a
  reset, not as a setting.
- **Turning hardware acceleration off to "fix" a glitch** — sometimes right for one broken driver, always wrong
  as a permanent state.
- **`gfx.webrender.software = true`** — same mistake with extra steps.

---

## Checklist

- [ ] Recommended settings unchecked
- [ ] Hardware acceleration checked
- [ ] Content process limit matches your RAM (8 default, 12 max here)
- [ ] `about:support` shows `Compositing: WebRender`
- [ ] `GPU #1` is the RTX, not the iGPU
