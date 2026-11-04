# 04 — `user.js` profiles, and why they override you

## What `user.js` is

A plain text file of `user_pref("name", value);` lines in your **profile folder**. Firefox reads it at every
startup and applies each line *after* loading `prefs.js`.

```
profile/
├── prefs.js          <- what the UI writes; Firefox owns this file
├── user.js           <- what you write; Firefox re-applies it every launch
├── chrome/
│   └── userChrome.css
└── storage/  cache/  ...
```

Find the folder: `about:support` → **Profile Folder** → **Open Folder**.

---

## The one thing that surprises everybody

Because `user.js` is applied last, on every launch:

- Change a pref in `about:config` → it reverts on restart.
- Right-click → **Reset** in `about:config` → it comes back on restart.
- Delete a line from `user.js` → the pref *stays* at the value it last had, because it is still in `prefs.js`.

That last one is the important one. Removing a line from `user.js` does **not** restore the default; it just
stops re-forcing it. To truly go back, reset the pref in `about:config` after removing the line, or restore the
`prefs.js` backup the install script made.

This is not a bug. It's what makes the file reproducible — and what makes a 300-line copy-pasted profile
impossible to debug six months later.

---

## This repo's `user.js` vs Betterfox

[Betterfox](https://github.com/yokoffing/Betterfox) is the reference implementation of this idea, and it is
excellent. It is also a different product.

| | this repo | Betterfox |
|---|---|---|
| Size | ~50 lines | 700+ prefs across several profiles |
| Goal | frames and latency on one specific laptop | privacy, security, speed, in that order |
| Scope | GPU path, process model, paint, scrolling | also network, fingerprinting, cookies, DNS |
| Reversibility | delete one file | delete one file, but you need to know what it changed |
| Maintenance | you, when Firefox renames something | a maintainer, weekly |

Use Betterfox if you want a thorough privacy baseline from someone who tracks Mozilla's changes. Use this repo
if you want to know what every line does and why. Do not stack both: two `user.js` files is one file plus a
silent conflict, since the second overwrites the first.

---

## Installing by hand

1. Close every Firefox window. Check Task Manager for `firefox.exe` — a background process will rewrite
   `prefs.js` on exit and undo your work.
2. `about:support` → **Profile Folder → Open Folder**
3. Copy `prefs.js` to `prefs-backup-manual.js` (same folder is fine).
4. Copy [`user.js`](../user.js) from this repo into the folder.
5. Start Firefox.

## Installing with the script

```powershell
.\scripts\Install-FirefoxTune.ps1
```

It resolves the profile from `profiles.ini`, checks that Firefox is closed, copies `prefs.js` to
`prefs-backup-<timestamp>.js`, backs up any existing `user.js`, then installs both files. If it cannot find a
profile (a Firefox that has never been launched has none), it says so instead of guessing.

Target a specific profile:

```powershell
.\scripts\Install-FirefoxTune.ps1 -ProfilePath 'C:\Users\me\AppData\Roaming\Mozilla\Firefox\Profiles\xxxx.default-beta'
```

See what it found without changing anything:

```powershell
.\scripts\Install-FirefoxTune.ps1 -List
```

### Why the choice of profile is not obvious

`profiles.ini` can disagree with itself, and it usually does on a machine that has run more than one Firefox
channel. Real example from this laptop:

```ini
[Profile0]
Name=default-beta
Path=Profiles/rrvij9rw.default-beta        <- the one the Beta install actually uses

[Profile1]
Name=default
Path=Profiles/y6k8mjd1.default
Default=1                                   <- the one the profile picker calls default

[InstallB16F9810555E63E5]
Default=Profiles/rrvij9rw.default-beta      <- and this is the binding that wins
```

A script that trusts `Default=1` configures the wrong browser on this machine — silently. Firefox resolves the
`[Install<hash>]` binding first, so the installer does the same, prints which binding it used, and refuses to guess
when more than one install is present.

---

## Updating

Mozilla renames or drops prefs regularly. Once a year, or after a big update:

1. `about:config` → search each pref name from [03](03-about-config.md)
2. A pref that no longer exists is dead weight — delete the line, nothing breaks
3. A pref whose *default* changed: read it, decide again

Dead lines are harmless (Firefox ignores unknown prefs), which is exactly why nobody notices them rotting.

---

## Uninstalling

```powershell
.\scripts\Restore-FirefoxTune.ps1
```

Renames `user.js` out of the way, disables `chrome\userChrome.css`, copies the newest `prefs.js` backup back
over the current one. Windows and NVIDIA changes are not touched — [10](10-revert.md).

Nuclear option, if the profile is a mess and you don't care what else is in it: `about:support` → **Refresh
Firefox**. It keeps bookmarks, passwords and extensions, resets prefs and removes `user.js`. The `chrome`
folder survives a refresh, so delete it yourself afterwards.
