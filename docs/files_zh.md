# 文件与部署

[English](files.md) | 中文

本文是仓库入口与文件的索引，不要求手动复制配置文件。首次使用和 `./cli.py` 菜单见 [README](../README_zh.md)；当前生效的按键见[快捷键说明](shortcuts_zh.md)。

## 配置链路

| 来源 | 作用 |
| --- | --- |
| `flake.nix` | 声明固定的输入与 `nixosConfigurations.default` 入口，引入 `configuration.nix` 和私有输入中的 `host.nix`。 |
| `flake.lock` | 固定输入版本；生产构建前应生成并审查。 |
| `configuration.nix` | 共用 NixOS 配置，导入 `desktop/` 与 `services/`。 |
| `desktop/` | Niri、SDDM、Rime 及桌面数据模块。 |
| `marko1616-home/home.nix` | 共用 Home Manager 入口，导入桌面、shell、编辑器等用户模块。 |
| `services/` | SSH、WireGuard 等可选系统服务，由私有配置决定。 |
| `templates/private-config/` | 公开的初始化模板；`./cli.py private init` 将其复制到独立的 `private-config/` 仓库。 |
| `scripts/private_config.py` | `./cli.py` 背后的私有仓库管理实现。 |
| `config/qq-source.json` | QQ 打包流程使用的版本与哈希元数据。 |

`private-config/` 保存真实主机配置，不纳入公开仓库。硬件配置、标识信息和场地相关服务设置放在这里；私钥与密码不能进入任何 Flake 源。公开的 `assets/` 存放 dotfiles、图片和固定版本的 submodule，不是用户运行时数据目录。

## 资源与安装位置

以下对应关系来自 `marko1616-home/desktop-environment.nix`、`marko1616-home/nvim.nix` 等 Home Manager 模块：

| 仓库来源 | 用户侧位置或用途 |
| --- | --- |
| `assets/config/niri/config.kdl` | `~/.config/niri/config.kdl`；Niri 布局、规则和快捷键 |
| `assets/config/quickshell/marko-shell/` | `~/.config/quickshell/marko-shell/`；shader 在 Home Manager 构建时编译 |
| `assets/config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `assets/config/wofi/{config,style.css}` | `~/.config/wofi/` |
| `assets/config/mako/config` | `~/.config/mako/config` |
| `assets/config/fcitx5/marko-shell/` | `~/.local/share/fcitx5/themes/marko-shell/`，另有系统 Fcitx 主题包 |
| `assets/config/nvim/` | `~/.config/nvim/` |
| `assets/plugins/nvim/` | `~/.local/share/nvim/plugins/`；固定版本的插件 submodule |
| `assets/config/zsh/greeting.*` | `~/.config/zsh/` |
| `assets/config/btop/btop.conf` | `~/.config/btop/btop.conf` |
| `assets/wallpapers/148557481_p1.jpg` | `~/.local/share/wallpapers/desktop.png` |

`desktop/rime-data.nix` 从 `assets/rime/`、`assets/rime-ice` submodule 和固定版本的上游文件构建 Rime 数据包。`programs.markoInput.enable` 为 true 时，`desktop/rime.nix` 将其加入 Fcitx5；不是把 `assets/rime/` 直接复制进用户家目录。激活与重新部署见 [Rime U/V 模式](rime-uv_zh.md)。

## 修改与应用

修改仓库中的源文件，不要直接修改 `~/.config` 下由 Home Manager 管理的链接。Git-backed Flake 引用新增公开文件时，构建前必须将其加入 Git index；未跟踪文件可能被 Flake 忽略。打开 `./cli.py` 菜单，使用 `build-dev` / `switch-dev` 对应本地私有配置，`build-prod` / `switch-prod` 对应锁定的远端私有输入。这些是菜单项，**不是** `./cli.py` 子命令。系统切换不保证所有运行中的桌面程序立即重启；Rime 等组件还需按[专页](rime-uv_zh.md)操作。
