{ ... }:
{
  # Authentication stays in the system PAM stack; no credentials in QML/Nix.
  security.pam.services.marko-lock = { };
}
