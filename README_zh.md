# NixOS 配置

[English](README.md) | 中文

Niri 桌面与 Home Manager 配置，使用 Flake 固定依赖。真实主机配置保存在独立的私有仓库，本地目录为 `private/`。

## 桌面环境

Niri、SDDM / Pixie、QuickShell（marko-shell 顶栏）、Wofi、Kitty、Mako，采用 Tokyo Night 配色。

顶栏为 `assets/config/quickshell/marko-shell/` 中的 QuickShell 配置，安装到 `~/.config/quickshell/marko-shell`。

## 工具

Zsh / Oh My Zsh、Neovim、LLVM / Clang、Python、btop、QQ、可选的公钥 SSH。

## 目录

```text
flake.nix                  # 系统入口和 CLI 环境
flake.lock                 # 首次迁移生成并提交
configuration.nix          # 通用系统设置
cli.py                     # 交互工具与 QQ 下载入口
private_config.py          # 私有配置仓库管理
private-config/            # 独立私有仓库，主仓库忽略
  host.nix                 # 主机、账户、内核、stateVersion
  hardware-configuration.nix # 本机挂载、UUID 和硬件信息
  ssh/                     # SSH 设置及客户端公钥
templates/private-config/  # 无真实主机数据的默认模板
config/qq-source.json      # QQ 固定版本与哈希
desktop/                   # 系统桌面模块
services/                  # 系统服务模块
marko1616-home/            # 通用 Home Manager 模块
assets/                    # dotfiles、壁纸、头像与插件子模块
```

## 首次使用

```bash
git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/marko1616/nixos-config.git
cd nixos-config
flake_ref="git+file://$PWD?submodules=1"
nix flake lock "$flake_ref"
./cli.py private init
./cli.py private import-hardware
./cli.py private edit-host
```

先核对 `private/host.nix` 的用户名、主机名、启动方式及两个 `stateVersion`，然后运行交互工具配置 SSH、更新 QQ：

```bash
./cli.py
```

每次准备应用更新前先考虑运行 `update-qq`，避免上游旧版本下架；复现旧版本或回滚时不要更新。

## 私有仓库

```bash
# 从已存在的仓库初始化或切换；已有 private/ 必须没有未提交修改。
./cli.py private switch \
  git@github.com:YOUR_ACCOUNT/private-config.git

./cli.py private status
```

CLI 不会提交、推送或激活系统。输入来源写入 `flake.nix`，提交写入 `flake.lock`。公钥和硬件内容不会进入公共主仓库；私有仓库地址及 revision 会记录在锁文件中。Flake 配置不能存放私钥或密码。

## 构建

未推送的本地配置：

```bash
sudo nixos-rebuild build --flake "$flake_ref#default" \
  --override-input private-config "path:$PWD/private-config" --no-write-lock-file
```

使用已提交并推送的私有配置：

```bash
nix flake update --flake "$flake_ref" private-config
sudo nixos-rebuild build --flake "$flake_ref#default"
sudo nixos-rebuild test --flake "$flake_ref#default"
sudo nixos-rebuild switch --flake "$flake_ref#default"
```

先检查 SSH 新连接和桌面，再重启验证内核与 SDDM。无需复制配置到 `/etc/nixos`。
