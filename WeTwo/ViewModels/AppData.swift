import Foundation

@MainActor
final class AppData: ObservableObject {
    @Published var me: Profile?
    @Published var myMemoriesList: [Memory] = []
    @Published var myPartnerships: [Partnership] = []
    @Published var chat: [LoveMessage] = []

    func loadMe() async {
        do { me = try await SupabaseService.shared.myProfile() }
        catch { print("loadMe error:", error) }
    }

    func saveMe(_ p: Profile) async {
        do { me = try await SupabaseService.shared.upsertProfile(p) }
        catch { print("saveMe error:", error) }
    }

    func loadMemories() async {
        do { myMemoriesList = try await SupabaseService.shared.myMemories() }
        catch { print("memories error:", error) }
    }

    func addMemory(_ m: Memory) async {
        do {
            let _ = try await SupabaseService.shared.addMemory(m)
            await loadMemories()
        } catch { print("addMemory error:", error) }
    }

    func loadPartnerships() async {
        guard let userId = SupabaseService.shared.currentUserId else { return }
        do { myPartnerships = try await SupabaseService.shared.partnershipsMine(userId: userId) }
        catch { print("partner error:", error) }
    }

    func openChat(with partner: UUID) async {
        do { chat = try await SupabaseService.shared.conversation(with: partner) }
        catch { print("chat error:", error) }
    }

    func sendMessage(to partner: UUID, text: String) async {
        do {
            let _ = try await SupabaseService.shared.sendLoveMessage(to: partner, text: text)
            await openChat(with: partner)
        } catch { print("send message error:", error) }
    }
}
