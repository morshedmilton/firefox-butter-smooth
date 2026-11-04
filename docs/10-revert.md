# 10 — Revert

Everything in this repo is reversible. This page is the exit.

Order matters: undo in reverse — Firefox first, then the driver, then Windows.

---

## Profile side (one command)

```powershell
.\scripts\Restore-FirefoxTune.ps1
```

What it does:

1. Refuses to run while Firefox is open
2. Renames `user.js` → `user.js.removed-<timestamp>`
3. Renames `chrome/userChrome.css` → `userChrome.css.disabled-<timestamp>`
   (`-RemoveChrome` deletes the folder instead)
4. Copies the newest `prefs-backup-*.js` back over `prefs.js`, after saving the current one as
   `prefs-before-restore-<timestamp>.js`

Nothing is deleted, so you can put it all back by renaming two files.

---

## Manual undo, step by step

| Step | How to undo | Time |
|---|---|---|
| 10. Measuring | `layers.acceleration.draw-fps` → `false` | 10 s |
| 9. Scroll feel | `about:config` → right-click each pref → **Reset** | 1 min |
| 8. Extension diet | reinstall whatever you removed | — |
| 7. `userChrome.css` | delete the file, restart. Optionally `toolkit.legacyUserProfileCustomizations.stylesheets` → `false` | 30 s |
| 6. `user.js` | delete the file (values already applied stay — reset them in `about:config` or restore `prefs.js`) | 30 s |
| 5. `about:config` prefs | right-click → **Reset** per pref, or restore the `prefs.js` backup | 2 min |
| 4. Performance panel | re-tick **Use recommended performance settings** | 10 s |
| 3. NVIDIA profile | NVIDIA Control Panel → Firefox → **Remove**, or **Restore** defaults | 1 min |
| 2. GPU choice | Settings → Display → Graphics → Firefox → **Let Windows decide** | 30 s |
| 1. Refresh rate | Settings → Display → Advanced display → pick 60 Hz | 10 s |

---

## Resetting a single pref properly

`user.js` complicates this, so be explicit about which case you're in:

**With `user.js` still installed:** editing `about:config` does nothing — it reverts at next start. Remove the
line from `user.js` (or the whole file) **first**, restart, then reset in `about:config`.

**Without `user.js`:** `about:config` → search → right-click the row → **Reset**. The row returns to its
build default, or disappears entirely if the pref is default-valued.

---

## The complete reset

If the profile is beyond reasoning with:

1. `about:support` → **Refresh Firefox** → confirm
   - keeps: bookmarks, history, passwords, cookies, extensions
   - loses: pref changes, `user.js`, custom toolbar layout
   - **survives:** the `chrome/` folder — delete it by hand or your CSS keeps loading
2. Verify `about:support` → Graphics still shows `WebRender` and the RTX
3. Re-apply only what you actually missed

---

## Windows side, in full

1. **Refresh rate:** `Win + I` → System → Display → Advanced display → 60 Hz
2. **GPU preference:** System → Display → Graphics → Firefox → **Let Windows decide**
3. **HAGS:** System → Display → Graphics → Change default graphics settings → Off → reboot
4. **NVIDIA:** Control Panel → Manage 3D Settings → Program Settings → Firefox → **Remove**
5. **G-Sync:** Display → Set up G-SYNC → reset to default
6. **Power plan:** `powercfg.cpl` → Balanced
7. **Thermal mode:** Dell/MyDell → back to Balanced

None of this touches the Firefox profile, and none of it requires admin rights except HAGS.

---

## What cannot be undone

Being honest about the limits:

- **Time spent.** No restore point for that.
- **A `prefs.js` restore is not a clean default profile.** It restores prefs *as they were when the backup ran*,
  which includes whatever you had before installing this repo. That's usually what you want; it is not the same
  as "factory default".
- **Refresh Firefox throws away your pref history**, so save `prefs.js` somewhere before doing it if you might
  want to diff later.

---

## Verify you're clean

```
about:support -> Graphics: Compositing = WebRender, GPU #1 = your usual GPU
about:config  -> search "nglayout.initialpaint.delay" -> back to 5
profile folder -> no user.js, no chrome/userChrome.css
```

If all four are true, the machine is back to how it shipped — minus the browser history you made reading this.
