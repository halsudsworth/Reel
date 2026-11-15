# Changelog

## 1.2.1

- New event tracker: joined events that are running get their own box, like the quest tracker, instead of a line on the fishing bar. Each event shows its progress and the time left; a checklist shows each of its lines. Drag the title to move it, click it to fold it up. Untrack on the Events tab hides an event from it.
- Timed dash events (most fish in your best few minutes) are counted, with your best run and your last few minutes on separate lines.
- Clean view can keep the event tracker visible (Clean view tab, Keep visible in clean view).
- The bar's catch count now reads "21 fish this session".
- Mithril Bound Trunk, Bloated Mightfish and Ravaged Fishing Pole are on the catch list.

## 1.2.0

- New Events tab: join an event or tournament by pasting its event code from halsudsworth.com (Copy event code on the event's page). Joined events can be tracked on the fishing bar while they run, with your progress and the time left, and your journal paste is scored for them. Untrack keeps an event joined but off the bar. `/reel event` and the minimap menu open the tab.
- The Bar page scrolls when its checkboxes run past the bottom of the window.

## 1.1.3

- Guild hello: a moment after login, R.E.E.L. says hello to your guild, and guildmates running R.E.E.L. answer. A chat line lists who answered; `/reel guild` lists everyone heard from.

## 1.1.2

- Fixed: characters who haven't learned fishing no longer see "Fishing ?" on the bar.
- Fixed: a sharpening stone, weightstone or poison on a weapon was shown as a lure. The lure timer now only counts with a fishing pole in hand.

## 1.1.1

- The lure button and the lure choice on the Bar page know "Secret" Bait, the new +25 lure in Forever.

## 1.1.0

- Fixed: the lure button on the R.E.E.L. bar now sits inside the gold border instead of covering its left edge.
- Right-click the minimap button for quick settings: show or lock the R.E.E.L. bar, Clean View, the splash booster, and Export journal.
- Your journal now keeps the full text of Riggle Bassbait's winner yell, not only the winner's name.
- Fixed: an error about a secret string when Riggle Bassbait yelled.
- Fixed: the "Done fishing after" slider on the General page no longer hangs off the left edge.

## 1.0.1

- Fixed: fish tooltips now name a recipe vendor of your faction, nearest first, instead of always the first one listed.
- Fixed: an error about secret auras when a mob attacked you while fishing.

## 1.0.0

The release for the launch of World of Warcraft: Forever.

- Clean View, the immersion settings and the presets.
- The bar, the lure button and one-key fishing.
- The journal: every catch with time, place, skill and level, Records and Feats.
- `/reel export` for the leaderboards and events on halsudsworth.com.
- Fixed: Max graphics changed nothing on Forever.
- Fixed: the Toggle clean view key works whether or not Clean View is on for casting.
- Leaving Clean View (moving, Escape, Show UI) brings names, sound and graphics back at once, not 20 seconds later.
- One key reels in only with the game's Enable Interact Key on (Options > Gameplay > Controls); R.E.E.L. now says so once in chat if it's off.

## 1.0.0-rc.5

- The journal counts your casts and catches at each fishing skill in every spot, lure and gear included, so the site can work out the skill each zone needs.

## 1.0.0-rc.4

- A catch right after a loading screen, when the game hasn't named the zone yet, is logged under Unknown instead of breaking the export.
- The fishing camera is remembered per character, so logging in on an alt no longer moves its camera.
- The clear-all warning says what goes: journals, records, derby coins and Riggle's winners, for every character on the account.
- An event the game client doesn't have is skipped and listed in `/reel debug`, instead of stopping the addon from loading.
- No errors if the saved data couldn't be loaded.

## 1.0.0-rc.3

- The fish data is rebuilt. Each fish knows the zones where it's a real catch and where to go for it.
- "Zone fish" on the bar counts only fish that are a real catch in the zone: rare traces no longer count.

## 1.0.0-rc.2

- Catches with auto-loot on are logged in the journal.
- `/reelfish` opens the settings too, for when another addon also uses `/reel`.
- The export carries your region and realm IDs, so the site can tell characters with the same name apart.
- Characters left empty by a reset are repaired.
- Each zone is logged with its map ID, so the site can read journals from translated clients (German, French and so on).
- Character ids mix in the name and time, so two characters can't end up with the same one.
- A warning in chat if the game doesn't report the server's time, and reading your fishing skill can't cause an error.
- A setting the client doesn't have is listed in `/reel debug` instead of printed to chat.
- The addon's website is halsudsworth.com.

## 1.0.0-beta.3

- Reset catch data keeps each character's id, so the site still takes that character's journal afterwards.
- Key Bindings shows "Fish (lure, cast, reel in)" and "Apply lure" instead of the raw button names.
- The export leaves the Ruleset out when the game doesn't report it, rather than calling everyone Normal.
- If one item on the bar fails, the rest of the bar keeps updating.
- Bug reports ask for the debug block only: the whole saved file holds your characters' ids.

## 1.0.0-beta.2

- `/reel export`: your journal as one string to copy and paste at halsudsworth.com/paste.
- Every catch is now logged with the server's time, the zone, subzone and map position, your fishing skill and level.

## 1.0.0-beta.1

First public build, made on the World of Warcraft: Forever beta.

- Clean View: the interface fades while you fish, with your choice of what stays visible and how it comes back.
- Immersion page: hide names and nameplates, combat and error text, and the bobber tooltip; auto-loot while fishing; max graphics while fishing; optional fishing camera and letterbox bars.
- The bar: fishing skill with bonus, lure timer, food and camp buffs, zone fish count.
- One-click lure button, double-click casting, splash booster sound settings.
- Fish journal: catches per character, zones, sessions, records, rare fish, and the zone's uncaught fish.
- Cooking recipes on fish tooltips, with vendors.
- Speckled Tastyfish counter during the Stranglethorn Fishing Extravaganza.
