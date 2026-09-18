{ pkgs, ... }:

let
  qq = pkgs.stdenv.mkDerivation {
    pname = "qq";
    version = "3.2.33";

    src = pkgs.requireFile {
      name = "QQ_3.2.33_260902_x86_64_01.AppImage";

      message = ''
        Please download QQ AppImage manually.
        Then add it to the Nix store:
          nix-store --add-fixed sha256 ./QQ_3.2.33_260902_x86_64_01.AppImage
      '';

      hash = "sha256-Ure8seexRvVmYnmsDaTlSdmVE13tZ70bkSmt1F/pCxQ=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    dontUnpack = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/lib/qq"
      cp "$src" "$out/lib/qq/QQ.AppImage"
      chmod +x "$out/lib/qq/QQ.AppImage"

      makeWrapper "${pkgs.appimage-run}/bin/appimage-run" "$out/bin/qq" \
        --add-flags "$out/lib/qq/QQ.AppImage"

      runHook postInstall
    '';
  };
in
{
  home.packages = [ qq ];

  home.file.".local/share/applications/qq.desktop".text = ''
    [Desktop Entry]
    Name=QQ
    Comment=Tencent QQ
    Exec=qq
    Terminal=false
    Type=Application
    Categories=Network;InstantMessaging;
  '';
}
