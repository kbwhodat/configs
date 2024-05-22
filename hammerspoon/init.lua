
smallorbig = "small"

local window = hs.window.focusedWindow()

hs.hotkey.bind({"ctrl"}, "space", function()
  local app = hs.application.get("kitty")
  -- local window = app:mainWindow()
  -- if window then
  --     window:setTitlebarAppearance(false)
  -- end

  if app:mainWindow() ~= nil then 
    if app then
      local win = app:mainWindow()
      local appscreen = win:screen() 
      local mainScreen = hs.screen.mainScreen()

      if appscreen == mainScreen then
        if app:isFrontmost() then 
          app:hide()
        else
          app:activate()
          hs.application.launchOrFocus("kitty")

        end
      else

        if app:isHidden() and appscreen ~= mainScreen then 
          hs.application.launchOrFocus("kitty")
          win:moveToScreen(mainScreen)
        elseif appscreen ~= mainScreen and app:isFrontmost() == false then
          app:activate()
          hs.application.launchOrFocus("kitty")
        elseif app:isFrontmost() then
          app:hide()
        end
      end

    else
      hs.application.open(app:name())
    end
  else
    hs.application.open(app:name())
    app:mainWindow():moveToUnit'[100,50,0,100]'
    local mainScreen = hs.screen.mainScreen()
    local win = app:mainWindow()
    local appscreen = win:screen() 
    win:moveToScreen(mainScreen)
    app:mainWindow():moveToUnit'[100,50,0,100]'

  end

end)



hs.hotkey.bind({"ctrl"}, "\\", function()

  local app = hs.application.get("kitty")
  local fwindow = app:mainWindow()


  if fwindow:isVisible() then
    if smallorbig == "small" then
      app:mainWindow():moveToUnit'[100,50,0,100]'
      hs.application.launchOrFocus("kitty")
      smallorbig = "big"
    else
      hs.application.launchOrFocus("kitty")
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

