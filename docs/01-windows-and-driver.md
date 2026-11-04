# 01 — Windows and the driver

Everything on this page changes how the *system* hands frames to Firefox. It is worth more than every pref in
`about:config` combined, and it survives Firefox updates.

Order matters: refresh rate → GPU choice → driver profile → power policy.

---

## 1.1 Refresh rate

`Win + I` → **System → Display → Advanced display** → **Choose a refresh rate**.

| What you see | What it means |
|---|---|
| 60 Hz only | the panel is capped by a power plan, or you are on an external display that cannot do more |
| A list like 60 / 120 / 144 / 165 / 240 / 360 | Pick the highest offered — that's your panel's real maximum. |
| A "Dynamic refresh rate" toggle | Lets Windows drop to 60 Hz on battery. Nice for power, can feel inconsistent while scrolling |

A 165 Hz panel gives you **6.1 ms** per frame; a 360 Hz panel gives **2.78 ms**. That budget is shared by the
compositor, the content processes and every extension — which is why this guide cares about 3 ms stalls that
would be invisible at 60 Hz.

Two failure modes worth knowing:

- **Only 60 Hz offered.** Usually a driver reinstall: Windows falls back to the generic monitor driver and hides
the high-refresh modes. Reinstall the GPU driver, then re-check.
- **Capped below what the panel supports.** Link bandwidth, not Firefox. 1080p at 360 Hz fits DisplayPort 1.4 and
internal eDP, but not HDMI 2.0 (which tops out near 240 Hz at that resolution). Check cable and port first.

**Verify, don't assume.** After a driver update or a dock, Windows can silently go back to 60 Hz. Check this
first whenever the browser "suddenly feels worse" — it is almost always this.

---

## 1.2 Which GPU gets Firefox

`Win + I` → **System → Display → Graphics** → **Browse** → `C:\Program Files\Mozilla Firefox\firefox.exe` →
**Options** → **High performance** → **Save**.

This is a Windows per-app preference. It is respected regardless of what the NVIDIA driver would have chosen,
and it applies to the whole process tree Firefox spawns (content processes, GPU process).

### What "Automatic MUX / Advanced Optimus" actually does

In hybrid mode:

```
app  ->  dGPU renders  ->  frames copied to  ->  iGPU  ->  panel
```

The copy is the price of hybrid graphics. Forcing Firefox onto the dGPU does not remove that copy — it only
changes *which* GPU does the rendering. What you gain is the dGPU's fill rate for compositing, canvas, WebGL
and video decode. What you pay is idle power: the dGPU does not reach the iGPU's idle floor.

### When *not* to do this

- On battery, most of the time. The iGPU renders a browser perfectly well at 60 Hz.
- If you hear fans ramp up while reading a docs page. That is the dGPU idle power, and it is normal.

Set it back to **Let Windows decide** for the battery profile — 15 seconds of work.

---

## 1.3 Hardware-accelerated GPU scheduling (HAGS)

`Win + I` → **System → Display → Graphics** → **Change default graphics settings** → **Hardware-accelerated
GPU scheduling** → On → reboot.

- **Pros:** lower submission latency, less CPU work per frame.
- **Cons:** on some driver branches it causes stutter in video playback or in VMs. If anything regresses,
  this is the first switch to flip back.
- **Verdict:** try it; keep it only if the profiler agrees.

---

## 1.4 NVIDIA Control Panel

`Manage 3D Settings` → tab **Program Settings** → **Add** → `firefox.exe`.

| Setting | Plugged in | Battery | Note |
|---|---|---|---|
| Preferred graphics processor | High-performance NVIDIA processor | Integrated graphics | belt and braces with 1.2 |
| Power management mode | Prefer maximum performance | Optimal power | stops clock ramping between frames |
| Max Frame Rate | Off, or = panel Hz | Off | never allow a 20–30 FPS cap |
| Vertical sync | Use the 3D application setting | same | Firefox syncs to the compositor; forcing Off tears |
| Vulkan/OpenGL present method | Prefer layered on DXGI Swapchain | same | **the** Optimus flicker fix |
| Low Latency Mode | Off | Off | browsers batch; low-latency mode fights that |

### The flicker fix, explained

On Optimus laptops the driver sometimes presents frames directly to the panel and sometimes through the iGPU.
When the present method changes mid-session — exactly what happens when Windows flips display modes for a game —
you get a black flash or a brief resize. Pinning the present method to the DXGI swapchain path keeps it
consistent. This is the one NVIDIA setting that fixes a *visible* bug rather than buying a fraction of a frame.

### G-Sync / VRR

If the panel supports it, `Display → Set up G-SYNC`:

- **Enable for full screen mode** — safe.
- **Enable for windowed and full screen mode** — can cause brightness flicker on windowed browsers and
  desktop apps on some panels. Try it; if the screen pulses while scrolling, turn windowed off.

VRR plus `layout.frame_rate = -1` is the correct pair. A pinned `layout.frame_rate` breaks the whole point of
a variable-refresh panel — see [08](08-what-not-to-do.md).

---

## 1.5 Power policy (gaming laptops)

`Win + R` → `powercfg.cpl` → **Power Options**.

| Plan | Effect here |
|---|---|
| Balanced | correct default; Windows 11 handles boost well |
| High performance | slightly higher idle clocks, negligible gain, more heat |
| Ultimate Performance | hides on most laptops; adds heat for no latency win |
| Power saver | caps the CPU hard; scrolling gets worse, not better |

On a high-power HX-class CPU in a slim gaming chassis the bottleneck is **thermal headroom**, not power limits. Raising the power
ceiling buys a few hundred MHz for a few seconds and then the fan curve takes it back. If you want sustained
smoothness, the useful knobs are:

- Dell **thermal mode** (via MyDell or the F9/Fn+F9 shortcut on some SKUs): Quiet / Balanced / Performance / G.
  Performance or G raises the fan floor and holds clocks — that is a real gain for browser smoothness on a
  laptop that has been idling in Quiet mode.
- Cleaning the vents. Unglamorous, measurable.

`powercfg /batteryreport` before/after any of this if you care about the battery cost of the dGPU profile.

---

## Checklist

- [ ] Panel at its **maximum refresh rate**, verified in Settings
- [ ] `firefox.exe` set to High performance (plugged-in profile)
- [ ] HAGS on, then profiled for regressions
- [ ] NVIDIA program profile created, present method = DXGI swapchain
- [ ] Thermal mode set to Performance/G if the machine idles in Quiet
- [ ] Battery profile written down so you can switch back in 15 s
