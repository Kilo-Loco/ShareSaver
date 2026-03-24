import UIKit
import UniformTypeIdentifiers
import CoreData

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        handleSharedItems()
    }

    private func handleSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        Task {
            for item in extensionItems {
                guard let attachments = item.attachments else { continue }
                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        if let text = try? await provider.loadItem(
                            forTypeIdentifier: UTType.plainText.identifier
                        ) as? String {
                            saveItem(text: text)
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        if let url = try? await provider.loadItem(
                            forTypeIdentifier: UTType.url.identifier
                        ) as? URL {
                            saveItem(text: url.absoluteString)
                        }
                    }
                }
            }
            close()
        }
    }

    private func saveItem(text: String) {
        let context = PersistenceController.shared.container.newBackgroundContext()
        context.performAndWait {
            let item = SavedItem(context: context)
            item.id = UUID()
            item.text = text
            item.createdAt = Date()
            try? context.save()
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
