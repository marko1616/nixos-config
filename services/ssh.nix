{ config, lib, inputs, ... }:

let
  settings =
    builtins.fromJSON
      (builtins.readFile "${inputs.private-config}/ssh/settings.json");

  keyFile = "${inputs.private-config}/ssh/authorized_keys";

  keys = lib.filter
    (line: line != "" && !(lib.hasPrefix "#" line))
    (lib.splitString "\n" (builtins.readFile keyFile));
in
{
  config = lib.mkIf settings.enable {
    assertions = [
      {
        assertion = keys != [ ];
        message = "Import an SSH public key using ./cli.py first.";
      }
      {
        assertion =
          settings.user != "root"
          && (config.users.users.${settings.user}.isNormalUser or false);

        message = "The SSH account must be an existing normal NixOS user.";
      }
    ];

    services.openssh = {
      enable = true;
      ports = [ 22 ];
      openFirewall = true;

      authorizedKeysInHomedir = false;

      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 22;
        }
      ];

      settings = {
        AddressFamily = "inet";
        AllowUsers = [ settings.user ];
        PermitRootLogin = "no";

        PubkeyAuthentication = true;
        AuthenticationMethods = "publickey";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    users.users.${settings.user}.openssh.authorizedKeys.keyFiles = [
      keyFile
    ];
  };
}
