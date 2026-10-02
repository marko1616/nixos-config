# Rime U/V 模式（小鹤双拼，Fcitx5）

[English](rime-uv.md) | 中文

`programs.markoInput.enable` 提供 Fcitx5 + Rime：默认小鹤双拼，`Shift+U` 进 U 模式，
`Shift+V` 进 V 模式。

## 行为

| 输入 | 结果 |
| --- | --- |
| 常规 | 小鹤双拼；普通小写 `u`/`v` 仍按双拼键位输入 |
| `Shift+U` + `hspnz` | 笔画查字（横竖撇捺折），如 `Uhspn` → 木 |
| `Shift+U` + 双拼部件码 | 部件拆字，如 `Umumu` → 林 |
| `Shift+U` + `udw`/`uxh`/`uts`/`ubd`/`usx`/`ujh`/`uzm` | 单位/序号/特殊/标点/数学/几何/字母 |
| `Shift+V` | 数字、日期、时间、算式；`UC`+Unicode 码位，`GB`+GB18030 编码 |
| `Esc` | 退出模式，不改变方案状态 |

在 U/V 模式中，`Space` 或 `Enter` 提交当前候选，`Ctrl+Enter` 提交原始输入，`Esc` 取消。`1…7` 按序号选词仅适用于 **U 模式**；V 模式的数字属于输入表达式。完整按键摘要见[快捷键说明](shortcuts_zh.md)。

## 结构

- `desktop/rime.nix` — 模块与开关；input method 组只做初始化，不覆盖已有用户配置。系统激活不删除或改写用户的 Rime 目录；编译缓存由用户在 Fcitx5 的 Rime 菜单中重新部署。
- `desktop/rime-data.nix` — rime-ice 以 Git submodule（`assets/rime-ice`，固定 revision）引用，
  rime-stroke 按 revision 取自上游；两者与 `assets/rime` 一并拼装，在构建期编译并断言
  关键产物存在。
- `assets/rime/marko-input.schema.yaml` — 在小鹤方案上打补丁，接入 U/V 处理链。
- `assets/rime/marko_terms.dict.yaml` — 从 `USER.md` 挑选的中文专业词语与作品名，以词典扩展包挂载，保留雾凇拼音主词典及原有用户学习数据。
- `assets/rime/marko_phrase_double.txt` — 项目名和缩写的完整小写输入码（如 `riscv` → `RISC-V`）；不包含账号或基础设施标识。
- `assets/rime/marko-input-radical.schema.yaml`、`marko-input-stroke.schema.yaml` — 独立 prism，
  不改写其它已安装方案的编码。
- `assets/rime/lua/marko_uv_*.lua` — 入口处理与译文；`lua/marko_uv/` — V 模式与符号表。
- `scripts/build_rime_uv_data.py` — 由固定上游文件生成 `symbols.lua` 与 `gb_data.lua`；
  构建期完成，运行期无网络访问。

## 已知约束

- `lua_translator` 收到的是 **const** `Segment`（`LuaType<rime::Segment const&>`）。对 `seg`
  赋值会被绑定层以 `bad argument #2 ... (LuaType<rime::Segment> expected)` 拒绝并中断该次
  译文，因此译文内不写 `seg`。模式提示未启用：只在滤镜（segment 可变）里设 `seg.prompt`
  会改变 preedit 渲染，把提示插进组合串。
- 笔画与拆字共用 `uv` 标签：精确匹配优先，其余轮转合并。
- GB18030 表取自 WHATWG Encoding 固定 revision，与微软实现并非逐字节同源。

## 首次启用与更新

使用 `./cli.py` 菜单完成构建和切换后，注销并重新登录，让 Fcitx5 加载新插件和共享数据。
若已有个人 Fcitx5 profile，系统默认组不会覆盖它；先在 Fcitx5 配置中将 Rime 加入当前输入法组，并选择 `marko-input` 方案。
然后在 Fcitx5 的 Rime 菜单中选择 **Deploy（重新部署）**，由 Rime 在当前用户的实际数据目录中更新编译缓存；设置了非默认 `XDG_DATA_HOME` 时同样适用。
之后每次更新该数据包，都在新会话中执行一次重新部署。系统切换本身不重启正在运行的 Fcitx5，也不清理任何用户的 `build/`、词库或 `sync/`。

## 验证

- 引擎级测试：真实 librime 加载该方案，86 项断言通过（笔画、拆字、7 个符号类别及翻页与
  数字选词、V 模式各形式、非法输入与 Esc、光标编辑、小键盘、ascii 透传、常规双拼）。
- `rime_deployer --build` 作为构建门禁。

## 回退

`programs.markoInput.enable = false;` 并移除 `desktop/rime.nix` 的 import，即回到原状。
