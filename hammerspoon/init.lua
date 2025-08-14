
smallorbig = "small"

local window = hs.window.focusedWindow()

hs.hotkey.bind({"ctrl", "shift"}, "space", function()
  local app = hs.application.get("emacs")

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

hs.hotkey.bind({"ctrl"}, "space", function()
  local app = hs.application.get("net.kovidgoyal.kitty")

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



hs.hotkey.bind({"ctrl"}, "\\", function()
  local app = hs.application.get("net.kovidgoyal.kitty")
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

