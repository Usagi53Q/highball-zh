import Foundation

/// Highball 语言选择与简繁双语辅助工具
public enum HighballLang {
    case zhHans
    case zhHant
    case fr
    case en

    /// 获取当前生效的界面语言
    public static var current: HighballLang {
        if let env = ProcessInfo.processInfo.environment["HIGHBALL_LANG"]?.lowercased() {
            if env.contains("hant") || env.contains("tw") || env.contains("hk") { return .zhHant }
            if env.contains("hans") || env.contains("cn") || env.contains("zh") { return .zhHans }
            if env.hasPrefix("fr") { return .fr }
            if env.hasPrefix("en") { return .en }
        }
        if let pref = UserDefaults.standard.string(forKey: "HighballLanguage")?.lowercased() {
            if pref.contains("hant") || pref.contains("tw") || pref.contains("hk") { return .zhHant }
            if pref.contains("hans") || pref.contains("cn") || pref.contains("zh") { return .zhHans }
            if pref.hasPrefix("fr") { return .fr }
            if pref.hasPrefix("en") { return .en }
        }
        for lang in Locale.preferredLanguages {
            let l = lang.lowercased()
            if l.contains("hant") || l.contains("tw") || l.contains("hk") { return .zhHant }
            if l.contains("hans") || l.contains("cn") || l.hasPrefix("zh") { return .zhHans }
        }
        #if DEFAULT_ZH_HANT
        return .zhHant
        #else
        return .zhHans
        #endif
    }

    /// 根据当前语言返回简体中文、繁體中文或英文文本
    public static func pick(hans: String, hant: String, en: String) -> String {
        switch current {
        case .zhHans: return hans
        case .zhHant: return hant
        case .en, .fr: return en
        }
    }
}

/// 游戏详情页上的说明文案（支持简繁双语及英文）
public enum GamePageCopy {
    public struct Verdict: Equatable {
        public var headline: String
        public var detail: String?
    }

