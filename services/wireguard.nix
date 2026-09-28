{ lib, inputs, ... }:

let
  settingsFile = "${inputs.private-config}/wireguard/settings.json";

  settings =
    if builtins.pathExists settingsFile then
      builtins.fromJSON (builtins.readFile settingsFile)
    else
      throw "private-config/wireguard/settings.json is missing: run ./cli.py private init, or add it alongside ssh/settings.json in the private repository.";
in
{
  config = lib.mkIf settings.enable {
    assertions = [
      {
        assertion = settings.peers != [ ];
        message = "Add at least one WireGuard peer to private-config/wireguard/settings.json.";
      }
    ];

    networking.wireguard.interfaces.wg0 = {
      ips = [ settings.address ];

      # The private key never lives in a repository: the Nix store is
      # world-readable, so a key declared here would be a leak. The wireguard
      # module generates this file on first activation (umask 077, mode 0600).
      generatePrivateKeyFile = true;
      privateKeyFile = "/etc/wireguard/wg0.key";

      # A peer that NATs onto its LAN needs that LAN subnet in allowedIPs.
      # Which subnet that is, is site-specific, so it lives in the private file.
      peers = map
        (peer: {
          publicKey = peer.publicKey;
          allowedIPs = peer.allowedIPs;
          endpoint = peer.endpoint;
          persistentKeepalive = peer.persistentKeepalive or null;
        })
        settings.peers;
    };
  };
}
