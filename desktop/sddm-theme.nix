{ pkgs }:
pkgs.stdenv.mkDerivation {
  name = "pixie-sddm";
  src = pkgs.fetchFromGitHub {
    owner = "marko1616";
    repo = "pixie-sddm";
    rev = "main";
    hash = "sha256-wl0exe5DLszzTv+aBc3qNytF+OFEEI6jiKaL9Vkapso=";
  };
  postPatch = ''
  substituteInPlace components/Clock.qml \
    --replace-fail 'spacing: -130' 'spacing: -60' \
--replace-fail 'spacing: 0' 'spacing: -40'
  '';
  installPhase = ''
      runHook preInstall
      themeDir="$out/share/sddm/themes/pixie"
      mkdir -p "$themeDir"
      cp -r * "$themeDir/"
      install -m644 ${../assets/config/sddm/theme.conf} \
        "$themeDir/theme.conf"
      install -m644 ${../assets/login-background/65475029_p0.jpg} \
        "$themeDir/assets/desktop.jpg"
      runHook postInstall
  '';
}

