# 动态锁屏

[English](lockscreen.md) | 中文

## 使用与失败行为

`Super+Alt+L` 启动 `marko-lock`。输入当前用户密码，按 Enter 提交。Escape 只清空输入，绝不解锁。配置中只有这一种锁屏器，不保留第二套锁屏实现或接管快捷键。

启动器用 flock 串行处理并发请求。首次启动独立的 QuickShell 0.3.2 进程；解锁后进程常驻，但不保留视频 surface。冷启动给 daemon 最多 15 秒加载 QML，再给 IPC 就绪响应最多五秒；启动失败会报告退出状态和 QuickShell 近期日志。待进程就绪后，启动器按输出逐屏用 `grim` 截取锁前桌面，随后调用 `lock.engage` 并等待 compositor 的 `secure` 确认。截图文件位于用户私有的 `XDG_RUNTIME_DIR/marko-lock-capture`，退出锁定后删除；下次锁定也会先清理旧文件。截图失败不阻断安全锁定，转场使用不透明主题底色兜底。三秒内未收到安全确认则打印错误、返回非零，**不得把该次调用当作锁屏成功**。若 Niri 已进入锁定态，锁屏进程异常后 Niri 仍保留锁定背景。

若锁屏进程死亡、Niri 显示锁定背景，再按一次 `Super+Alt+L`：此绑定在锁定时仍可用，启动器会尝试新建实例。这符合 [Niri 官方恢复说明](https://github.com/niri-wm/niri/wiki/FAQ#how-do-i-recover-from-a-dead-screen-locker--from-a-red-screen)。若旧进程仍在但无响应，或 compositor 自身故障，则可能需要从 TTY 处理；快捷键不能保证修复所有故障。部署前应确认 TTY 登录可用；不要为绕过认证错误而强制解锁会话。

新增公开文件必须先进入 Git 索引，Git-backed flake 才会收录。打开交互式 `./cli.py` 菜单，依次选择 `build-dev`、`switch-dev`，之后注销并重新登录。锁屏命令本身无需 sudo。无需新增私有文件，但此版本求值前必须从已有的 `private-config/theme/settings.json` 删除过时的 `colors.swaylock` 对象；附带的私有补丁适用于此前交付的那组配色。

## 配色

锁屏专用语义色定义在 `theme/colors.nix` 的 `lockscreen` 组。私有覆盖写入 `private-config/theme/settings.json` 的 `colors.lockscreen`，例如 `"colors": {"lockscreen": {"cardBackground": "#28363B", "inputSelection": "#ACD4E8"}}`。未覆盖的锁屏角色使用公开默认值；修改顶栏的 `colors.quickshell` 不再牵动锁屏配色。`theme/default.nix` 生成 `LockColors.qml`，Home Manager 将其安装进锁屏 QML 配置；不要直接修改 Nix store 中的生成文件。`Theme.qml` 仍只共享动画、字体、几何参数。视频／图片背景来自壁纸设置，`surfaceBackground` 是始终不透明的兜底色。

## 组件与边界

每个输出使用始终不透明的 `WlSessionLockSurface`。仅在 compositor 确认 `secure` 后开始入场动画和 PAM。所有屏幕共享一个 `PamContext`，使用 `/etc/pam.d/marko-lock` 和当前进程用户；密码不进入 CLI 参数或 IPC。只有 `PamResult.Success` 能启动退出动画，动画完成后才释放会话锁。退出期间再次请求锁屏会取消释放、重新认证。媒体错误、Escape、普通认证失败均不能解锁；连续 Enter 不会重复提交同一提示。

锁屏复用现有私有壁纸和 QuickShell 主题，不新增私有设置。安全 surface 始终全屏且不透明。入场改为 780 ms、各段独立缓动的三段 Overview 式动作：锁前冻结帧由 100% 缩至 70%；两张 70% 的画面以 32 像素间距横向滚动；锁屏画面由 70% 放大至 100%。PAM 成功后用 690 ms 反向播放三段，复用**锁入时**的冻结帧；动画结束才释放会话锁，Niri 随即直切实时桌面。不能在锁仍生效时让真实桌面透过锁屏表面，也不承诺最后切换帧无跳变。逐屏截图不是原子性的，也不保证恰为锁定前的最后一帧。若截图失败，启动器在 stderr 提示并保留不透明兜底；该输出无法呈现真实桌面缩小。

Qt Multimedia 与 mpvpaper 分别解码，锁入／解锁时视频相位可能跳变；每台显示器各有播放器，多屏负载须实测。媒体失败时回退静态图或不透明主题底色，不阻塞认证。原有 swayidle 策略不变；不新增闲置超时或休眠钩子。

## 目标机器验收

离屏测试运行真实 QML 界面／控制器，但使用**模拟 PAM**，不能代替真实账户认证或 Wayland 安全性测试。测试媒体是无用户数据的 64×48、20 帧 MPEG-4 人工视频。目标机器还需验证：

| 测试 | 预期 |
| --- | --- |
| 正确／错误密码，连续 Enter | 只有真实 PAM 成功才解锁；每个提示只提交一次 |
| Escape、外部点击、初始焦点 | 保持锁定；输入和焦点符合界面行为 |
| 退出动画期间再次请求锁定 | 取消退出并重新认证 |
| PAM 故障或尝试上限 | 继续锁定；界面允许时重试，否则走 TTY 恢复 |
| 媒体丢失或编码不支持 | 不透明背景，认证界面可用 |
| 截图失败、输出名变化 | 退回不透明主题底色，认证与安全锁定不受影响 |
| 入场、出场、解锁交界 | 780 ms 缩小 → 滚动 → 放大；690 ms 反向；最后直切实时桌面 |
| 多屏、热插拔、缩放 | 覆盖所有输出，切换焦点后可输入 |
| 熄屏、休眠恢复 | 不泄露桌面，仍能认证 |
| 启动或安全确认失败 | 命令返回非零，不宣称锁定成功 |
| 锁定后进程死亡 | Niri 保留锁定背景；同一快捷键可启动新实例 |

上游依据见[英文说明末尾](lockscreen.md)。
