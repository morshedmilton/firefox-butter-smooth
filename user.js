// =============================================================================
//  firefox-butter-smooth · user.js
//
//  Tested on: Firefox 160.0 Beta, Windows 11 x64, one 16 GB hybrid-GPU laptop
//  Values that depend on RAM (process count, canvas cache) are annotated - scale
//  them for your machine; everything else is hardware-independent.
//
//  WHERE THIS GOES
//    about:support -> "Profile Folder" -> Open Folder -> drop this file there.
//    Or run scripts/Install-FirefoxTune.ps1, which does it and backs up first.
//
//  HOW IT BEHAVES
//    Firefox re-applies this file on EVERY start, and it wins over anything
//    you change in about:config. If a pref below "keeps coming back", this
//    file is why. That is the deal: reproducibility in exchange for surprise.
//
//  TO UNDO
//    Close Firefox -> delete this file -> reopen. Nothing else is touched.
//    (about:config values already written stay until you reset them; the
//    install script keeps a prefs.js backup for that.)
//
//  RULE FOR EDITING
//    Only put a line here if you can say what it changes in one sentence.
//    Lines that no longer exist in your build are ignored silently - they are
//    not errors, they are just dead weight. See docs/08 for the usual suspects.
// =============================================================================


// --- 1. Compositing: stay on the GPU -----------------------------------------
// If any of these are "true", Firefox is quietly rasterising on the CPU, which
// is the real reason some setups feel sluggish no matter what you set elsewhere.
user_pref("gfx.webrender.software", false);
user_pref("gfx.direct2d.disabled", false);
user_pref("layers.acceleration.disabled", false);
user_pref("gfx.canvas.accelerated", true);
// VRAM reserve for canvas surfaces, MB. Default 256. 512 is comfortable for
// 8 GB and helps canvas-heavy dashboards/maps; do not raise it on 4 GB cards.
user_pref("gfx.canvas.accelerated.cache-size", 512);


// --- 2. Process model --------------------------------------------------------
// Default is 8. This CPU has 20 threads and the machine has 16 GB, so 12 is
// the useful ceiling: more parallel pages, still no swapping. 16+ starts to
// cost more in RAM than it returns.
user_pref("dom.ipc.processCount", 12);
// Site isolation. Leave it true; disabling it is a security downgrade, not an
// optimisation, and it does not buy frames on this hardware.
user_pref("fission.autostart", true);
// Let Firefox collapse background tabs instead of swapping to disk.
user_pref("browser.tabs.unloadOnLowMemory", true);
// Session state writes: 15 s -> 60 s. Fewer small disk writes, cheaper on the
// SSD, invisible in use. You lose at most 60 s of tab state on a hard crash.
user_pref("browser.sessionstore.interval", 60000);


// --- 3. Paint latency --------------------------------------------------------
// How long Firefox waits before the first paint. Default is 5 ms on current
// builds (250 ms in very old ones). Zero starts drawing immediately; the
// trade-off is a slightly higher chance of a visible reflow on slow pages.
user_pref("nglayout.initialpaint.delay", 0);
user_pref("nglayout.initialpaint.delay.composite", 0);


// --- 4. Scrolling feel (taste - not a performance change) --------------------
user_pref("apz.overscroll.enabled", true);
// The newer MSD physics model, closer to a native app than the legacy curve.
user_pref("general.smoothScroll.msdPhysics.enabled", true);
// Shorter animation window per wheel notch. Defaults: 400 / 200.
user_pref("general.smoothScroll.mouseWheel.durationMaxMS", 300);
user_pref("general.smoothScroll.mouseWheel.durationMinMS", 100);
// No easing into the stop - the scroll tracks your wheel and stops when you do.
user_pref("general.smoothScroll.currentVelocityWeighting", 0);
user_pref("general.smoothScroll.stopDecelerationWeighting", 0.82);
// Pixels per "line scroll". Stock feel is ~3 lines per notch; 30 px makes a
// notch travel further. Pure preference - delete the line if scrolling flies.
user_pref("mousewheel.min_line_scroll_amount", 30);
// Do NOT pin layout.frame_rate to your panel Hz. -1 means "follow the display
// and vsync", which is what you want on a 360 Hz panel, and pinning it is
// a classic source of judder and tearing. Mentioned here so nobody adds it.
user_pref("layout.frame_rate", -1);


// --- 5. Video decode ---------------------------------------------------------
user_pref("media.hardware-video-decoding.enabled", true);
// HEVC through Windows Media Foundation. Needs the HEVC Video Extension from
// the Store to actually decode HEVC; otherwise the pref is inert.
user_pref("media.wmf.hevc.enabled", 1);
// Deliberately NOT set: media.hardware-video-decoding.force-enabled = true.
// It bypasses Mozilla's driver blocklist, which exists because some drivers
// produce green frames. Turn it on only if about:support says you fell back to
// software decode, and expect to turn it back off. See docs/09.
// Also deliberately NOT set: media.ffvpx.enabled = false. That disables
// Firefox's bundled decoders; it does not enable hardware decode. docs/08.


// --- 6. Startup --------------------------------------------------------------
// Keep the Windows skeleton window. It draws a lightweight frame while the
// real UI loads, which is why launch feels instant. Setting it to false (as
// some lists suggest, "to speed up launch") does the opposite.
user_pref("browser.startup.preXULSkeletonUI", true);


// --- 7. Background noise -----------------------------------------------------
// Not performance-critical on 20 threads, but every one of these is a timer,
// a network request, or a disk write you did not ask for.
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
// Address-bar suggestions. Set to true if you actually use Firefox Suggest.
user_pref("browser.urlbar.quicksuggest.enabled", false);
// Pocket is on its way out of Firefox; the pref is harmless if it is already gone.
user_pref("extensions.pocket.enabled", false);


// --- 8. UI -------------------------------------------------------------------
// Required for chrome/userChrome.css to be read at all. Without this it is a
// text file Firefox never opens.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Expose the compact density option in Customize Toolbar.
user_pref("browser.compactmode.show", true);
// Uncomment for compact mode by default (more page, fewer pixels):
// user_pref("browser.uidensity", 1);


// =============================================================================
//  NOT SET ON PURPOSE - the internet will tell you to set these
//  They are no-ops on current builds, or actively wrong. Reasons in docs/08.
//
//    gfx.webrender.all                       - WebRender is always on now
//    layers.acceleration.force-enabled       - legacy Layers compositor, gone
//    dom.ipc.processCount.extension          - pre-Fission, ignored
//    gfx.content.azure.backends              - the Azure backend was removed
//    content.notify.interval                 - micro-tuning, unmeasurable
//    browser.tabs.remote.autostart           - multiprocess is mandatory
//    browser.ping-centre.telemetry           - that component was removed
//    image.mem.decode_on_draw                - not present in current builds
//    media.ffvpx.enabled = false             - breaks fallback, no GPU gain
//    browser.startup.preXULSkeletonUI = false- slower launch, not faster
//    layout.frame_rate = <your Hz>           - judder/tearing on high-Hz panels
// =============================================================================
