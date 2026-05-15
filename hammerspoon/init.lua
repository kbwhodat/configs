
smallorbig = "small"

local window = hs.window.focusedWindow()

hs.hotkey.bind({"ctrl", "option"}, "space", function()
  local app = hs.application.get("zed")

  if app:mainWindow() ~= nil then
    if app then
      local win = app:mainWindow()
      local appscreen = win:screen()
      local mousescreen = hs.mouse.getCurrentScreen()

      if appscreen == mousescreen then
        if app:isFrontmost() then
          app:hide()
        else
          app:activate()
        end
      else

        if app:isHidden() and appscreen ~= mousescreen then
          win:moveToScreen(mousescreen)
        elseif appscreen ~= mousescreen and app:isFrontmost() == false then
          app:activate()
        elseif app:isFrontmost() then
          app:hide()
        end
      end
    end
  else
    app:mainWindow():moveToUnit'[100,50,0,100]'
    local mousescreen = hs.mouse.getCurrentScreen()
    local win = app:mainWindow()
    local appscreen = win:screen() 
    win:moveToScreen(mousescreen)
    app:mainWindow():moveToUnit'[100,50,0,100]'

  end

end)

-- Find the emacs daemon process at the macOS level.  System Events sees
-- it under the literal binary name `emacs-stable' (from `~/.local/bin/
-- emacs-stable' — see `home.activation.stabilizeEmacsAndBounce' in
-- emacs.nix).  hs.application.find may return a table on multi-match
-- so we unwrap that case.
local function findEmacs()
  local r = hs.application.find("emacs-stable")
  if type(r) == "table" then r = r[1] end
  return r
end

-- Force-activate emacs at the macOS level via System Events by PID.
--
-- Why not `app:activate()` (the obvious choice):
--   `:activate()' calls NSRunningApplication.activateWithOptions, which
--   silently fails for our daemon.  Reason: the daemon binary at
--   `~/.local/bin/emacs-stable' is a bare Mach-O — no .app bundle, no
--   Info.plist, so NSRunningApplication can't fully activate it.
--   Verified: `osascript … set frontmost of process "emacs-stable"' is
--   a no-op too, but the same call using `(first process whose unix id
--   is PID)' DOES bring it forward.  PID-route bypasses the broken
--   bundle lookup.
local function activateEmacsByPID(pid)
  if not pid then return end
  hs.osascript.applescript(string.format(
    'tell application "System Events"\n' ..
    '  set p to first process whose unix id is %d\n' ..
    '  set visible of p to true\n' ..
    '  set frontmost of p to true\n' ..
    'end tell',
    pid))
end

-- Poll until the daemon has at least one window, then activate.
-- emacsclient -n returns the moment the eval is enqueued, not when
-- the NSWindow is rendered — there's a ~100-300 ms cold-start gap.
local function emacsWindow(app, screen)
  if not app then return nil end
  local windows = app:allWindows()
  if screen then
    for _, win in ipairs(windows) do
      if win:screen() == screen then
        return win
      end
    end
  end
  return app:mainWindow() or app:focusedWindow() or windows[1]
end

local function focusEmacsWindow(app, win)
  if not app or not win then return end

  app:unhide()

  -- emacs-stable is a bare daemon binary, not a normal .app bundle, so
  -- NSRunningApplication activation is unreliable. Drive focus through
  -- Accessibility by PID/window instead.
  local axApp = hs.axuielement.applicationElement(app)
  if axApp then
    pcall(function() axApp:setAttributeValue("AXFrontmost", true) end)
  end

  activateEmacsByPID(app:pid())

  local axWin = hs.axuielement.windowElement(win)
  if axWin then
    pcall(function() axWin:performAction("AXRaise") end)
    pcall(function() axWin:setAttributeValue("AXMain", true) end)
    pcall(function() axWin:setAttributeValue("AXFocused", true) end)
    pcall(function()
      hs.axuielement.systemWideElement():setAttributeValue("AXFocusedWindow", axWin)
    end)
  end

  win:raise()
  win:focus()
  activateEmacsByPID(app:pid())