    /// 根据当前 Mac 芯片与数据库条目生成兼容性结论
    public static func verdict(_ entry: GameDBEntry?, myChip: String, today: Date = Date()) -> Verdict {
        let mine = shortChip(myChip)
        guard let entry else {
            return Verdict(
                headline: HighballLang.pick(
                    hans: "尚无人在 \(mine) 上测试过此游戏。",
                    hant: "尚無人在 \(mine) 上測試過此遊戲。",
                    en: "Nobody has tested this on an \(mine) yet."),
                detail: HighballLang.pick(
                    hans: "兼容性数据库中暂无此游戏的记录。你将是第一位反馈运行情况的玩家。",
                    hant: "相容性資料庫中暫無此遊戲的記錄。你將是第一位回報執行情況的玩家。",
                    en: "Nothing in the compatibility database for it yet. You would be the first to report it.")
            )
        }
        switch entry.status {
        case "blocked-anticheat":
            let name = entry.anticheat?.names.first ?? HighballLang.pick(hans: "其反作弊系统", hant: "其防作弊系統", en: "its anti-cheat")
            return Verdict(
                headline: HighballLang.pick(
                    hans: "无法运行：\(name)。",
                    hant: "無法執行：\(name)。",
                    en: "Can't run: \(name)."),
                detail: entry.anticheat?.note ?? HighballLang.pick(
                    hans: "其反作弊系统不支持在 macOS 上运行。",
                    hant: "其防作弊系統不支援在 macOS 上執行。",
                    en: "Its anti-cheat does not run on macOS.")
            )
        case "blocked-publisher":
            return Verdict(
                headline: HighballLang.pick(
                    hans: "无法运行：发行商封锁了 macOS。",
                    hant: "無法執行：發行商封鎖了 macOS。",
                    en: "Can't run: its publisher blocks macOS."),
                detail: HighballLang.pick(
                    hans: "无论使用何种引擎或图形模式，该游戏一旦检测到 macOS 就会自行停止运行。",
                    hant: "無論使用何種引擎或圖形模式，該遊戲一旦偵測到 macOS 就會自行停止執行。",
                    en: "The game stops itself when it finds macOS, whatever the engine or graphics mode.")
            )
        case "verified-local":
            let chip = entry.verified?.chip.map(shortChip)
            var head = chip.map {
                HighballLang.pick(hans: "已在 \($0) 上通过验证。", hant: "已在 \($0) 上通過驗證。", en: "Verified on an \($0).")
            } ?? HighballLang.pick(hans: "已在本项目的测试 Mac 上通过验证。", hant: "已在本專案的測試 Mac 上通過驗證。", en: "Verified on this project's own Mac.")
            if chip == mine {
                head = HighballLang.pick(
                    hans: "已在与你相同的 \(mine) 芯片上通过验证。",
                    hant: "已在與你相同的 \(mine) 晶片上通過驗證。",
                    en: "Verified on an \(mine), the same chip as yours.")
            }
            var parts: [String] = []
            if let fps = entry.verified?.fps, let phrase = fpsPhrase(fps) {
                parts.append(phrase)
            }
            if let os = entry.verified?.macos {
                parts.append(HighballLang.pick(hans: "（运行于 macOS \(os)）", hant: "（執行於 macOS \(os)）", en: "on macOS \(os)"))
            }
            var detail = parts.isEmpty ? "" : sentenceCase(parts.joined(separator: " "))
            if let when = freshness(entry.lastVerified, today: today) {
                let confirmed = HighballLang.pick(hans: "最近确认于\(when)。", hant: "最近確認於\(when)。", en: "Last confirmed \(when).")
                let confirmedComma = HighballLang.pick(hans: "，最近确认于\(when)。", hant: "，最近確認於\(when)。", en: ", last confirmed \(when).")
                detail += detail.isEmpty ? confirmed : confirmedComma
            } else if !detail.isEmpty {
                detail += HighballLang.pick(hans: "。", hant: "。", en: ".")
            }
            if let chip, chip != mine {
                let yours = HighballLang.pick(hans: "你的 Mac 为 \(mine)。", hant: "你的 Mac 為 \(mine)。", en: "Your Mac is an \(mine).")
                detail += (detail.isEmpty ? "" : " ") + yours
            }
            return Verdict(headline: head, detail: detail.isEmpty ? nil : detail)
        case "reported-upstream":
            return Verdict(
                headline: HighballLang.pick(
                    hans: "上游报告可正常运行。",
                    hant: "上游回報可正常執行。",
                    en: "Reported working upstream."),
                detail: HighballLang.pick(
                    hans: "在渲染器的发行说明中被列为可正常运行；本项目尚未实机验证。你的 Mac 为 \(mine)。",
                    hant: "在渲染器的發行說明中被列為可正常執行；本專案尚未實機驗證。你的 Mac 為 \(mine)。",
                    en: "Named in the renderer's release notes as working; not verified here yet. Your Mac is an \(mine).")
            )
        default:
            return Verdict(
                headline: HighballLang.pick(
                    hans: "由玩家社区反馈。",
                    hant: "由玩家社群回報。",
                    en: "Reported by players."),
                detail: HighballLang.pick(
                    hans: "本项目尚未进行实机验证。你的 Mac 为 \(mine)。",
                    hant: "本專案尚未進行實機驗證。你的 Mac 為 \(mine)。",
                    en: "Not verified by this project yet. Your Mac is an \(mine).")
            )
        }
    }

    public struct MacBuild: Equatable {
        public var headline: String
        public var detail: String
        public var requirements: String?
        public var yourMac: String
        public var source: String
    }

    public static func macBuild(_ build: MacSteamBuild?, entry: GameDBEntry?, myChip: String, macOS: String) -> MacBuild? {
        guard let build else { return nil }
        let installed = build == .installed
        let source = switch build {
        case .installed:
            HighballLang.pick(hans: "Mac 版 Steam 显示该游戏已安装。", hant: "Mac 版 Steam 顯示該遊戲已安裝。", en: "Steam for Mac lists it as installed.")
        case .inDatabase:
            HighballLang.pick(hans: "来自兼容性数据库。", hant: "來自相容性資料庫。", en: "From the compatibility database.")
        case .onStore:
            HighballLang.pick(hans: "Steam 商店页面显示其支持 macOS。", hant: "Steam 商店頁面顯示其支援 macOS。", en: "Steam's store page lists macOS for it.")
        }
        return MacBuild(
            headline: installed
                ? HighballLang.pick(hans: "已在 Mac 版 Steam 中安装。", hant: "已在 Mac 版 Steam 中安裝。", en: "Installed in Steam for Mac.")
                : HighballLang.pick(hans: "Steam 上提供原生 Mac 版本。", hant: "Steam 上提供原生 Mac 版本。", en: "There is a native Mac build on Steam."),
            detail: installed
                ? HighballLang.pick(
                    hans: "点击“开始游戏”将直接通过 Mac 版 Steam 启动原生 Mac 版本，无需经过 Windows 兼容层。",
                    hant: "點擊「開始遊戲」將直接透過 Mac 版 Steam 啟動原生 Mac 版本，無需經過 Windows 相容層。",
                    en: "Play starts the Mac build through Steam for Mac, with no Windows layer in between.")
                : HighballLang.pick(
                    hans: "原生版本的性能体验优于任何 Windows 兼容层，且你的 Steam 购买已包含该版本。",
                    hant: "原生版本的效能體驗優於任何 Windows 相容層，且你的 Steam 購買已包含該版本。",
                    en: "It will beat running the Windows version through any compatibility layer, and your Steam purchase already includes it."),
            requirements: entry?.nativeMac?.available == true ? entry?.nativeMac?.note : nil,
            yourMac: HighballLang.pick(
                hans: "你的 Mac 为 \(shortChip(myChip))，系统版本 macOS \(macOS)。",
                hant: "你的 Mac 為 \(shortChip(myChip))，系統版本 macOS \(macOS)。",
                en: "Your Mac is an \(shortChip(myChip)) on macOS \(macOS)."),
            source: source)
    }

