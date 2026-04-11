import Observation
import SwiftUI

struct DoomStatusView: View {
    let viewModel: PopoverViewModel
    @State private var successCardVisible = false

    private let pinkAccent = Color(red: 0.86, green: 0.29, blue: 0.55)
    private let pinkTitle = Color(red: 0.75, green: 0.16, blue: 0.39)
    private let pinkBody = Color(red: 0.35, green: 0.23, blue: 0.30)
    private let pinkBackgroundTop = Color(red: 1.0, green: 0.96, blue: 0.98)
    private let pinkBackgroundBottom = Color(red: 0.98, green: 0.88, blue: 0.92)
    private let pinkBorder = Color(red: 0.95, green: 0.66, blue: 0.78)

    private var showsSuccessArtwork: Bool {
        guard case .success = viewModel.doomsStatus else { return false }
        return viewModel.latestGeneratedFileURL != nil
    }

    private var isSuccessState: Bool {
        if case .success = viewModel.doomsStatus {
            return true
        }
        return false
    }

    private var isGeneratingState: Bool {
        if case .generating = viewModel.doomsStatus {
            return true
        }
        return false
    }

    var body: some View {
        Group {
            switch viewModel.doomsStatus {
            case .idle:
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.orange)
                        Text("Doom")
                            .font(.headline)
                    }
                    Text("Click to generate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .generating:
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.55))
                        Image("MenuBarIcon")
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                                .tint(pinkAccent)
                            Text("Generating...")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(pinkTitle)
                        }
                        Text("Gathering context and building your moment")
                            .font(.caption)
                            .foregroundStyle(pinkBody)
                            .lineLimit(3)
                    }
                    .padding(.leading, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            case .success(let message):
                if showsSuccessArtwork {
                    HStack(alignment: .center, spacing: 14) {
                        AnimatedGIFView(resourceName: "kawaii_bomb_bounce")
                            .frame(width: 80, height: 80)
                            .scaleEffect(successCardVisible ? 1.0 : 0.92)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(pinkAccent)
                                Text("Generated!")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(pinkTitle)
                            }

                            Text(message)
                                .font(.caption)
                                .foregroundStyle(pinkBody)
                                .lineLimit(3)
                                .textSelection(.enabled)
                        }
                        .padding(.leading, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scaleEffect(successCardVisible ? 1.0 : 0.96)
                    .opacity(successCardVisible ? 1.0 : 0.0)
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(pinkAccent)
                            Text("Generated!")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(pinkTitle)
                        }
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(pinkBody)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                }

            case .error(let message):
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Failed")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .frame(width: showsSuccessArtwork ? 324 : (isGeneratingState ? 268 : 260))
        .background(
            Group {
                if isSuccessState || isGeneratingState {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [pinkBackgroundTop, pinkBackgroundBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        )
        .overlay(
            Group {
                if isSuccessState || isGeneratingState {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(pinkBorder, lineWidth: 1)
                }
            }
        )
        .shadow(color: (isSuccessState || isGeneratingState) ? Color.black.opacity(0.08) : .clear, radius: 14, x: 0, y: 8)
        .animation(.spring(response: 0.36, dampingFraction: 0.8), value: successCardVisible)
        .onAppear {
            successCardVisible = showsSuccessArtwork
        }
        .onChange(of: showsSuccessArtwork) { _, newValue in
            if newValue {
                successCardVisible = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.76)) {
                    successCardVisible = true
                }
            } else {
                successCardVisible = false
            }
        }
    }
}
