# NextDNS lockdown (NixOS). Linux counterpart of ./default.nix.
# The resolver itself is systemd-resolved with DNS-over-TLS to NextDNS
# (see modules/system/nixos-config). This only adds the firewall layer:
# plain DNS (port 53) may leave the machine only towards NextDNS.
{ config, lib, ... }:

let
  cfg = config.modules.nextdnsLockdown;

  # ipt = "iptables" or "ip6tables"; allowed = NextDNS ranges for that family
  lock = ipt: allowed: ''
    ${ipt} -w -N nextdns-lock 2>/dev/null || ${ipt} -w -F nextdns-lock
    ${lib.concatMapStringsSep "\n" (net: "${ipt} -w -A nextdns-lock -d ${net} -j ACCEPT") allowed}
    ${ipt} -w -A nextdns-lock -j REJECT
    ${unlock ipt}
    ${ipt} -w -I OUTPUT ! -o lo -p udp --dport 53 -j nextdns-lock
    ${ipt} -w -I OUTPUT ! -o lo -p tcp --dport 53 -j nextdns-lock
  '';
  unlock = ipt: ''
    ${ipt} -w -D OUTPUT ! -o lo -p udp --dport 53 -j nextdns-lock 2>/dev/null || true
    ${ipt} -w -D OUTPUT ! -o lo -p tcp --dport 53 -j nextdns-lock 2>/dev/null || true
  '';
  drop = ipt: ''
    ${unlock ipt}
    ${ipt} -w -F nextdns-lock 2>/dev/null || true
    ${ipt} -w -X nextdns-lock 2>/dev/null || true
  '';
in
{
  options.modules.nextdnsLockdown.enable = lib.mkEnableOption "NextDNS lockdown";

  config = lib.mkIf cfg.enable {
    networking.firewall.extraCommands =
      lock "iptables" [ "45.90.28.0/24" "45.90.30.0/24" ]
      + lock "ip6tables" [ "2a07:a8c0::/32" "2a07:a8c1::/32" ];

    networking.firewall.extraStopCommands =
      drop "iptables" + drop "ip6tables";
  };
}
