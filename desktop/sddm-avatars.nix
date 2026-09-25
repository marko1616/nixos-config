{ ... }: {
  # Per-user avatar mappings belong to private/host.nix.
  services.displayManager.sddm.settings.Theme = {
    EnableAvatars = true;
    FacesDir = "/etc/sddm-avatars";
  };
}
