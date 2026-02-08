
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

hs.hotkey.bind({"ctrl", "shift"}, "space", function()
  local app = hs.application.find("Emacs") or hs.application.find("emacs")
  if app then
    app:activate()
  else
    hs.application.launchOrFocus("Emacs")
  end
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
