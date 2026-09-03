{ ... }:
{
  # Caps Lock (0x39) -> F18 (0x6D) at the HID level. Hammerspoon turns a
  # held F18 into the navigation layer (see ~/.config/hammerspoon/init.lua).
  launchd.agents.hidutil-capslock = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/hidutil" "property" "--set"
        ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}''
      ];
      RunAtLoad = true;
    };
  };
}
