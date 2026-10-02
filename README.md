# Project2026 Windows 试玩包

2026-10-01 制作的完整、未压缩 Windows 包体位于 `Windows/`。无需 Unreal Engine 编辑器。

## 下载并运行

推荐在网页选择 **Code → Download ZIP**，完整解压后双击根目录 `Repair_and_Start.bat`。
它会自动更新下载器，从 GitHub Release 并行下载缺失的真实游戏文件，逐文件校验 SHA256，完成后启动游戏。无需安装 Git。
首次必需下载约 3.53 GB，默认 4 路并发；已有完整文件直接复用，旧版 `.download` 中间文件也可续传。跳过 Vulkan 调试组件、GPU 分析工具与 ARM 安装包。中断后再次运行即可继续，请保留完整目录结构。

已下载旧版 `package-main` 且出现“16 位应用程序”提示时，将最新版 `Repair_and_Start.bat` 放进
`package-main` 根目录（与 `Windows` 文件夹同级），先关闭旧下载窗口，再双击修复。不要把它放进 `Windows` 子目录。新启动器会刷新旧版下载器，不需要删除已经下载的内容。

也可以安装 Git 和 Git LFS 后运行：

```powershell
git lfs install
git clone https://github.com/aarongameboy/package.git
cd package
git lfs pull
```

打开 `Windows` 文件夹，双击 `开始游戏.bat`；此入口也会自动刷新根目录启动器并使用新版下载器。也可以直接运行同目录的 `Project2026.exe`。
必须保留 `Engine` 和 `Project2026` 的完整目录结构，不要只复制启动程序。

GitHub 网页 ZIP 中的大文件可能是 LFS 指针。请先运行修复启动器，再启动 EXE；否则 Windows 会误报“16 位应用程序”。

## 试玩说明

- Windows 10/11 64 位，默认 DirectX 12。包体约 3.59 GB。
- 默认连接 `tencent.codepeak.cn:5555` 测试服，需要网络和可用试玩账号。
- 操作及运行库安装入口见 `Windows/试玩说明.txt`。
- 大资源采用引擎原生分区文件；游戏自动读取，无需合并。
- 成品通过正常音频启动和测试服握手/心跳；资源重新分区后再次通过 293 项本地场景检查（2轮8次切图、12次移动）。
- 本地场景测试使用测试数据，未用真实账号完成完整游戏流程。
- 旧独立海钓场景的部分鱼材质可能显示异常。

`build_manifest.json` 与 `SHA256SUMS.txt` 记录上传文件大小和校验和。不包含编辑器、源码、调试符号或试玩账号。

下载速度受 GitHub 在所在地的网络影响，无法保证国内网络速度；Release 不通时自动退回原文件渠道。两块大资源经 64 MB 分片自动还原，无需手动合并。每个分片和完整文件校验通过后才替换目标文件，下载失败不会启动不完整游戏。
