import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class PropertiesViewModel {
    enum ConnectivityStatus: Equatable {
        case idle
        case testing
        case success(String)
        case error(String)

        var message: String {
            switch self {
            case .idle:
                return "Configure the export folder and Ollama connection."
            case .testing:
                return "Testing Ollama connectivity..."
            case .success(let message), .error(let message):
                return message
            }
        }
    }

    var connectivityStatus: ConnectivityStatus = .idle
    var piecesStatus: String = ""
    var availableOllamaModels: [String] = []
    var ollamaModelsStatus: String = ""

    let settings: AppSettings
    private let ollamaService: OllamaService

    init(
        settings: AppSettings,
        ollamaService: OllamaService = OllamaService()
    ) {
        self.settings = settings
        self.ollamaService = ollamaService
    }

    var statusColor: Color {
        switch connectivityStatus {
        case .idle:
            return .secondary
        case .testing:
            return .primary
        case .success:
            return .green
        case .error:
            return .red
        }
    }

    var isTesting: Bool {
        if case .testing = connectivityStatus {
            return true
        }

        return false
    }

    var displayedOllamaModels: [String] {
        let trimmedSelectedModel = settings.ollamaModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSelectedModel.isEmpty == false else {
            return availableOllamaModels
        }

        if availableOllamaModels.contains(trimmedSelectedModel) {
            return availableOllamaModels
        }

        return [trimmedSelectedModel] + availableOllamaModels
    }

    func chooseExportDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.prompt = "Choose"
        openPanel.directoryURL = settings.exportDirectoryURL

        if openPanel.runModal() == .OK, let url = openPanel.url {
            settings.exportDirectoryPath = url.path
        }
    }

    func refreshAvailableModels() {
        ollamaModelsStatus = "Loading models..."

        Task {
            let result = await ollamaService.fetchAvailableModels(
                baseURLString: settings.ollamaBaseURLString
            )

            switch result {
            case .success(let models):
                availableOllamaModels = models
                if models.isEmpty {
                    ollamaModelsStatus = "No models found on this Ollama instance."
                } else {
                    ollamaModelsStatus = "Loaded \(models.count) model\(models.count == 1 ? "" : "s")."
                    let trimmedSelectedModel = settings.ollamaModel.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedSelectedModel.isEmpty {
                        settings.ollamaModel = models[0]
                    }
                }
            case .failure(let error):
                availableOllamaModels = []
                ollamaModelsStatus = error.localizedDescription
            }
        }
    }

    func testConnectivity() {
        guard isTesting == false else { return }

        connectivityStatus = .testing

        Task {
            let result = await ollamaService.testConnection(
                baseURLString: settings.ollamaBaseURLString,
                model: settings.ollamaModel
            )

            switch result {
            case .success(let message):
                connectivityStatus = .success(message)
            case .failure(let error):
                connectivityStatus = .error(error.localizedDescription)
            }
        }
    }

    func testPiecesConnection() {
        piecesStatus = "Checking..."

        Task {
            let piecesService = PiecesOSService(baseURLString: settings.piecesBaseURLString)
            let available = await piecesService.isAvailable()
            if available {
                let events = await piecesService.fetchRecentWorkstreamEvents(limit: 1)
                piecesStatus = "Connected. \(events.isEmpty ? "No LTM events yet." : "LTM active.")"
            } else {
                piecesStatus = "Pieces OS not reachable at \(settings.piecesBaseURLString)."
            }
        }
    }
}

struct PropertiesView: View {
    let viewModel: PropertiesViewModel

    var body: some View {
        @Bindable var settings = viewModel.settings

        VStack(alignment: .leading, spacing: 18) {
            Text("Properties")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Generation Mode")
                    .font(.headline)

                Picker("Mode", selection: $settings.generationMode) {
                    ForEach(GenerationMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(settings.generationMode.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Export")
                    .font(.headline)

                Picker("Export", selection: $settings.exportPreset) {
                    ForEach(ExportPreset.allCases, id: \.self) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                Text(settings.exportPreset.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Export Folder")
                    .font(.headline)

                HStack(spacing: 10) {
                    TextField("Export folder path", text: $settings.exportDirectoryPath)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse", action: viewModel.chooseExportDirectory)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ollama")
                    .font(.headline)

                TextField("Base URL", text: $settings.ollamaBaseURLString)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: settings.ollamaBaseURLString) { _, _ in
                        viewModel.refreshAvailableModels()
                    }

                HStack(spacing: 10) {
                    Picker("Model", selection: $settings.ollamaModel) {
                        if viewModel.displayedOllamaModels.isEmpty {
                            Text("No models available").tag("")
                        } else {
                            ForEach(viewModel.displayedOllamaModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Refresh Models", action: viewModel.refreshAvailableModels)

                    Button(viewModel.isTesting ? "Testing..." : "Test Connectivity", action: viewModel.testConnectivity)
                        .disabled(viewModel.isTesting)
                }

                if viewModel.ollamaModelsStatus.isEmpty == false {
                    Text(viewModel.ollamaModelsStatus)
                        .font(.footnote)
                        .foregroundStyle(viewModel.availableOllamaModels.isEmpty ? Color.secondary : Color.green)
                }

                Text("The configured model is used to generate an AI resume summary for each snapshot.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(viewModel.connectivityStatus.message)
                    .font(.footnote)
                    .foregroundStyle(viewModel.statusColor)
                    .lineLimit(3, reservesSpace: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Pieces OS")
                    .font(.headline)

                TextField("Pieces base URL", text: $settings.piecesBaseURLString)
                    .textFieldStyle(.roundedBorder)

                Toggle("Use Pieces for Doom's Moment generation", isOn: $settings.usePiecesForGeneration)

                Text("When enabled, Doom's Moment pulls LTM from Pieces OS and uses its AI for generation. Falls back to Ollama if unavailable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("Test Pieces Connection", action: viewModel.testPiecesConnection)

                    if viewModel.piecesStatus.isEmpty == false {
                        Text(viewModel.piecesStatus)
                            .font(.footnote)
                            .foregroundStyle(viewModel.piecesStatus.contains("Connected") ? .green : .red)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Search Tags")
                    .font(.headline)

                TextField("Comma-separated tags for generated files and notes", text: $settings.userTagsString)
                    .textFieldStyle(.roundedBorder)

                Text("These tags are added to the generated Hashtags section so your Doom's Moments are easier to find later.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 460)
        .task {
            viewModel.refreshAvailableModels()
        }
    }
}

#Preview {
    PropertiesView(viewModel: PropertiesViewModel(settings: AppSettings()))
}
