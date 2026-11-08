# Changelog

## Unreleased

- Right-click the minimap button for quick settings: show or lock the R.E.E.L. bar, Clean View, the splash booster, and Export journal.
- Your journal now keeps the full text of Riggle Bassbait's winner yell, not only the winner's name.
- Fixed: an error about a secret string when Riggle Bassbait yelled.

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
