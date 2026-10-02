# Project2026 Windows 试玩包

最新包体：2026-10-02，Windows x64，Development，包含已验证的登录 Loading。

## 下载与启动

在网页选择 Code → Download ZIP，完整解压后双击 `Windows/开始游戏.bat`，也可双击根目录 `Repair_and_Start.bat`。GitHub 网页 ZIP 中的大文件可能只有 LFS 指针，启动器会下载真实资源并校验，完成后自动开启游戏，无需 Unreal Engine 或 Git。

首次必需下载约 3.54 GB，4 路并发、64 MB 分片、断线续传。已有完整且 SHA256 一致的文件直接复用；不同版本的下载进度分开保留，不混用。GitHub 网络速度取决于所在地网络。

已有旧安装的玩家：关闭旧下载窗口，下载最新 `Windows/开始游戏.bat` 覆盖同名文件，再双击运行。保留 Windows 文件夹，完整旧资源按校验结果复用。旧入口仍固定旧版本；不会自动升级，请替换入口。

原生资源、运行库与说明位于 `Windows/`，不要只复制 EXE。Windows 10/11 64 位，默认 DirectX 12；需要运行库时使用 `Windows/Engine/Extras/Redist/en-us/vc_redist.x64.exe`。

默认连接 `tencent.codepeak.cn:5555` 测试服，需要可用试玩账号。本次发布未部署或重启服务器。

## 验收

- 本轮打包客户端正常音频、登录界面、测试服握手通过。
- 场景验收 293 项通过，两轮八次切图、十二次移动。
- 登录 Loading 验收 33 项客户端断言和 5 项画面检查通过。
- 快照 Lua 回归 83 项通过。未进行真实账号交易。
- 旧独立海钓场景的部分鱼材质可能显示异常。

新版下载清单 `download_manifest_20261002_1713.json`、下载器与入口使用配套固定提交，防止缓存混用。`build_manifest.json` 和 `SHA256SUMS.txt` 对应最新原生包体；原 `download_manifest.json` 与旧 Release 保留，供旧入口继续下载旧版本。

新版 Release：[playtest-20261002-1713](https://github.com/aarongameboy/package/releases/tag/playtest-20261002-1713)。资源分片由启动器自动还原，无需手动合并。Git LFS 用户也可以 clone 仓库并执行 `git lfs pull` 后直接启动 `Windows/Project2026.exe`。
