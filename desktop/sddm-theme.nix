{ pkgs, inputs, colors }:
let
  theme = inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.pixie-sddm.override {
    background = ../assets/login-background/65475029_p0.jpg;
    autoColor = false;
    accentColor = colors.sddm.accent;
    backgroundColor = colors.sddm.background;
    textColor = colors.sddm.text;
    fontFamily = "Terminess Nerd Font";
    use24HourClock = true;
  };
in theme.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    substituteInPlace components/Clock.qml \
      --replace-fail 'spacing: -130' 'spacing: -60' \
      --replace-fail 'spacing: 0' 'spacing: -40'
  '';
})
