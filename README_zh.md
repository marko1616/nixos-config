# NixOS 配置

[ [English](README.md) | 中文 ]

我的个人 NixOS 配置和桌面环境。

## 特性

### 桌面环境

* **Niri** — Wayland compositor
* **SDDM** — 登录管理器
* **Waybar** — 状态栏
* **Fuzzel** — 应用程序启动器
* **Kitty** — 终端模拟器
* **Tokyo Night** — 主要配色主题

### 工具

* **Zsh** + **Oh My Zsh** — Shell
* **Neovim** — 文本编辑器
* **btop** — 系统监视器
* **Git** — 版本控制
* **Home Manager** — 用户环境管理

### 其他

* 自定义应用程序配置
* 个人壁纸和桌面资源
* 自定义 Nix 软件包

## 目录结构

```text
.
├── assets/
│   └── config/
├── desktop/
├── marko1616-home/
├── configuration.nix
├── hardware-configuration.nix
├── README.md
└── README_zh.md
```

### `assets/`

应用程序配置文件和个人资源。

### `desktop/`

桌面环境相关的 Nix 配置。

### `marko1616-home/`

Home Manager 配置。

### `configuration.nix`

主要的 NixOS 配置。

## 注意

这是一个个人配置仓库，并不是通用的 NixOS 模板。

其中部分配置针对我的机器和使用环境。

### QQ

QQ 软件包需要手动获取并添加 QQ AppImage，因为 AppImage 本身没有包含在这个仓库中。

相关配置见 `marko1616-home/qq.nix`。

## License

个人配置，请自行决定是否使用。

