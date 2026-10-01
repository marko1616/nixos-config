# 本仓库的默认快捷键

[English](shortcuts.md) | 中文

这里列出的是**仓库配置中已生效的绑定**，不是 Niri、Neovim 或 Fcitx 的全部上游默认键。Niri 的准确信息以 [`assets/config/niri/config.kdl`](../assets/config/niri/config.kdl) 中的 `binds` 为准。普通 Niri TTY 会话里 `Mod` 为 Super（winit 后端为 Alt）；`Ctrl`、`Shift` 是独立修饰键。`Mod+Shift+/` 可以打开 Niri 的屏幕快捷键提示。KDL 中注释掉的绑定不生效。

## Niri：启动与会话

| 按键 | 操作 |
| --- | --- |
| `Mod+T` / `Mod+D` | 打开 Kitty / Wofi |
| `Super+Alt+L` | 使用 swaylock 锁屏 |
| `Mod+O` | 切换概览 |
| `Mod+Q` | 关闭当前窗口 |
| `Mod+Shift+E` 或 `Ctrl+Alt+Delete` | 退出 Niri，需确认 |
| `Mod+Shift+P` | 关闭显示器，直到下一次输入 |
| `Mod+Escape` | 切换快捷键抑制；远程控制程序失灵时的退出通道 |

## Niri：焦点与移动

| 按键 | 操作 |
| --- | --- |
| `Mod+Left/Right` 或 `Mod+H/L` | 聚焦相邻列 |
| `Mod+Up/Down` 或 `Mod+K/J` | 聚焦上／下窗口 |
| 上述方向键再加 `Ctrl` | 左右移动当前列，或上下移动当前窗口 |
| `Mod+Home/End`；再加 `Ctrl` | 聚焦首／末列；将列移动到首／末 |
| `Mod+Shift+方向键` 或 `Mod+Shift+H/J/K/L` | 聚焦相邻显示器 |
| 上述显示器绑定再加 `Ctrl` | 将列移到相邻显示器 |
| `Mod+Page_Up/Page_Down` 或 `Mod+I/U` | 聚焦上／下工作区 |
| 上述工作区绑定再加 `Ctrl` | 将列移到上／下工作区 |
| `Mod+Shift+Page_Up/Page_Down` 或 `Mod+Shift+I/U` | 上／下调整工作区次序 |
| `Mod+1…9`；再加 `Ctrl` | 聚焦指定编号工作区；将列移过去 |

Niri 使用动态工作区：指定的编号超过现有数量时，会选中最下方的空工作区。`Mod+滚轮` 也可切换工作区，`Mod+Ctrl+滚轮` 可移动列。水平滚轮或 `Mod+Shift+竖向滚轮` 可切换列；再加 `Ctrl` 则移动列。

## Niri：布局与显示

| 按键 | 操作 |
| --- | --- |
| `Mod+[` / `Mod+]` | 向左／右列合并或移出窗口 |
| `Mod+,` / `Mod+.` | 从右侧收进当前列／移出当前列底部窗口 |
| `Mod+R` / `Mod+Shift+R` | 正向／反向循环预设列宽 |
| `Mod+Ctrl+Shift+R` / `Mod+Ctrl+R` | 循环预设窗口高度／重置高度 |
| `Mod+F` / `Mod+Shift+F` | 最大化列／窗口全屏 |
| `Mod+M` / `Mod+Ctrl+F` | 窗口扩展至屏幕边缘／列占满可用宽度 |
| `Mod+C` / `Mod+Ctrl+C` | 居中当前列／所有可见列 |
| `Mod+-` / `Mod+=` | 列宽减少／增加 10% |
| `Mod+Shift+-` / `Mod+Shift+=` | 窗口高度减少／增加 10% |
| `Mod+V` / `Mod+Shift+V` | 切换浮动／在浮动与平铺间切换焦点 |
| `Mod+W` | 切换列的标签页显示 |
| `Print` 或 `Super+Shift+S` | 交互式截图 |
| `Ctrl+Print` / `Alt+Print` | 截取屏幕／当前窗口 |

`XF86AudioRaiseVolume` 和 `XF86AudioLowerVolume` 每次调节音量 10%；静音键与麦克风静音键分别切换对应通道。`XF86AudioPlay/Stop/Prev/Next` 控制 MPRIS 播放；`XF86MonBrightnessUp/Down` 每次调节背光 10%。这些绑定也写在同一 Niri 文件中。

## 其他已配置按键

| 场景 | 按键 | 操作 |
| --- | --- | --- |
| Neovim 普通／可视模式 | `<leader>f` | 通过 Conform 异步格式化缓冲区／选区，回退到 LSP；定义见 [`keymaps.lua`](../assets/config/nvim/lua/config/keymaps.lua)。仓库未设置 `mapleader`，实际前缀取决于 Neovim 设置及用户覆盖。 |
| QuickShell 交互面板 | `Esc` | 关闭已打开的面板；见 [`PopoverBase.qml`](../assets/config/quickshell/marko-shell/PopoverBase.qml)。 |
| Rime `marko-input` | `Shift+U` / `Shift+V` | 进入笔画／拆字／符号模式或数字／日期／时间／算式／编码模式。普通小写 `u`、`v` 仍是小鹤双拼输入。 |
| Rime U/V 模式 | `Esc` 或 `Ctrl+Backspace` | 取消；`Backspace` 编辑，剩模式前缀时取消。 |
| Rime U/V 模式 | `Space` / `Enter`；`Ctrl+Enter` | 提交当前候选；提交原始输入。 |
| Rime U/V 模式 | `Up/Down`、`Page Up/Down` | 移动候选／翻页。 |
| Rime U 模式 | `1…7` | 按当前页序号选词；V 模式的普通数字是表达式输入。 |
| Rime U/V 模式 | `Ctrl+1…7` | 按当前页序号选词。 |

Rime 用法与示例见 [Rime U/V 模式](rime-uv_zh.md)。仓库没有配置 Fcitx 全局输入法切换键；它取决于用户自己的 Fcitx profile。