    public struct WillDo: Equatable {
        public var text: String
        public var cost: String?
        public var done: Bool
        public init(text: String, cost: String? = nil, done: Bool = false) { self.text = text; self.cost = cost; self.done = done }
    }

    public static func willDo(_ entry: GameDBEntry?, recipe: Recipe?, applied: Bool,
                              bottleRenderer: Renderer, explicit: Bool = false, gameOverride: Renderer? = nil,
                              needsDirect3D12: Bool = false,
                              osMajor: Int = ProcessInfo.processInfo.operatingSystemVersion.majorVersion) -> [WillDo] {
        var items: [WillDo] = []
        let rowMode = entry?.effectiveRenderer(osMajor: osMajor)
        let direct3D12Mode = (rowMode?.servesDirect3D12 == true ? rowMode : nil) ?? .d3dmetal
        let givesWay = needsDirect3D12 && !bottleRenderer.servesDirect3D12 && (explicit || rowMode == nil)
        if entry?.nativeVulkan == true {
            items.append(WillDo(text: HighballLang.pick(
                hans: "让游戏直接使用 Vulkan 进行渲染；图形模式设置对此游戏不生效",
                hant: "讓遊戲直接使用 Vulkan 進行渲染；圖形模式設定對此遊戲不生效",
                en: "Let it draw with Vulkan directly; the graphics mode does not apply to this game")))
        } else if let gameOverride {
            items.append(WillDo(text: HighballLang.pick(
                hans: "对此游戏使用 \(plainName(gameOverride))（由你指定）；当前环境仍保持为 \(plainName(bottleRenderer))",
                hant: "對此遊戲使用 \(plainName(gameOverride))（由你指定）；目前環境仍保持為 \(plainName(bottleRenderer))",
                en: "Use \(plainName(gameOverride)) for this game (set by you); the environment stays on \(plainName(bottleRenderer))")))
        } else if givesWay {
            items.append(WillDo(text: explicit
                ? HighballLang.pick(
                    hans: "对此游戏使用 \(plainName(direct3D12Mode))：该游戏仅支持 DirectX 12，而你环境的设置（\(plainName(bottleRenderer))）不支持。环境中的其他程序仍保持使用 \(plainName(bottleRenderer))",
                    hant: "對此遊戲使用 \(plainName(direct3D12Mode))：該遊戲僅支援 DirectX 12，而你環境的設定（\(plainName(bottleRenderer))）不支援。環境中的其他程式仍保持使用 \(plainName(bottleRenderer))",
                    en: "Use \(plainName(direct3D12Mode)) for this game: it only has DirectX 12, which \(plainName(bottleRenderer)), your environment's setting, does not have. The environment keeps \(plainName(bottleRenderer)) for everything else")
                : HighballLang.pick(
                    hans: "对此游戏使用 \(plainName(direct3D12Mode))：该游戏仅支持 DirectX 12，而当前环境的 \(plainName(bottleRenderer)) 不支持",
                    hant: "對此遊戲使用 \(plainName(direct3D12Mode))：該遊戲僅支援 DirectX 12，而目前環境的 \(plainName(bottleRenderer)) 不支援",
                    en: "Use \(plainName(direct3D12Mode)) for this game: it only has DirectX 12, which the environment's \(plainName(bottleRenderer)) does not have")))
        } else if explicit {
            if let wanted = entry?.effectiveRenderer(osMajor: osMajor), wanted != bottleRenderer {
                items.append(WillDo(text: HighballLang.pick(
                    hans: "使用你环境的设置 \(plainName(bottleRenderer))。数据库建议使用 \(plainName(wanted))，但环境的手动设置优先级更高",
                    hant: "使用你環境的設定 \(plainName(bottleRenderer))。資料庫建議使用 \(plainName(wanted))，但環境的手動設定優先順序更高",
                    en: "Use \(plainName(bottleRenderer)), your environment's setting. The database asks for \(plainName(wanted)), and an environment's own setting wins")))
            } else {
                items.append(WillDo(text: HighballLang.pick(
                    hans: "使用环境的设置 \(plainName(bottleRenderer))（由你指定）",
                    hant: "使用環境的設定 \(plainName(bottleRenderer))（由你指定）",
                    en: "Use \(plainName(bottleRenderer)), the environment's setting (set by you)")))
            }
        } else if let wanted = entry?.effectiveRenderer(osMajor: osMajor) {
            items.append(WillDo(text: wanted == bottleRenderer
                ? HighballLang.pick(
                    hans: "使用已验证的 \(plainName(wanted))",
                    hant: "使用已驗證的 \(plainName(wanted))",
                    en: "Use \(plainName(wanted)), the way it was verified")
                : HighballLang.pick(
                    hans: "对此游戏使用已验证的 \(plainName(wanted))，而非环境默认的 \(plainName(bottleRenderer))",
                    hant: "對此遊戲使用已驗證的 \(plainName(wanted))，而非環境預設的 \(plainName(bottleRenderer))",
                    en: "Use \(plainName(wanted)) for this game, the way it was verified, instead of the environment's \(wanted == bottleRenderer ? "" : plainName(bottleRenderer))")))
        } else {
            items.append(WillDo(text: HighballLang.pick(
                hans: "使用环境默认的 \(plainName(bottleRenderer))；数据库尚未指定更优模式",
                hant: "使用環境預設的 \(plainName(bottleRenderer))；資料庫尚未指定更優模式",
                en: "Use \(plainName(bottleRenderer)), the environment's setting; no verdict names a better one")))
        }
        if let args = entry?.effectiveLaunchArgs(osMajor: osMajor), !args.isEmpty {
            let joined = args.joined(separator: " ")
            items.append(WillDo(text: HighballLang.pick(
                hans: "使用启动参数 \(joined) 启动",
                hant: "使用啟動參數 \(joined) 啟動",
                en: "Start it with \(joined)")))
        }
        if let recipe, recipe.isOptIn {
            items.append(WillDo(text: applied
                ? HighballLang.pick(
                    hans: "保留你在“高级”中应用的 \(recipe.title) 修复方案",
                    hant: "保留你在「進階」中套用的 \(recipe.title) 修復方案",
                    en: "Keep the \(recipe.title) fix you applied under Advanced")
                : HighballLang.pick(
                    hans: "暂不启用可选的 \(recipe.title) 修复方案；若说明中提到你的 Mac 需要它，可在“高级”中开启",
                    hant: "暫不啟用可選的 \(recipe.title) 修復方案；若說明中提到你的 Mac 需要它，可在「進階」中開啟",
                    en: "Leave the optional \(recipe.title) fix alone; it is under Advanced for when the notes say your Mac needs it"),
                done: applied))
        } else if let recipe {
            for step in recipe.steps {
                guard let text = describe(step) else { continue }
                items.append(WillDo(text: text, cost: applied ? nil : step.slowHint, done: applied))
            }
        }
        return items
    }

