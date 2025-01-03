self: super:
let
  by-name = import ./by-name self super;
in
  super.lib.mergeAttrsList [
    by-name
    { alsa-lib = super.alsa-lib; }
  ]
