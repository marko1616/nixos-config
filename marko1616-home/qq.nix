{ pkgs, ... }:

let
  source = builtins.fromJSON (builtins.readFile ../config/qq-source.json);

  appimage = pkgs.stdenvNoCC.mkDerivation {
    name = builtins.baseNameOf source.url;

    nativeBuildInputs = [ pkgs.python3 ];

    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    impureEnvVars = pkgs.lib.fetchers.proxyImpureEnvVars;

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = source.hash;

    buildCommand = ''
      python3 ${../cli.py} \
        --fetch-qq ${pkgs.lib.escapeShellArg source.url} "$out"
    '';
  };

  qq = pkgs.stdenvNoCC.mkDerivation {
    pname = "qq";
    version = source.version;

    src = appimage;

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