    public static func rowRendererHeldBack(_ entry: GameDBEntry?, bottleRenderer: Renderer, explicit: Bool, gameOverride: Renderer?,
                                           needsDirect3D12: Bool = false,
                                           osMajor: Int = ProcessInfo.processInfo.operatingSystemVersion.majorVersion) -> Renderer? {
        guard explicit, gameOverride == nil, entry?.nativeVulkan != true,
              let wanted = entry?.effectiveRenderer(osMajor: osMajor), wanted != bottleRenderer else { return nil }
        if needsDirect3D12, !bottleRenderer.servesDirect3D12, wanted.servesDirect3D12 { return nil }
        return wanted
    }

    public static func fpsPhrase(_ fps: String) -> String? {
        var t = fps.trimmingCharacters(in: .whitespacesAndNewlines)
        if let stop = t.range(of: ". ") { t = String(t[..<stop.lowerBound]) }
        if t.hasSuffix(".") { t.removeLast() }
        guard !t.isEmpty else { return nil }
        let figure = "^(?i:about )?[0-9]+(?:\\.[0-9]+)?(?:\\s*(?:-|–|to)\\s*[0-9]+(?:\\.[0-9]+)?)?"
        guard let r = t.range(of: figure, options: .regularExpression) else { return t }
        let rest = String(t[r.upperBound...])
        if rest.lowercased().hasPrefix(" fps") { return t }
        let numStr = String(t[r]).replacingOccurrences(of: "about ", with: HighballLang.pick(hans: "约 ", hant: "約 ", en: "about "), options: .caseInsensitive)
        let unit = HighballLang.pick(hans: " 帧/秒 (FPS)", hant: " 幀/秒 (FPS)", en: " frames per second")
        return numStr + unit + rest
    }

