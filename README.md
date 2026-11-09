# Guilty ⚖️

A native Mac focus timer built with SwiftUI. Set a countdown, keep distractions on trial, and get back to your work.

## Run

Requires macOS 13 or newer and Xcode or the Swift command-line tools to build. No third-party packages are needed.

```sh
./scripts/build-app.sh
open dist/Guilty.app
```

The script builds an app for your Mac’s architecture and signs it locally. You can move `dist/Guilty.app` into Applications. This is a local build, not a notarized public download. Open `Package.swift` in Xcode to edit the project.

## Use

1. Review **Apps on trial** and **Words on trial** before starting. YouTube and common entertainment sites are included.
2. Use **Add app** to choose games or other distractions. **Find games** scans `/Applications` and `~/Applications` for apps with a declared game category. Some games do not declare one, so add those manually.
3. Pick a preset or enter a custom time from 1 to 480 minutes. Click **Start focus session**.
4. When macOS asks, let Guilty control your browser. This permission reads the active tab’s URL. If denied, enable it in **System Settings → Privacy & Security → Automation**. The status text reports browser failures.
5. Opening a blocked app or site hides its application and brings up **You R Found Guilty**.
6. Choose **Back to focus** to leave it blocked. The small **Wrongly Accused** button allows the current visit only. Switching to another app clears the pass. For websites, changing the active tab, window, or URL also clears it. Returning brings up a fresh warning.

**Pause / Resume** freezes or continues both the countdown and blocking. **Reset** restores the original session length (and stays paused if already paused). **End timer** stops the session. These controls are also in the menu bar. Blocklists cannot be edited while a running or paused session exists.

Visit passes are held only in memory; reopening Guilty never restores a pass. Old saved session-wide exceptions are ignored. Browser checks are polled, so a tab switch away and back between checks may not be detected. Reloading an unchanged URL in the same tab is treated as the same visit.

Closing the window keeps Guilty running in the menu bar. Quitting asks for confirmation during a session. An absolute end time is saved, so sleeping or reopening the app does not restart the countdown.

## What protection covers

- Checks the frontmost app and supported browser about every 0.6 seconds. Browser replies may take longer.
- Reads active tabs in Safari, Chrome, Edge, Brave, Vivaldi and Opera through AppleScript. Browser permission is required for each browser.
- Hides a blocked application; does not terminate it, close tabs, or stop background audio/downloads.
- Matches each guilty keyword anywhere in the full URL, ignoring letter case, including paths, search terms, fragments, and percent-decoded text. For example, `fandom` matches `myfandom.org` and `school.org/search?q=fandom`. This does not classify page content: a fan site without a listed word in its URL needs another keyword.
- Existing domain rules are converted to names once, and `fandom` is added. Short links `youtu.be` and `x.com` stay as full keywords; `twitter` is also included in new default lists. This avoids using the single letter `x` as a rule.
- Enter a word such as `fandom` or paste a website address to extract its name. Broad matching also catches unrelated sites whose URL happens to include a listed word; Wrongly Accused still allows only that visit.
- Unsupported browsers, including Firefox, can be blocked as whole apps using **Add app**.
- Uses editable lists, not automatic classification of all entertainment content.

This is a self-control tool, not an unbreakable system restriction. A page may load briefly before it is hidden. Quitting or force-quitting Guilty stops enforcement. Denied browser permissions prevent website checks; the app reports this in its status. A network filter or browser extension would be needed to stop requests before pages load.

## Privacy

No server, analytics, or network service. URLs are checked in memory and are not saved. Lists, the timer deadline, and paused time are stored locally in `~/Library/Application Support/Guilty/session.json`.

## Tests

```sh
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache" \
swift test --disable-sandbox
```

Tests cover full-URL keyword matching, encoded URLs, keyword migration, input normalization, visit-pass expiry, pause/resume/reset/end, old-session migration, duration limits, and saved-session round trips. Live browser permission prompts and app hiding need a manual check on the target Mac.

Manual check: add a harmless app, start a one-minute session, open it, verify the guilty screen, switch to it again without dismissing the screen, and verify it is still hidden. Choose Wrongly Accused and verify the current visit stays usable. Switch to another app and return: the warning should appear again. Verify Pause freezes time and stops blocking, Resume continues, Reset restores the chosen duration, and End clears the session. Repeat with a listed website in each browser you use, including testing permission denial.

App monitoring uses Apple’s [NSWorkspace API](https://developer.apple.com/documentation/appkit/nsworkspace).

The app includes a shield-and-gavel icon for Finder, the Dock, and Spotlight. The build script generates all icon sizes from `scripts/make-icon.swift`. If Spotlight keeps an old icon, quit the app and reopen the rebuilt copy; moving that copy to Applications also makes it easier to find.
