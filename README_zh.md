# NixOS 配置

[English](README.md) | 中文

Niri 桌面与 Home Manager 配置，使用 Flake 固定依赖。真实主机配置保存在独立的私有仓库，本地目录为 `private-config/`。

## 桌面环境

Niri、SDDM / Pixie、QuickShell（marko-shell 顶栏）、Wofi、Kitty、Mako，采用 Tokyo Night 配色。

顶栏为 `assets/config/quickshell/marko-shell/` 中的 QuickShell 配置，安装到 `~/.config/quickshell/marko-shell`。

Fcitx5 经典界面的候选窗默认使用 `assets/config/fcitx5/marko-shell/` 主题；Home Manager 还会将其链接到 `~/.local/share/fcitx5/themes/marko-shell/`，使未从整合包装器启动的 Fcitx 也能发现主题。主题以 Tokyo Night 配色和 SVG 圆角匹配顶栏。现有的 `~/.config/fcitx5/conf/classicui.conf` 优先于系统默认设置：在「Fcitx5 配置 → 附加组件 → 经典用户界面」中，为 Theme 选择「Marko Shell」（若跟随系统明暗配色，Dark Theme 也选它）。激活后若仍看不到主题，先注销并重新登录再检查。经典界面主题不能为候选窗添加动画，QuickShell 弹窗动画也不会作用于 Fcitx5。
Rime 输入法提供方案 `marko-input`：默认小鹤双拼；`Shift+U` 进入笔画与部件拆字，并可按类别取符号（`udw`、`uxh`、`uts`、`ubd`、`usx`、`ujh`、`uzm`）；`Shift+V` 输入中文数字、日期、时间与算式，以及 Unicode 码位（`UC`）和 GB18030 编码（`GB`）。关闭方式为 `programs.markoInput.enable = false;`。上游来源按 revision 固定，方案在构建期编译；激活过程不触碰用户 Rime 数据。切换系统后先注销并重新登录，再通过 Rime 菜单的「重新部署」更新用户编译缓存。详见 [Rime U/V 模式](docs/rime-uv_zh.md)。

工作区用橙色圆点提示 urgency。Wi-Fi 行从 NetworkManager 的缓存扫描结果读取 BSSID，因此未连接的网络也会显示当前可见信号最强的 AP，并标出其余同名 AP 的数量。已连接行只有在扫描结果为该设备和 SSID 找到唯一活动 BSSID 时才显示活动地址。密码输入由顶栏自己的 NetworkManager 连接助手处理，点击 Connect 不会再打开第二个系统密码窗口。本配置不再安装旧 Waybar、bzmenu 和 networkmanager_dmenu。

可交互面板使用能接收键盘输入的透明覆盖层。输入区域遮罩让顶栏继续接收鼠标事件，同时观察顶栏下方的移动和外部点击。鼠标离开顶栏与面板 500 毫秒后开始单向退出动画；一旦开始，移回也不会倒放复原。外部点击会被消耗并播放退出动画，Esc 也会关闭面板。顶栏与面板共用提亮的底色，细描边沿融合后的 SDF 外轮廓绘制。延迟可在 `Theme.qml` 的 `popupLeaveDelay` 中调整。密码框保持无边框，文字、占位提示和光标垂直居中。提示框保持非交互，不抢占键盘焦点。

## 工具

Zsh / Oh My Zsh、Neovim、LLVM / Clang、Python、btop、QQ、可选的公钥 SSH。

Neovim 插件由 submodule 固定并只读部署；Tree-sitter parser 和 query 安装到可写的 Neovim data `site` 目录。所需语言通过 `:TSInstall` 安装，升级 Tree-sitter 插件后显式运行 `:TSUpdate`；启动时不自动安装或更新 parser。

## 目录

文件／部署映射与生效快捷键见[文档目录](docs/README_zh.md)。

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

## 锁文件菜单

运行 `./cli.py` → `flake-lock`（菜单项，不是子命令），选择初始化／补全（保留有效锁定）、更新指定输入、更新全部输入，或查看／暂存当前锁文件。首次使用选初始化／补全。操作使用 `flake.nix` 声明的输入，不带 dev 的本地覆盖；更新 `private-config` 锁定不会切换其本地 checkout。

Nix 先生成临时候选文件，展示操作前后及相对 HEAD 的差异，再选择丢弃、仅保存，或保存并**仅暂存整个 `flake.lock`**（替换它原有的暂存版本）。其他文件的暂存状态不变。生成失败或保存前取消不会改变原锁文件和索引；暂存失败则保留已保存的文件，便于重试。不会调用 sudo、提交、推送、构建或激活系统；prod 的严格锁定检查保持不变。

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

私有配置提交并推送后，在 `flake-lock` 中选择更新指定输入 → `private-config`，审阅并暂存结果，再选择 `build-prod` 或 `switch-prod`。

先检查 SSH 新连接和桌面，再重启验证内核与 SDDM。无需复制配置到 `/etc/nixos`。