    // MARK: helpers

    public static func plainName(_ r: Renderer) -> String {
        switch r {
        case .dxmt:
            return HighballLang.pick(hans: "DXMT（基于 Metal 的 DirectX 11）", hant: "DXMT（基於 Metal 的 DirectX 11）", en: "DXMT (DirectX 11 on Metal)")
        case .d3dmetal:
            return HighballLang.pick(hans: "Apple 官方 DirectX 12 支持 (D3DMetal)", hant: "Apple 官方 DirectX 12 支援 (D3DMetal)", en: "Apple's DirectX 12 support")
        case .dxvk:
            return HighballLang.pick(hans: "DXVK（基于 Metal 的 Vulkan）", hant: "DXVK（基於 Metal 的 Vulkan）", en: "DXVK (Vulkan on Metal)")
        case .wined3d:
            return HighballLang.pick(hans: "Wine 自带 Direct3D", hant: "Wine 內建 Direct3D", en: "Wine's own Direct3D")
        case .vkd3d:
            return HighballLang.pick(hans: "vkd3d-proton（通过 Vulkan 运行 DirectX 12）", hant: "vkd3d-proton（透過 Vulkan 執行 DirectX 12）", en: "vkd3d-proton (DirectX 12 through Vulkan)")
        }
    }

    public static func shortChip(_ chip: String) -> String {
        let t = chip.trimmingCharacters(in: .whitespaces)
        return t.hasPrefix("Apple ") ? String(t.dropFirst(6)) : t
    }

    static func freshness(_ ymd: String?, today: Date) -> String? {
        guard let ymd else { return nil }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = TimeZone(identifier: "UTC")
        guard let d = f.date(from: ymd) else { return nil }
        let days = Int(today.timeIntervalSince(d) / 86_400)
        switch days {
        case ..<1:
            return HighballLang.pick(hans: "今天", hant: "今天", en: "today")
        case 1:
            return HighballLang.pick(hans: "昨天", hant: "昨天", en: "yesterday")
        case 2...60:
            return HighballLang.pick(hans: " \(days) 天前", hant: " \(days) 天前", en: "\(days) days ago")
        default:
            return HighballLang.pick(hans: " \(ymd)", hant: " \(ymd)", en: "on \(ymd)")
        }
    }

    static func sentenceCase(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.uppercased() + s.dropFirst()
    }

