{ pkgs }:
let
  lib = pkgs.lib;
  colors = import ./colors.nix;
  colorValues = lib.collect builtins.isString colors;
  validColor = value:
    value == "NONE"
    || value == "transparent"
    || builtins.match "^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$" value != null;

  render = src: variables:
    pkgs.replaceVars src variables;

  quickshellColors = pkgs.writeText "Colors.qml" ''
    pragma Singleton
    import QtQuick

    // Generated from theme/colors.nix. Do not edit in the deployed tree.
    QtObject {
        readonly property color barWindowBackground: "${colors.quickshell.barWindowBackground}"
        readonly property color barBackground: "${colors.quickshell.barBackground}"
        readonly property color barOutline: "${colors.quickshell.barOutline}"
        readonly property color workspaceContainerBackground: "${colors.quickshell.workspaceContainerBackground}"
        readonly property color workspaceFocused: "${colors.quickshell.workspaceFocused}"
        readonly property color workspaceActive: "${colors.quickshell.workspaceActive}"
        readonly property color workspaceInactive: "${colors.quickshell.workspaceInactive}"
        readonly property color workspaceUrgent: "${colors.quickshell.workspaceUrgent}"
        readonly property color workspaceSeparator: "${colors.quickshell.workspaceSeparator}"
        readonly property color statusContainerBackground: "${colors.quickshell.statusContainerBackground}"
        readonly property color cpuAccent: "${colors.quickshell.cpuAccent}"
        readonly property color memoryAccent: "${colors.quickshell.memoryAccent}"
        readonly property color clockAccent: "${colors.quickshell.clockAccent}"
        readonly property color wifiAccent: "${colors.quickshell.wifiAccent}"
        readonly property color bluetoothAccent: "${colors.quickshell.bluetoothAccent}"
        readonly property color audioAccent: "${colors.quickshell.audioAccent}"
        readonly property color batteryCritical: "${colors.quickshell.batteryCritical}"
        readonly property color batteryLow: "${colors.quickshell.batteryLow}"
        readonly property color batteryNormal: "${colors.quickshell.batteryNormal}"
        readonly property color powerAccent: "${colors.quickshell.powerAccent}"
        readonly property color pillDefaultAccent: "${colors.quickshell.pillDefaultAccent}"
        readonly property color pillBackground: "${colors.quickshell.pillBackground}"
        readonly property color audioTitle: "${colors.quickshell.audioTitle}"
        readonly property color audioValue: "${colors.quickshell.audioValue}"
        readonly property color audioError: "${colors.quickshell.audioError}"
        readonly property color audioUnmuteAction: "${colors.quickshell.audioUnmuteAction}"
        readonly property color audioMuteAction: "${colors.quickshell.audioMuteAction}"
        readonly property color bluetoothTitle: "${colors.quickshell.bluetoothTitle}"
        readonly property color bluetoothAdapterStatus: "${colors.quickshell.bluetoothAdapterStatus}"
        readonly property color bluetoothScanningLabel: "${colors.quickshell.bluetoothScanningLabel}"
        readonly property color bluetoothConnectedRowBackground: "${colors.quickshell.bluetoothConnectedRowBackground}"
        readonly property color bluetoothDisconnectedRowBackground: "${colors.quickshell.bluetoothDisconnectedRowBackground}"
        readonly property color bluetoothDeviceName: "${colors.quickshell.bluetoothDeviceName}"
        readonly property color bluetoothDeviceDetails: "${colors.quickshell.bluetoothDeviceDetails}"
        readonly property color bluetoothPairingAction: "${colors.quickshell.bluetoothPairingAction}"
        readonly property color bluetoothDisconnectAction: "${colors.quickshell.bluetoothDisconnectAction}"
        readonly property color bluetoothConnectAction: "${colors.quickshell.bluetoothConnectAction}"
        readonly property color tooltipWindowBackground: "${colors.quickshell.tooltipWindowBackground}"
        readonly property color tooltipBackground: "${colors.quickshell.tooltipBackground}"
        readonly property color tooltipOutline: "${colors.quickshell.tooltipOutline}"
        readonly property color tooltipText: "${colors.quickshell.tooltipText}"
        readonly property color sliderTrack: "${colors.quickshell.sliderTrack}"
        readonly property color sliderFill: "${colors.quickshell.sliderFill}"
        readonly property color sliderThumb: "${colors.quickshell.sliderThumb}"
        readonly property color sliderFocusBorder: "${colors.quickshell.sliderFocusBorder}"
        readonly property color switchCheckedBackground: "${colors.quickshell.switchCheckedBackground}"
        readonly property color switchUncheckedBackground: "${colors.quickshell.switchUncheckedBackground}"
        readonly property color switchFocusBorder: "${colors.quickshell.switchFocusBorder}"
        readonly property color switchCheckedBorder: "${colors.quickshell.switchCheckedBorder}"
        readonly property color switchUncheckedBorder: "${colors.quickshell.switchUncheckedBorder}"
        readonly property color switchThumb: "${colors.quickshell.switchThumb}"
        readonly property color networkTitle: "${colors.quickshell.networkTitle}"
        readonly property color networkError: "${colors.quickshell.networkError}"
        readonly property color networkWarning: "${colors.quickshell.networkWarning}"
        readonly property color networkConnectedRowBackground: "${colors.quickshell.networkConnectedRowBackground}"
        readonly property color networkDisconnectedRowBackground: "${colors.quickshell.networkDisconnectedRowBackground}"
        readonly property color networkIcon: "${colors.quickshell.networkIcon}"
        readonly property color networkName: "${colors.quickshell.networkName}"
        readonly property color networkDetails: "${colors.quickshell.networkDetails}"
        readonly property color networkAccessPointDetails: "${colors.quickshell.networkAccessPointDetails}"
        readonly property color passwordText: "${colors.quickshell.passwordText}"
        readonly property color passwordPlaceholder: "${colors.quickshell.passwordPlaceholder}"
        readonly property color passwordSelectionBackground: "${colors.quickshell.passwordSelectionBackground}"
        readonly property color passwordSelectedText: "${colors.quickshell.passwordSelectedText}"
        readonly property color passwordFocusedBackground: "${colors.quickshell.passwordFocusedBackground}"
        readonly property color passwordUnfocusedBackground: "${colors.quickshell.passwordUnfocusedBackground}"
        readonly property color popoverWindowBackground: "${colors.quickshell.popoverWindowBackground}"
        readonly property color popoverBackground: "${colors.quickshell.popoverBackground}"
        readonly property color popoverOutline: "${colors.quickshell.popoverOutline}"
        readonly property color powerTitle: "${colors.quickshell.powerTitle}"
        readonly property color powerSelectedBackground: "${colors.quickshell.powerSelectedBackground}"
        readonly property color powerHoverBackground: "${colors.quickshell.powerHoverBackground}"
        readonly property color powerIdleBackground: "${colors.quickshell.powerIdleBackground}"
        readonly property color powerIcon: "${colors.quickshell.powerIcon}"
        readonly property color powerLabel: "${colors.quickshell.powerLabel}"
        readonly property color textButtonDefaultText: "${colors.quickshell.textButtonDefaultText}"
        readonly property color textButtonPressedBackground: "${colors.quickshell.textButtonPressedBackground}"
        readonly property color textButtonHoverBackground: "${colors.quickshell.textButtonHoverBackground}"
        readonly property color textButtonIdleBackground: "${colors.quickshell.textButtonIdleBackground}"
        readonly property color textButtonFocusBorder: "${colors.quickshell.textButtonFocusBorder}"
    }
  '';

  quickshell = pkgs.runCommandLocal "marko-shell" {
    nativeBuildInputs = [ pkgs.qt6.qtshadertools ];
  } ''
    mkdir -p "$out"
    cp -r ${../assets/config/quickshell/marko-shell}/. "$out/"
    cp ${quickshellColors} "$out/Colors.qml"
    qsb --glsl "300es,330" \
      -o "$out/SdfPopup.frag.qsb" "$out/SdfPopup.frag"
  '';

  fcitx5Theme = pkgs.runCommand "fcitx5-marko-shell-theme" { } ''
    theme_dir="$out/share/fcitx5/themes/marko-shell"
    mkdir -p "$theme_dir"
    cp ${render ../assets/config/fcitx5/marko-shell/theme.conf.in (lib.getAttrs [
      "normalText"
      "highlightText"
      "highlightBackground"
      "highlightCandidateText"
      "candidateLabel"
      "highlightCandidateLabel"
      "candidateComment"
      "highlightCandidateComment"
    ] colors.fcitx5)} "$theme_dir/theme.conf"
    cp ${render ../assets/config/fcitx5/marko-shell/panel.svg.in (lib.getAttrs [
      "panelBackground"
      "panelBorder"
    ] colors.fcitx5)} "$theme_dir/panel.svg"
    cp ${render ../assets/config/fcitx5/marko-shell/highlight.svg.in (lib.getAttrs [
      "highlightImageBackground"
    ] colors.fcitx5)} "$theme_dir/highlight.svg"
  '';

  neovimPalette = {
    bg_statusline = colors.neovim.statuslineBackground;
  };
  neovimHighlights = {
    LineNrAbove = {
      fg = colors.neovim.highlights.lineNumberAboveForeground;
      bg = colors.neovim.highlights.lineNumberAboveBackground;
    };
    LineNrBelow = {
      fg = colors.neovim.highlights.lineNumberBelowForeground;
      bg = colors.neovim.highlights.lineNumberBelowBackground;
    };
    CursorLineNr = {
      fg = colors.neovim.highlights.cursorLineNumberForeground;
      bg = colors.neovim.highlights.cursorLineNumberBackground;
      bold = true;
    };
    LineNr = {
      fg = colors.neovim.highlights.lineNumberForeground;
      bg = colors.neovim.highlights.lineNumberBackground;
    };
  };
  toLua = value:
    if builtins.isAttrs value then
      "{\n" + lib.concatStringsSep ",\n" (
        lib.mapAttrsToList (name: child:
          "  [${builtins.toJSON name}] = ${toLua child}"
        ) value
      ) + "\n}"
    else if builtins.isList value then
      "{ " + lib.concatMapStringsSep ", " toLua value + " }"
    else
      builtins.toJSON value;
  neovimColors = pkgs.writeText "colors.lua" ''
    -- Generated from theme/colors.nix. Do not edit in the deployed tree.
    return {
      palette = ${toLua neovimPalette},
      highlights = ${toLua neovimHighlights},
    }
  '';
  neovim = pkgs.runCommandLocal "marko-neovim-config" { } ''
    mkdir -p "$out/lua/theme"
    cp -r ${../assets/config/nvim}/. "$out/"
    cp ${neovimColors} "$out/lua/theme/colors.lua"
  '';
in
assert lib.assertMsg (lib.all validColor colorValues)
  "theme/colors.nix contains a value that is neither #RRGGBB, an eight-digit color, transparent, nor NONE";
{
  inherit colors quickshell neovim fcitx5Theme;
  files = {
    niri = render ../assets/config/niri/config.kdl.in (colors.niri // {
      # cli.py fills these runtime placeholders after the Nix build.
      DEFAULT_AUDIO_SINK = null;
      DEFAULT_AUDIO_SOURCE = null;
    });
    kitty = render ../assets/config/kitty/kitty.conf.in colors.kitty;
    wofiStyle = render ../assets/config/wofi/style.css.in colors.wofi;
    mako = render ../assets/config/mako/config.in colors.mako;
    btopTheme = render ../assets/config/btop/themes/marko.theme.in colors.btop;
  };
}
