# NixOS 配置

[English](README.md) | 中文

Niri 桌面与 Home Manager 配置，使用 Flake 固定依赖。真实主机配置保存在独立的私有仓库，本地目录为 `private-config/`。

## 桌面环境

Niri、SDDM / Pixie、QuickShell（marko-shell 顶栏）、Wofi、Kitty、Mako，采用 Tokyo Night 配色。

顶栏为 `assets/config/quickshell/marko-shell/` 中的 QuickShell 配置，安装到 `~/.config/quickshell/marko-shell`。

工作区用橙色圆点提示 urgency。已连接的 Wi-Fi 行通过安装的 `iw` 工具读取内核关联状态中的 BSSID，并要求同一状态中的 SSID 与 QuickShell 行一致，避免把同名邻近 AP 错配到当前网络；未连接行不再推测 AP 地址。本配置不再安装旧 Waybar、bzmenu 和 networkmanager_dmenu。

换肤后的 Qt 控件在弹窗取得键盘焦点时支持键盘操作；默认悬停关闭弹窗仍不 grab。现有 `Theme.popupGrabFocus` 可切回 grab 模式，但外部点击关闭将由合成器处理。

## 工具

Zsh / Oh My Zsh、Neovim、LLVM / Clang、Python、btop、QQ、可选的公钥 SSH。

Neovim 插件由 submodule 固定并只读部署；Tree-sitter parser 和 query 安装到可写的 Neovim data `site` 目录。所需语言通过 `:TSInstall` 安装，升级 Tree-sitter 插件后显式运行 `:TSUpdate`；启动时不自动安装或更新 parser。

## 目录

```text
flake.nix                  # 系统入口
flake.lock                 # 首次迁移生成并提交
configuration.nix          # 通用系统设置
cli.py                     # 交互工具与 QQ 下载入口
scripts/private_config.py  # 私有配置仓库管理
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

先核对 `private-config/host.nix` 的用户名、主机名、启动方式及两个 `stateVersion`，然后运行交互工具配置 SSH、更新 QQ：

```bash
./cli.py
```

每次准备应用更新前先考虑运行 `update-qq`，避免上游旧版本下架；复现旧版本或回滚时不要更新。

## 私有仓库

```bash
# 从已存在的仓库初始化或切换；已有 private-config/ 必须没有未提交修改。
./cli.py private switch \
  git@github.com:YOUR_ACCOUNT/private-config.git

./cli.py private status
```

切换会拒绝未提交的本地修改，将候选仓库检出到新 lock 中的精确 revision（detached HEAD）并重新验证，保留旧目录备份，失败时恢复输入和锁文件。继续开发前先创建开发分支。私有仓库管理命令不会提交、推送或激活系统；交互菜单中的 `switch-dev` 和 `switch-prod` 会激活系统。输入来源写入 `flake.nix`，提交写入 `flake.lock`。公钥和硬件内容不会进入公共主仓库；私有仓库地址及 revision 会记录在锁文件中。Flake 配置不能存放私钥或密码。

## 构建与激活

运行 `./cli.py` 打开交互菜单，选择以下四个选项之一，再确认执行（不是 `./cli.py build-dev` 形式的子命令）：

| 选项 | 私有配置来源 | 行为 |
| --- | --- | --- |
| `build-dev` | 本地 `private-config/`，包括尚未提交的修改 | 只构建，不激活 |
| `switch-dev` | 同上 | 构建并立即激活系统 |
| `build-prod` | `flake.nix` 声明、`flake.lock` 固定的输入 | 只构建，不激活 |
| `switch-prod` | 同上 | 构建并立即激活系统 |

四项均调用 `sudo nixos-rebuild`，系统配置为 `default`，公共配置来自当前本地 Git 工作树并包含子模块。`prod` **不是拉取公共仓库最新 HEAD**，也不自动更新私有仓库 revision；若仍使用模板输入，prod 就会构建模板并触发其保护断言。prod 要求存在已审查且已纳入 Git 索引的 `flake.lock`，并通过 `--no-update-lock-file` 禁止自动更新；缺失或失配直接失败。

`dev` 添加本地私有目录覆盖和 `--no-write-lock-file`；prod 不覆盖输入。新建的公共配置文件必须先纳入 Git 索引，否则 Git flake 不会包含它们。已删除 `private build-local`，改用交互菜单中的 `build-dev`（会调用 sudo）。

以下为对应的手动构建流程：

未推送的本地配置：

```bash
sudo nixos-rebuild build --flake "$flake_ref#default" \
  --override-input private-config "path:$PWD/private-config" --no-write-lock-file
```

使用已提交并推送的私有配置：

```bash
nix flake update --flake "$flake_ref" private-config
sudo nixos-rebuild build --flake "$flake_ref#default" --no-update-lock-file
sudo nixos-rebuild test --flake "$flake_ref#default" --no-update-lock-file
sudo nixos-rebuild switch --flake "$flake_ref#default" --no-update-lock-file
```

先检查 SSH 新连接和桌面，再重启验证内核与 SDDM。无需复制配置到 `/etc/nixos`。
