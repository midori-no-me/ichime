import Anime365Kit
import IchimeProfile
import SwiftUI

@Observable @MainActor
private final class StreamingChannelSettingPickerViewModel {
  static let placeholderChannelID = "__loading"

  private(set) var playerChannel: PlayerChannel?
  private(set) var playerChannels: [PlayerChannel] = []
  private(set) var isLoading: Bool = false

  private let profilePageService: ProfilePageService

  var selection: String {
    self.playerChannel?.id ?? Self.placeholderChannelID
  }

  var hasLoadedChannels: Bool {
    !self.playerChannels.isEmpty
  }

  init(
    profilePageService: ProfilePageService = AppDependencies.live.profilePageService
  ) {
    self.profilePageService = profilePageService
  }

  func load() async -> Void {
    guard !self.isLoading, !self.hasLoadedChannels else {
      return
    }

    self.isLoading = true

    defer {
      self.isLoading = false
    }

    do {
      let settings = try await self.profilePageService.getProfilePlayerChannelSettings()

      self.playerChannel = settings.playerChannel
      self.playerChannels = settings.playerChannels
    }
    catch {}
  }

  func selectChannel(id: String) async -> Void {
    guard
      id != Self.placeholderChannelID,
      let playerChannel = self.playerChannels.first(where: { $0.id == id })
    else {
      return
    }

    self.isLoading = true

    defer {
      self.isLoading = false
    }

    do {
      try await self.profilePageService.updateProfilePlayerChannel(playerChannel)

      self.playerChannel = playerChannel
    }
    catch {}
  }
}

struct StreamingChannelSettingPicker: View {
  @State private var viewModel: StreamingChannelSettingPickerViewModel = .init()

  var body: some View {
    Picker(
      "Используемый канал",
      selection: Binding(
        get: {
          self.viewModel.selection
        },
        set: { channelID in
          Task {
            await self.viewModel.selectChannel(id: channelID)
          }
        }
      )
    ) {
      if !self.viewModel.hasLoadedChannels {
        Text("Загрузка...")
          .tag(StreamingChannelSettingPickerViewModel.placeholderChannelID)
      }

      ForEach(self.viewModel.playerChannels) { playerChannel in
        Text(playerChannel.name)
          .tag(playerChannel.id)
      }
    }
    .pickerStyle(.navigationLink)
    .disabled(!self.viewModel.hasLoadedChannels || self.viewModel.isLoading)
    .task {
      await self.viewModel.load()
    }
  }
}
