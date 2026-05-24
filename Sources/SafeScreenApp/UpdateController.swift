import AppKit
import Foundation

@MainActor
final class UpdateController {
    private enum State {
        case idle
        case checking
        case downloading
    }

    private struct GitHubRelease: Decodable {
        let tagName: String
        let assets: [GitHubReleaseAsset]

        var dmgAsset: GitHubReleaseAsset? {
            assets.first { asset in
                asset.name.lowercased().hasSuffix(".dmg")
            } ?? assets.first { asset in
                asset.browserDownloadURL.pathExtension.lowercased() == "dmg"
            }
        }

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case assets
        }
    }

    private struct GitHubReleaseAsset: Decodable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    private struct ReleaseVersion: Comparable, CustomStringConvertible {
        let major: Int
        let minor: Int
        let patch: Int

        var description: String {
            "\(major).\(minor).\(patch)"
        }

        init?(_ value: String) {
            var normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalized.first == "v" || normalized.first == "V" {
                normalized.removeFirst()
            }

            let withoutMetadata = normalized
                .split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false)
                .first
                .map(String.init) ?? ""
            let versionCore = withoutMetadata
                .split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
                .first
                .map(String.init) ?? ""
            let parts = versionCore.split(separator: ".", omittingEmptySubsequences: false)

            guard parts.count == 3,
                  let major = Int(parts[0]),
                  let minor = Int(parts[1]),
                  let patch = Int(parts[2]),
                  major >= 0,
                  minor >= 0,
                  patch >= 0
            else {
                return nil
            }

            self.major = major
            self.minor = minor
            self.patch = patch
        }

        static func < (lhs: ReleaseVersion, rhs: ReleaseVersion) -> Bool {
            if lhs.major != rhs.major {
                return lhs.major < rhs.major
            }
            if lhs.minor != rhs.minor {
                return lhs.minor < rhs.minor
            }
            return lhs.patch < rhs.patch
        }
    }

    private enum UpdateError: LocalizedError {
        case invalidGitHubResponse
        case githubStatus(Int)
        case invalidReleaseVersion(String)
        case missingDMGAsset(String)
        case downloadStatus(Int)

        var errorDescription: String? {
            switch self {
            case .invalidGitHubResponse:
                "GitHub вернул неожиданный ответ."
            case let .githubStatus(statusCode):
                "GitHub вернул HTTP \(statusCode)."
            case let .invalidReleaseVersion(tag):
                "Не удалось разобрать версию релиза: \(tag)."
            case let .missingDMGAsset(version):
                "В релизе \(version) не найден DMG-файл."
            case let .downloadStatus(statusCode):
                "Не удалось скачать DMG: HTTP \(statusCode)."
            }
        }
    }

    var onStateChanged: (() -> Void)?

    var menuItemTitle: String {
        switch state {
        case .idle:
            "Проверка наличия обновлений"
        case .checking:
            "Проверка обновлений..."
        case .downloading:
            "Загрузка обновления..."
        }
    }

    var isBusy: Bool {
        state != .idle
    }

    private let session: URLSession
    private let fileManager: FileManager
    private let downloadsDirectory: URL
    private var state: State = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChanged?()
        }
    }

    init(
        session: URLSession = .shared,
        fileManager: FileManager = .default,
        downloadsDirectory: URL? = nil
    ) {
        self.session = session
        self.fileManager = fileManager
        self.downloadsDirectory = downloadsDirectory
            ?? fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true)
    }

    func checkForUpdates() {
        guard !isBusy else { return }

        state = .checking
        Task { @MainActor [weak self] in
            await self?.checkAndMaybeDownload()
        }
    }

    private func checkAndMaybeDownload() async {
        do {
            let release = try await fetchLatestRelease()
            let currentVersion = ReleaseVersion(currentVersionString) ?? ReleaseVersion("0.0.0")!

            guard let latestVersion = ReleaseVersion(release.tagName) else {
                throw UpdateError.invalidReleaseVersion(release.tagName)
            }

            guard latestVersion > currentVersion else {
                state = .idle
                presentNoUpdateAlert(currentVersion: currentVersion)
                return
            }

            guard let asset = release.dmgAsset else {
                throw UpdateError.missingDMGAsset(latestVersion.description)
            }

            state = .downloading
            let destinationURL = try await download(asset: asset)
            state = .idle
            presentDownloadCompleteAlert(destinationURL: destinationURL, latestVersion: latestVersion)
        } catch {
            state = .idle
            presentUpdateErrorAlert(error)
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        let url = URL(string: "https://api.github.com/repos/LexorCrypto/safe_screen/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidGitHubResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UpdateError.githubStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private func download(asset: GitHubReleaseAsset) async throws -> URL {
        var request = URLRequest(url: asset.browserDownloadURL)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (temporaryURL, response) = try await session.download(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidGitHubResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UpdateError.downloadStatus(httpResponse.statusCode)
        }

        try fileManager.createDirectory(
            at: downloadsDirectory,
            withIntermediateDirectories: true
        )

        let destinationURL = uniqueDestinationURL(fileName: asset.name)
        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }

    private var currentVersionString: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
           !trimmedValue.isEmpty {
            return trimmedValue
        }
        return "0.0.0"
    }

    private var userAgent: String {
        "SafeScreen/\(currentVersionString)"
    }

    private func uniqueDestinationURL(fileName: String) -> URL {
        let safeFileName = fileName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let baseName = safeFileName.isEmpty ? "Safe-Screen-update.dmg" : safeFileName
        let originalURL = downloadsDirectory.appendingPathComponent(baseName, isDirectory: false)

        guard fileManager.fileExists(atPath: originalURL.path) else {
            return originalURL
        }

        let name = (baseName as NSString).deletingPathExtension
        let pathExtension = (baseName as NSString).pathExtension

        for index in 2...99 {
            let candidateName = pathExtension.isEmpty
                ? "\(name) \(index)"
                : "\(name) \(index).\(pathExtension)"
            let candidateURL = downloadsDirectory.appendingPathComponent(candidateName, isDirectory: false)
            if !fileManager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
        }

        return downloadsDirectory.appendingPathComponent(
            "\(UUID().uuidString)-\(baseName)",
            isDirectory: false
        )
    }

    private func presentNoUpdateAlert(currentVersion: ReleaseVersion) {
        let alert = NSAlert()
        alert.messageText = "Обновлений нет"
        alert.informativeText = "Установлена актуальная версия Safe Screen \(currentVersion)."
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func presentDownloadCompleteAlert(destinationURL: URL, latestVersion: ReleaseVersion) {
        let alert = NSAlert()
        alert.messageText = "Обновление Safe Screen \(latestVersion) скачано"
        alert.informativeText = "Файл сохранен в Downloads:\n\(destinationURL.lastPathComponent)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Открыть DMG")
        alert.addButton(withTitle: "Показать в Finder")
        alert.addButton(withTitle: "OK")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            NSWorkspace.shared.open(destinationURL)
        case .alertSecondButtonReturn:
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
        default:
            break
        }
    }

    private func presentUpdateErrorAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Не удалось проверить обновления"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

}
