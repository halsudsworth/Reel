---
name: Bug report
about: Something in R.E.E.L. isn't working
title: ""
labels: bug
---

**What happened**
What you did, what you expected, what you saw instead.

**Error text, if any**
If a Lua error popped up, paste it here. If you can't copy from the chat window, type `/console scriptErrors 1`, reproduce it, and paste the error from the pop-up.

**Debug block**
In game, type `/reel debug`, then `/reload`. Open this file in a text editor:
`World of Warcraft\_classic_\WTF\Account\<your account>\SavedVariables\Reel.lua`
Copy only the `["debug"] = {` block (down to its closing `},`) and paste it here. Please don't attach the whole file: it holds an id for each of your characters, and anyone with an id can replace that character's journal on halsudsworth.com.

**Setup**
- R.E.E.L. version (addon list, or `## Version` in Reel.toc):
- Other fishing or UI addons running:
- Preset or settings that matter (Clean View on? Immersion toggles? One key bound?):
