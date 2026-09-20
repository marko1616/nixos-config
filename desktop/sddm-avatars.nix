{ lib, ... }:

let
  avatars = {
    marko1616 = ../assets/avatars/marko1616.png;
  };
in
{
  services.displayManager.sddm.settings.Theme = {
    EnableAvatars = true;
    FacesDir = "/etc/sddm-avatars";
  };

  environment.etc = lib.mapAttrs'
    (username: image:
      lib.nameValuePair "sddm-avatars/${username}.face.icon" {
        source = image;
      })
    avatars;
}
