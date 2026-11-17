# Changelog

## 1.4.2

- Fixed: on a German, French or other non-English client, events joined with a code from halsudsworth.com now count your catches in the event's zones.
- On non-English clients: the bar's Zone fish, the Completionist feat and the recipe vendor tips now know which zone you're in, the fishing skill bonus counts gear, and the Food and Camp items find their buffs (each food or camp buff is learned the first time you eat or place it).

## 1.4.1

- Settings: the R.E.E.L. page in Options now has the presets, your R.E.E.L. key bindings with the key each is bound to, an Open Key Bindings button, Export, and links to the other pages.
- Settings are back on six pages, in alphabetical order: Bar, Casting, Clean View, General, Immersion and Sound.
- The Bar page is a single table of what's on your bar, in the bar's order. Each item's options sit on the same line, and the page fits without scrolling.
- While a settings page or the R.E.E.L. window is open, the bar shows everything you've checked, even without a fishing pole equipped.
- The apply-lure button only shows with a fishing pole equipped.
- Dropdown lists are as wide as their longest entry, so long lure names aren't cut off.
- Fixed: with Fishing skill off the bar, a catch didn't show at all. It now shows in the bar's first item.
- Fixed: dragging the bar could drop it partway.

## 1.4.0

A new look for everything R.E.E.L. shows you: oiled oak, brass nails and lantern light.

- The R.E.E.L. window is rebuilt: an oak frame with a brass nameplate, Journal and Events tabs along the top, a painted banner on every tab, and Export at the bottom.
- Journal: Fish, Zones, Sessions and Records.
  - Fish: click a column to sort; click a fish for when and where you first and last caught it.
  - Sessions: fish names run the full width, so they're no longer cut short.
  - Records: tackle trays for Treasures, Pools and wreckage, the Stranglethorn Extravaganza and Rare fish, plus cards for the Derby, Feats and your Records.
- Events: Hal's calendar is built in, so it works without halsudsworth.com. It shows what's running now with your standing, today's and this week's challenge, the next two events, and joining by code.
- Settings moved to Esc > Options > AddOns > R.E.E.L., on four pages: At the water, Clean View, Sound and General. The gear in the window, `/reel options` and the minimap button's right-click menu open them.
- The bar is rebuilt, with three layouts: Vertical, Horizontal and Icons (horizontal).
  - Lure, food and camp each show an icon and their timer; hover for the buff's name.
  - A catch shows the fish in the lure button's place with its name and count, without hiding the rest of the bar. A long name scrolls slowly.
  - New, off by default: a cast countdown.
- New: click the food icon on the bar to eat your best fishing food, or pick which food with the Use menu on the At the water page. There's a key binding for it too.
- "New in Forever" is gone from Records. Ravaged Fishing Pole is now a Treasure, and Whimsyfin is an ordinary fish.
- Fixed: grey items count at their vendor price. A silly auction listing for a junk item could make a session look worth gold.
- Fixed: Hal's calendar events on the Events tab now match your catches' zones, so standings and challenges count.
- Fixed: closing the R.E.E.L. window in combat no longer leaves the bar up until combat ends.

## 1.3.0

- Fish tab: a new Value column shows what each fish you've caught is worth (count times price). With Auctionator installed it uses Auctionator's price, marked with a grey a; otherwise the vendor price, marked with a grey v.
- Sessions tab: three new columns: catches per hour, the average time per catch, and value per hour.
- New bar item, off by default: catches per hour this session (Bar page).
- New key binding: Quick recast (no lure). It cancels your cast and casts again straight away, without putting on a lure. Set it under Key Bindings > AddOns > R.E.E.L.
- "Play sound when tabbed out" on the Sound page now works on its own, without Splash booster.

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
