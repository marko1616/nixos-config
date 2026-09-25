# NixOS 配置

[ [English](README.md) | 中文 ]

我的个人 NixOS 配置和桌面环境，使用传统非 Flake 配置与 Home Manager。

## 特性

### 桌面环境

* **Niri** — Wayland 窗口合成器
* **SDDM** — 登录管理器，包含自定义主题和头像
* **Waybar** — 状态栏
* **Wofi** — 应用启动器
* **Kitty** — 终端模拟器
* **Mako** — 通知服务
* **Tokyo Night** — 主要配色主题

### 工具

* **Zsh + Oh My Zsh** — Shell，使用 `fino` 主题
* **Neovim** — 编辑器，插件通过 Git 子模块管理
* **LLVM / Clang** — C/C++ 工具链
* **Python** — 开发环境
* **btop** — 系统监视器
* **Git** — 版本控制
* **Home Manager** — 用户环境管理
* **QQ** — AppImage 软件包及源信息更新工具
* **OpenSSH** — 可选的单账户、仅公钥远程访问

## 目录结构

```text
.
├── assets/                     # 共享 dotfiles 与桌面资源
│   ├── avatars/                # 用户头像
│   ├── config/                 # 应用程序 dotfiles
│   ├── login-background/       # SDDM 登录背景
│   ├── plugins/
│   │   └── nvim/               # Neovim 插件子模块
│   └── wallpapers/             # 桌面壁纸
├── config/                     # 本地自定义配置
│   └── ssh/                    # CLI 自动创建，由 Git 忽略
│       ├── authorized_keys     # 导入的客户端公钥
│       └── settings.json       # SSH 账户与启用开关
├── desktop/                    # 桌面环境模块
│   ├── niri.nix                # Niri 配置
│   ├── sddm-avatars.nix         # SDDM 头像
│   └── sddm-theme.nix           # SDDM 主题
├── marko1616-home/              # Home Manager 配置
│   ├── home.nix                # 用户配置入口
│   ├── qq.nix                  # QQ AppImage 软件包
│   ├── qq-source.json          # 固定的 QQ 版本、下载地址与哈希
│   └── ...                     # Shell、编辑器及开发工具配置
├── services/
│   └── ssh.nix                 # SSH 服务模块
├── cli.py                      # SSH 交互配置与 QQ 更新工具
├── configuration.nix           # NixOS 主配置
├── README.md                   # 英文说明
└── README_zh.md                # 中文说明
```

`assets/config/` 存放 dotfiles；`config/` 存放本地自定义配置。

## 配置

这是个人配置。在其他机器上使用前，请检查用户名、主机名、硬件设置和文件路径。

克隆时包含浅克隆子模块：

```bash
git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/marko1616/nixos-config.git
cd nixos-config
```

如果已经克隆但缺少子模块：

```bash
git submodule update --init --recursive --depth 1
```

### 配置工具

```bash
./cli.py
```

脚本通过 `nix-shell` shebang 自动提供 Python 和所需依赖，无需额外的 `shell.nix` 或手动安装 Python 包。如果缺少执行权限，先运行一次 `chmod +x cli.py`。

选择任务并确认，执行完成后返回菜单：

| 任务 | 操作 |
| --- | --- |
| `configure-ssh` | 选择一个已有的普通账户，导入客户端公钥文件 |
| `disable-ssh` | 关闭配置中的 SSH，保留公钥文件 |
| `update-qq` | 下载官网最新 x86_64 QQ AppImage，更新固定版本与 SHA-256 |
| `exit` | 退出工具 |

### SSH

CLI 首次启动时自动创建 `config/ssh/settings.json` 和 `config/ssh/authorized_keys`，不会覆盖已有文件。SSH 默认关闭。

导入客户端的 `.pub` 文件，也支持每行一个公钥的文件。重新配置会替换此前导入的公钥。所选账户必须已在 NixOS 配置中定义。

启用后**仅监听 `0.0.0.0:22`**，只允许指定账户使用公钥认证。禁止 root 登录、密码认证、交互式认证和 IPv6 监听，不读取用户家目录中的 `authorized_keys` 文件。

在仓库根目录的 `.gitignore` 中保留：

```gitignore
/config/ssh/
```

### QQ

`marko1616-home/qq.nix` 从 `marko1616-home/qq-source.json` 读取版本、永久下载地址和 SHA-256。

构建时按需自动获取新的下载签名。`update-qq` 会下载完整 AppImage，计算哈希，并导入 Nix store 供后续构建复用，不保存会过期的签名 URL。目前软件包针对 x86_64。

### 应用配置

**每次使用这份配置前（包括首次配置），请先运行 `./cli.py` 并选择 `update-qq`，更新 QQ 版本与哈希后再重建系统。**

CLI 只修改配置文件，不自动重建系统。

保留本机的 `/etc/nixos/hardware-configuration.nix`。运行 CLI 后，在仓库根目录复制配置，**必须包含完整的 `assets/` 和被 Git 忽略的 `config/ssh/` 目录**：

```bash
sudo cp -a configuration.nix cli.py desktop services marko1616-home assets config /etc/nixos/
sudo nixos-rebuild switch
```

如果直接在 `/etc/nixos` 中管理仓库，无需再次复制。修改 SSH 设置或更新 QQ 后，重新复制并重建。通过 SSH 远程应用 SSH 变更时，保留当前会话，直到新连接验证成功。

