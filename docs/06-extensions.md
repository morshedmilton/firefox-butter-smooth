# 06 — Extensions, memory, and tab pressure

Extensions are the cheapest real performance win available, and the only one where "fewer" always beats
"tuned".

---

## 6.1 One blocker. Not two.

Running two content blockers means two filter databases, two matching passes per request, and two sets of
injected scripts per page. The second one adds nothing except CPU.

**Keep:** uBlock Origin.

**Remove if present:** AdBlock, AdBlock Plus, Ghostery, Privacy Badger, "AdGuard AdBlocker" alongside uBO,
and any vendor "browser assistant" toolbar (those exist mainly to watch what you do).

| | uBO alone | uBO + one more blocker |
|---|---|---|
| Filter passes per request | 1 | 2 |
| Injected scripts per frame | 1 set | 2 sets |
| Debug surface when a site breaks | one toggle | two, and they interact |

Privacy Badger's cookie-learning model is genuinely different from uBO's, but it also rewrites cookies per site
and shows up in profiles on heavy pages. If you want it, run it and check `about:processes` — don't assume.

## 6.2 Keep the filter lists lean

Every enabled list is a matching pass on every request. uBO ships with a sensible default set. Adding five
regional + five "annoyances + 10 custom" lists multiplies matching cost on every page load.

Rule of thumb: if you cannot name a site the list fixed, it is costing you more than it earns.

## 6.3 The extensions that cause scroll jank

Anything that injects CSS or mutates the DOM on every page:

| Extension type | Why it janks |
|---|---|
| "Dark mode for every site" / dark readers | rewrites colours per element, per page, often on scroll-triggered DOM changes |
| Font replacers | forces reflow with a new font metric after load |
| **"Smooth scroll" extensions** | intercepts wheel events in JavaScript and re-implements scrolling above Firefox's native APZ — strictly worse, always |
| Reading-mode / reader-lite clones | re-layout on load |
| "Tab suspender" extensions | duplicates what `browser.tabs.unloadOnLowMemory` already does natively |

That smooth-scroll row is worth repeating: Firefox's scrolling is handled by APZ in the compositor. A JS
extension **cannot** run in that path, so it has to take over the wheel event, scroll in JS, and lose frames
doing it. Native scrolling plus [step 9](../README.md#step-9--scroll-feel-taste-not-performance) is the whole
story.

## 6.4 Memory: what actually helps

| Setting | Where | Effect |
|---|---|---|
| `browser.tabs.unloadOnLowMemory` = `true` | about:config | native background-tab collapse under pressure |
| Content process limit (8–12) | about:preferences → Performance | caps how many tabs stay live |
| `about:processes` | about:processes | shows which tab owns the 900 MB |

Firefox already suspends background tabs' timers. A "memory saver" extension on top of that mostly adds a
process of its own.

**The honest ranking:** closing 20 tabs beats every memory setting in this repo. The settings just make the
inevitable less painful.

## 6.5 Audit your actual load

1. `about:processes` — sort by CPU, then by memory. One tab usually owns most of it.
2. `about:performance` (older builds) shows extensions' own CPU time directly. Where it still exists, it is the
   fastest way to find the extension that costs you frames.
3. Disable half your extensions, restart, compare in the Profiler ([07](07-measuring.md)). Bisect, don't guess.

## 6.6 Extension process isolation

Older lists tell you to set `dom.ipc.processCount.extension` to 2 "to isolate extensions from pages". That pref
belongs to the pre-Fission architecture: with site isolation, extensions already run in their own processes and
the pref is ignored. See [08](08-what-not-to-do.md).

## Checklist

- [ ] Exactly one content blocker (uBlock Origin)
- [ ] No second blocker, no vendor toolbar
- [ ] Nothing injecting CSS/DOM into every page (dark readers, font replacers, smooth-scroll add-ons)
- [ ] Filter lists: only the ones you can justify
- [ ] `about:processes` checked at least once with your normal tab set open
