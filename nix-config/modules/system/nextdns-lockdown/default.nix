# NextDNS lockdown (nix-darwin).
#   1. Pin Wi-Fi DNS to NextDNS; a LaunchDaemon re-applies it every 30 s.
#   2. PF: allow port 53 only to NextDNS, drop everything else.
#   3. Ship /etc/web-filter.mobileconfig (Apple web content filter).
#      Install once by hand: open /etc/web-filter.mobileconfig
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.nextdnsLockdown;
  dns = [ "45.90.30.210" "45.90.28.210" ];

  # Stock macOS pf.conf plus our DNS rules. Loaded from the nix store so
  # /etc/pf.conf itself is left alone.
  pfConf = pkgs.writeText "pf.conf" ''
    scrub-anchor "com.apple/*"
    nat-anchor "com.apple/*"
    rdr-anchor "com.apple/*"
    dummynet-anchor "com.apple/*"

    ${lib.concatMapStringsSep "\n" (ip: "pass out quick proto { tcp udp } to ${ip} port 53") dns}
    block drop out quick proto { tcp udp } to any port 53

    anchor "com.apple/*"
    load anchor "com.apple" from "/etc/pf.anchors/com.apple"
  '';

  # pfctl is chatty on stderr even on success; only show it on failure.
  pfApply = pkgs.writeShellScript "nextdns-pf-apply" ''
    out=$(/sbin/pfctl -f ${pfConf} 2>&1) || { echo "$out" >&2; exit 1; }
    /sbin/pfctl -e >/dev/null 2>&1 || true   # already enabled is fine
  '';

  mobileconfig = pkgs.writeText "web-filter.mobileconfig" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>PayloadContent</key>
      <array>
        <dict>
          <key>restrictWeb</key><true/>
          <key>useContentFilter</key><true/>
          <key>PayloadIdentifier</key><string>local.web-filter.payload</string>
          <key>PayloadType</key><string>com.apple.familycontrols.contentfilter</string>
          <key>PayloadUUID</key><string>4D756F0D-ECD5-438D-B41F-BA25D72D6117</string>
          <key>PayloadVersion</key><integer>1</integer>
        </dict>
      </array>
      <key>PayloadDisplayName</key><string>Web Content Filter</string>
      <key>PayloadIdentifier</key><string>local.web-filter</string>
      <key>PayloadType</key><string>Configuration</string>
      <key>PayloadUUID</key><string>DE845510-CFB1-48D4-ADF6-5B7E8B7EC276</string>
      <key>PayloadVersion</key><integer>1</integer>
    </dict>
    </plist>
  '';
in
{
  options.modules.nextdnsLockdown.enable = lib.mkEnableOption "NextDNS lockdown";

  config = lib.mkIf cfg.enable {
    # 1. pinned DNS
    networking.knownNetworkServices = [ "Wi-Fi" ];
    networking.dns = dns;

    launchd.daemons.enforce-nextdns.serviceConfig = {
      ProgramArguments = [ "/usr/sbin/networksetup" "-setdnsservers" "Wi-Fi" ] ++ dns;
      RunAtLoad = true;
      StartInterval = 30;
    };

    # 2. PF — on every rebuild, and at boot (PF rules don't survive reboot)
    system.activationScripts.postActivation.text = "${pfApply}";

    launchd.daemons.nextdns-pf.serviceConfig = {
      ProgramArguments = [ "${pfApply}" ];
      RunAtLoad = true;
    };

    # 3. content filter profile
    environment.etc."web-filter.mobileconfig".source = mobileconfig;
  };
}