    static func describe(_ step: Recipe.Step) -> String? {
        switch step {
        case let .installer(_, _, _, label, _, _):
            return HighballLang.pick(hans: "安装 \(label)", hant: "安裝 \(label)", en: "Install \(label)")
        case let .winetricks(verbs, _):
            let list = verbs.joined(separator: ", ")
            return HighballLang.pick(hans: "安装 \(list)", hant: "安裝 \(list)", en: "Install \(list)")
        case let .registry(_, name, _, _):
            return HighballLang.pick(hans: "设置 Windows 注册表项 \(name)", hant: "設定 Windows 登錄檔項目 \(name)", en: "Set the Windows registry value \(name)")
        case let .environment(name, _):
            return HighballLang.pick(hans: "为此游戏设置环境变量 \(name)", hant: "為此遊戲設定環境變數 \(name)", en: "Set \(name) for this game")
        case let .renderer(r):
            return HighballLang.pick(hans: "将环境的图形模式切换为 \(plainName(r))", hant: "將環境的圖形模式切換為 \(plainName(r))", en: "Switch the environment's graphics mode to \(plainName(r))")
        case let .sync(m):
            return HighballLang.pick(hans: "将环境的同步方式设置为 \(m.rawValue)", hant: "將環境的同步方式設定為 \(m.rawValue)", en: "Set the environment's sync mode to \(m.rawValue)")
        case let .winver(v):
            return HighballLang.pick(hans: "向游戏报告系统为 Windows \(v.rawValue)", hant: "向遊戲回報系統為 Windows \(v.rawValue)", en: "Report Windows \(v.rawValue) to the game")
        case let .file(path, _):
            let fn = URL(fileURLWithPath: path).lastPathComponent
            return HighballLang.pick(hans: "写入配置文件 \(fn)", hant: "寫入設定檔 \(fn)", en: "Write \(fn)")
        case let .copy(from, _, _):
            let fn = URL(fileURLWithPath: from).lastPathComponent
            return HighballLang.pick(hans: "从引擎复制专属的 \(fn) 给游戏使用", hant: "從引擎複製專屬的 \(fn) 給遊戲使用", en: "Give the game its own \(fn) from the engine")
        case .pin: return nil
        case let .note(text): return text
        case let .dllOverride(v):
            return HighballLang.pick(hans: "设置 Windows 动态库覆盖项 \(v)", hant: "設定 Windows 動態庫覆蓋項目 \(v)", en: "Set the Windows library override \(v)")
        case let .dxvkConfig(exe, _):
            return HighballLang.pick(hans: "为 \(exe) 配置 DXVK", hant: "為 \(exe) 設定 DXVK", en: "Configure DXVK for \(exe)")
        }
    }
}

extension GamePageCopy {
    public static func d3dMetalAsk(title: String, entry: GameDBEntry?) -> String {
        guard entry?.effectiveRenderer() == .d3dmetal else {
            return HighballLang.pick(
                hans: "\(title) 所在的环境被设置为使用 D3DMetal，这需要同意 Apple 的引擎许可协议。开启即代表同意该协议（允许非商业用途）；不会额外下载任何内容，也不会向 Apple 发送任何数据。使用 Highball 默认的 DXMT 即可流畅运行大多数游戏。",
                hant: "\(title) 所在的環境被設定為使用 D3DMetal，這需要同意 Apple 的引擎許可協議。開啟即代表同意該協議（允許非商業用途）；不會額外下載任何內容，也不會向 Apple 傳送任何資料。使用 Highball 預設的 DXMT 即可流暢執行大多數遊戲。",
                en: "The environment \(title) runs in is set to D3DMetal, which needs Apple's licence accepted for its engine. Turning it on means accepting that licence, which allows non-commercial use; nothing downloads and nothing is sent to Apple. Playing with DXMT, Highball's default, works for most games.")
        }
        let consequence = otherWorkingRenderer(entry).map {
            HighballLang.pick(
                hans: "如果不开启，\(title) 仍可使用记录为可运行的 \(plainName($0)) 启动，但运行速度会较慢。",
                hant: "如果不開啟，\(title) 仍可使用記錄為可執行的 \(plainName($0)) 啟動，但執行速度會較慢。",
                en: "Without it, \(title) still runs on \(plainName($0)), which was recorded as working, but slower.")
        } ?? HighballLang.pick(
            hans: "兼容性数据库中没有记录其他可运行 \(title) 的图形模式，因此如果不开启此项，Highball 将没有其他可用备选方案。",
            hant: "相容性資料庫中沒有記錄其他可執行 \(title) 的圖形模式，因此如果不開啟此項，Highball 將沒有其他可用備選方案。",
            en: "The database records no other graphics mode as working for \(title), so without it Highball has nothing else to try.")
        return HighballLang.pick(
            hans: "Highball 已内置该组件。开启即表示同意允许非商业用途的 Apple 许可协议。\(consequence) 无需额外下载，也不会向 Apple 发送任何信息。",
            hant: "Highball 已內建該組件。開啟即表示同意允許非商業用途的 Apple 許可協議。\(consequence) 無需額外下載，也不會向 Apple 傳送任何資訊。",
            en: "Highball already includes it. Turning it on means accepting Apple's licence, which allows non-commercial use. \(consequence) Nothing to download and nothing sent to Apple.")
    }

    public static func otherWorkingRenderer(_ entry: GameDBEntry?) -> Renderer? {
        guard let results = entry?.rendererResults else { return nil }
        for key in ["dxmt", "vkd3d", "dxvk", "wined3d"] where results[key]?.verdict == "works" {
            if let r = Renderer(rawValue: key) { return r }
        }
        return nil
    }
}