end

local function activateEmacsWhenReady(attempts)
  attempts = attempts or 0
  local app = findEmacs()
  local screen = hs.mouse.getCurrentScreen()
  local win = emacsWindow(app, screen)
  if app and win then
    if screen and win:screen() ~= screen then
      win:moveToScreen(screen)
    end

    focusEmacsWindow(app, win)

    if app:isFrontmost() then
      return
    end
  end
  if attempts < 40 then  -- 40 × 50 ms = 2 s ceiling
    hs.timer.doAfter(0.05, function() activateEmacsWhenReady(attempts + 1) end)
  end
end

hs.hotkey.bind({"ctrl", "shift"}, "space", function()
  -- Ensure a GUI frame exists.  `my/raise-or-make-frame' focuses an
  -- existing GUI frame, else makes one.  Idempotent — pressing twice
  -- never piles up duplicate frames.
  hs.execute(
    "/etc/profiles/per-user/katob/bin/emacsclient -n -a '' --eval '(my/raise-or-make-frame)'",
    true)

  -- Activate at macOS level once the frame actually exists.  Polls
  -- because emacsclient -n returns before the frame is rendered.
  activateEmacsWhenReady()
end)

hs.hotkey.bind({"ctrl"}, "space", function()
  local app = hs.application.find("WezTerm") or hs.application.find("wezterm")
  if app then
    app:activate()
  else
    hs.application.launchOrFocus("WezTerm")
  end
end)



hs.hotkey.bind({"ctrl"}, "\\", function()
  local app = hs.application.get("wezterm")
	local fwindow = app:mainWindow()
	if fwindow:isVisible() then
		if smallorbig == "small" then
			app:mainWindow():moveToUnit'[100,50,0,100]'
			smallorbig = "big"
		else
			local apps = app:mainWindow()
			fwindow:maximize()
			smallorbig = "small"
		end
	end
end)

local function sendSystemKey(key)
    hs.eventtap.event.newSystemKeyEvent(key, true):post()
    hs.eventtap.event.newSystemKeyEvent(key, false):post()
end

local volume = {
    up   = function() sendSystemKey("SOUND_UP") end,
    down = function() sendSystemKey("SOUND_DOWN") end,
    mute = function() sendSystemKey("MUTE") end,
}
hs.hotkey.bind({}, "f10", volume.mute)
hs.hotkey.bind({}, "f11", volume.down, nil, volume.down)
hs.hotkey.bind({}, "f12", volume.up, nil, volume.up)

local function focusBrowser(target)
  if target.bundleID and hs.application.launchOrFocusByBundleID(target.bundleID) then
    return
  end

  for _, name in ipairs(target.names or {}) do
    local app = hs.application.find(name)
    if app then
      app:activate()
      return
    end
  end

  for _, name in ipairs(target.names or {}) do
    if hs.application.launchOrFocus(name) then
      return
    end
  end
end

hs.hotkey.bind({"cmd", "shift"}, "f", function()
  focusBrowser({ bundleID = "app.zen-browser.zen", names = {"Zen Browser", "Zen"} })
end)

hs.hotkey.bind({"cmd", "shift"}, "g", function()
  focusBrowser({ bundleID = "org.chromium.Thorium", names = {"Thorium", "Thorium Browser"} })
end)

hs.hotkey.bind({"cmd", "shift"}, "y", function()
  focusBrowser({ bundleID = "io.freetubeapp.freetube", names = {"FreeTube", "freetube"} })
end)

hs.hotkey.bind({"ctrl", "cmd"}, "space", function()
  if hs.application.launchOrFocusByBundleID("com.sublimetext.4") then
    return
  end

  local app = hs.application.find("Sublime Text") or hs.application.find("sublime_text")
  if app then
    app:activate()
  else
    hs.application.launchOrFocus("Sublime Text")
  end
end)
