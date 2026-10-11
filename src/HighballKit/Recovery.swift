import Foundation

/// What a failure looks like on the primary surface: one sentence about what happened, one
/// about what it means, and at most one button that does the next thing (UX plan §3.6). Raw
/// output and exit codes never appear here; they stay behind a details view. A cause is named
/// only when the app actually detected it: a 60-second timeout is not "your connection dropped".
public struct Recovery: Equatable, Sendable {
    public enum Action: Equatable, Sendable {
        /// Run the same operation again (installs, downloads, recipe steps).
        case retry
        /// Re-run the bottle's Windows setup.
        case repairBottle
        /// Download and unpack this engine again over the damaged copy.
        case reinstallEngine(String)
        /// Nothing automatic; the details and a report are the next step.
        case none
    }
    public var headline: String
    public var meaning: String
    public var actionTitle: String?
    public var action: Action

    public init(headline: String, meaning: String, actionTitle: String? = nil, action: Action = .none) {
        self.headline = headline; self.meaning = meaning; self.actionTitle = actionTitle; self.action = action
    }

    /// The mapping from what actually failed to what the user sees. Unknown failures keep their
    /// own message as the headline so nothing is hidden, and get no button.
    public static func describe(_ error: Error) -> Recovery {
        if let url = error as? URLError {
            switch url.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return Recovery(headline: "The download could not reach the server.",
                                meaning: "Highball keeps what it already received and continues from there.",
                                actionTitle: "Try again", action: .retry)
            case .timedOut:
                return Recovery(headline: "The download stopped waiting for data.",
                                meaning: "Highball keeps what it already received and continues from there.",
                                actionTitle: "Try again", action: .retry)
            default:
                return Recovery(headline: "The download stopped.",
                                meaning: "Highball keeps what it already received and continues from there.",
                                actionTitle: "Try again", action: .retry)
            }
        }
        guard let known = error as? HighballError else {
            return Recovery(headline: (error as NSError).localizedDescription, meaning: "")
        }
        switch known {
        case let .engineDamaged(engine, files):
            let list = EngineIntegrity.list(files)
            return Recovery(
                headline: "Files are missing from Highball's engine.",
                meaning: HighballLang.pick(
                    hans: "引擎 \(engine) 安装后丢失了 \(list)，导致无法在其中启动任何 Windows 程序。这通常是因为杀毒软件或安全工具隔离了 Highball 的文件夹：请先将 ~/Library/Application Support/Highball 添加到杀毒软件的排除列表中，然后重新安装引擎。",
                    hant: "引擎 \(engine) 安裝後遺失了 \(list)，導致無法在其中啟動任何 Windows 程式。這通常是因為防毒軟體或安全工具隔離了 Highball 的資料夾：請先將 ~/Library/Application Support/Highball 加入防毒軟體的排除清單中，然後重新安裝引擎。",
                    en: "\(list) left engine \(engine) after it was installed, so no Windows program can start in it. Antivirus software quarantining Highball's folder is what this looks like from the inside: add ~/Library/Application Support/Highball to its exclusions first, then install the engine again."),
                actionTitle: "Install the engine again", action: .reinstallEngine(engine))
        case .checksumMismatch:
            return Recovery(headline: "The download didn't arrive intact.",
                            meaning: "This is usually a network problem. Highball discards the damaged file and downloads it again.",
                            actionTitle: "Download again", action: .retry)
        case let .processFailed(_, _, output) where Self.xcodeLicenceUnaccepted(output):
            return Recovery(headline: "Xcode's licence has not been accepted on this Mac.",
                            meaning: "Until it is, the developer tools this step needs refuse to run, so it stops partway and says something unrelated. Open Terminal, run sudo xcodebuild -license, read it through and accept it, then try again here.",
                            actionTitle: "Try again", action: .retry)
        case let .processFailed(command, _, _) where command.hasPrefix("wineboot"):
            return Recovery(headline: "The Windows environment didn't finish setting up.",
                            meaning: "Highball can run the setup again.",
                            actionTitle: "Repair", action: .repairBottle)
        case let .processFailed(command, _, output) where command.contains("winetricks"):
            let words = command.split(separator: " ").map(String.init)
            let verbs = words.drop(while: { $0 != "--unattended" }).dropFirst().joined(separator: " ")
            let what = verbs.isEmpty
                ? HighballLang.pick(hans: "winetricks 步骤", hant: "winetricks 步驟", en: "The winetricks step")
                : HighballLang.pick(hans: "使用 winetricks 安装 \(verbs)", hant: "使用 winetricks 安裝 \(verbs)", en: "Installing \(verbs) with winetricks")
            var meaning = HighballLang.pick(
                hans: "该步骤在运行时需要从互联网下载文件，而相关服务器偶尔会拒绝连接，因此等几分钟后重试通常就能成功。完整输出保存在 Highball 日志文件夹中最新带有 winetricks 字样的文件里。",
                hant: "該步驟在執行時需要從網際網路下載檔案，而相關伺服器偶爾會拒絕連線，因此等幾分鐘後重試通常就能成功。完整輸出保存在 Highball 日誌資料夾中最新帶有 winetricks 字樣的檔案裡。",
                en: "It downloads its files from the internet as it runs, and those servers refuse now and then, so trying again in a few minutes often works. The full output is in Highball's logs folder, in the newest file with winetricks in its name.")
            if let reason = Self.winetricksReason(output) {
                meaning += HighballLang.pick(hans: " 错误信息：\(reason)", hant: " 錯誤資訊：\(reason)", en: " It said: \(reason)")
            }
            return Recovery(
                headline: HighballLang.pick(hans: "\(what)未完成。", hant: "\(what)未完成。", en: "\(what) didn't finish."),
                meaning: meaning,
                actionTitle: "Try again", action: .retry)
        case let .processFailed(command, _, _):
            let name = command.split(separator: " ").first.map(String.init) ?? HighballLang.pick(hans: "安装程序", hant: "安裝程式", en: "The installer")
            return Recovery(
                headline: HighballLang.pick(hans: "\(name) 未完成。", hant: "\(name) 未完成。", en: "\(name) didn't finish."),
                meaning: "Highball can try again with a fresh copy.",
                actionTitle: "Try again", action: .retry)
        case let .invalid(what) where what.contains("32-bit"):
            return Recovery(headline: "The Windows environment didn't finish setting up.",
                            meaning: "Its 32-bit half is missing, which most installers need. Highball can repair it.",
                            actionTitle: "Repair", action: .repairBottle)
        case let .missing(what):
            return Recovery(headline: "Something Highball needs is missing.", meaning: what)
        case let .invalid(what), let .failed(what):
            return Recovery(headline: what, meaning: "")
        }
    }
}


extension Recovery {
    /// macOS refuses every Xcode-provided command line tool until the licence has been accepted,
    /// and prints this one sentence when it does. It can land anywhere in a step's output rather
    /// than at the end, so it is matched across the whole of it: in highball#180 it appeared four
    /// times in the middle of a corefonts run whose last real line was about `%AppData%`.
    static func xcodeLicenceUnaccepted(_ output: String) -> Bool {
        output.contains("You have not agreed to the Xcode license agreements")
    }

    /// The last line of a winetricks run that says something, skipping its progress noise and
    /// the shell's own "exited with" footer. Nil when the output is empty.
    static func winetricksReason(_ output: String) -> String? {
        let noise = ["warning: taskset", "Executing", "------", "[mvk-", "fixme:", "exited with"]
        let lines = output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        return lines.last { line in
            !line.isEmpty && !noise.contains { line.hasPrefix($0) || line.contains($0) }
        }.map { String($0.prefix(200)) }
    }
}
