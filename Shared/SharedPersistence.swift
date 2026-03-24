import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private static let appGroupID = "group.com.example.ShareSaver"

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ShareSaver")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID)?
            .appendingPathComponent("ShareSaver.sqlite") {
            container.persistentStoreDescriptions.first!.url = storeURL
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
