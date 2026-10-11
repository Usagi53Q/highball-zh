# Highball 中文汉化补丁 (简体中文 & 繁體中文)

<p align="left">
  <img src="https://img.shields.io/badge/Platform-macOS%2014%2B%20(Apple%20Silicon)-000000?style=flat-square&logo=apple&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Target%20App-Highball%20v0.10.10-f59e0b?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/Language-简体中文%20%7C%20繁體中文-10b981?style=flat-square" alt="Language" />
  <img src="https://img.shields.io/badge/License-GPL--3.0-f59e0b?style=flat-square" alt="License" />
</p>

专为 macOS (Apple Silicon) 平台的开源 Windows 游戏启动器 **[Highball](https://github.com/gauthierpiarrette/highball)** 打造的完整中文化补丁，同时支持 **简体中文 (`zh-Hans`)** 与 **繁體中文 (`zh-Hant`)**。

---

## 汉化特性

- **100% 全界面覆盖**：完整汉化 `L10n.swift` 全部 530+ 条界面词条，以及 `GamePageCopy.swift`、`Recovery.swift`、`ActivityText.swift` 中的动态兼容性结论、启动计划、帧生成（Lossless Scaling）说明与错误恢复引导。
- **简繁双语原生支持**：
  - **简体中文 (`zh-Hans`)**：符合中国大陆 macOS 与 PC 游戏玩家术语习惯（容器、渲染器、垂直同步、帧生成、运行库依赖、访达等）。
  - **繁體中文 (`zh-Hant`)**：符合台灣與港澳地區 macOS 慣用語（設定、預設、資料夾、磁碟、滑鼠、全螢幕、解析度、更新率、執行階段函式庫、相容性、防作弊等）。
- **无视系统语言限制**：无论你的 macOS 系统语言是英文还是中文，安装后均可直接以所选的简体或繁体中文启动，并支持随时通过一条命令秒级切换。
- **安全可逆**：安装脚本自动将原版可执行文件备份为 `Highball.orig`，随时可通过 `uninstall.sh` 无损还原。

---

## 快速安装

确保你已将原版 **[Highball](https://github.com/gauthierpiarrette/highball/releases)** 安装在 `/Applications/Highball.app`，然后在终端中运行：

```bash
git clone https://github.com/Usagi53Q/highball-zh.git
cd highball-zh
chmod +x install.sh uninstall.sh
./install.sh
```

### 命令行直接指定语言

- **安装简体中文版（默认）**：
  ```bash
  ./install.sh --zh-hans
  ```
- **安裝繁體中文版**：
  ```bash
  ./install.sh --zh-hant
  ```

### 免重装快速切换简繁英

由于补丁二进制内部已同时内置简体中文、繁體中文、英文与法文词库，安装后你也可以随时在终端执行以下命令切换语言（重启 Highball 即可生效）：

```bash
# 切换为简体中文
defaults write app.highball.Highball HighballLanguage -string "zh-Hans"

# 切換為繁體中文
defaults write app.highball.Highball HighballLanguage -string "zh-Hant"

# 切换回英文原版界面
defaults write app.highball.Highball HighballLanguage -string "en"
```

---

## 恢复原版 / 卸载补丁

如需卸载汉化并还原为官方原版二进制，只需运行：

```bash
./uninstall.sh
```

---

## 仓库目录结构

```text
highball-zh/
├── bin/
│   ├── Highball                # 默认预编译汉化二进制文件（含简繁双语词库）
│   ├── zh-Hans/
│   │   └── Highball            # 简体中文默认回退版可执行文件
│   └── zh-Hant/
│       └── Highball            # 繁體中文預設回退版可執行檔
├── src/
│   ├── HighballApp/
│   │   ├── L10n.swift          # 简繁双语 + 法语完整本地化字典（530+ 词条）
│   │   ├── ActivityStrip.swift # 底部状态栏本地化调用增强
│   │   ├── HighballApp.swift   # 弹窗与按钮本地化补全
│   │   └── SettingsView.swift  # 设置窗口与确认弹窗本地化补全
│   └── HighballKit/
│       ├── GamePageCopy.swift  # HighballLang 语言切换器与游戏详情页动态文案汉化
│       ├── ActivityText.swift  # 传输进度格式优化
│       └── Recovery.swift      # 异常诊断与恢复引导简繁双语汉化
├── entitlements.plist          # 麦克风音频输入权限签名配置
├── install.sh                  # 一键安装脚本（支持简体/繁體交互选择与参数指定）
├── uninstall.sh                # 一键卸载还原脚本
├── LICENSE                     # GPL-3.0 开源许可证（与上游一致）
└── README.md                   # 项目说明文档
```

---

## 从源码自行构建

如果你想基于上游最新源码自行编译此汉化补丁：

```bash
# 1. 克隆上游 Highball 仓库
git clone --depth 1 --branch v0.10.10 https://github.com/gauthierpiarrette/highball.git
cd highball

# 2. 覆盖本仓库 src/ 下的汉化源码文件
cp -R /path/to/highball-zh/src/HighballApp/* Sources/HighballApp/
cp -R /path/to/highball-zh/src/HighballKit/* Sources/HighballKit/

# 3. 使用 Swift Package Manager 编译 Release 二进制
swift build -c release --product HighballApp
```

---

## 致谢与开源许可

- 上游项目：[gauthierpiarrette/highball](https://github.com/gauthierpiarrette/highball)
- 本项目遵循与上游一致的 **GPL-3.0 License** 开源许可协议。
