import SwiftUI
import CoreData
import Combine

// MARK: - The Broken Approach (SwiftUI @FetchRequest)
//
// This version uses @FetchRequest, which does NOT pick up
// new objects inserted by the Share Extension process.
// Uncomment this and comment out the working version below
// to see the bug in action.

//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @Environment(\.scenePhase) private var scenePhase
//
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \SavedItem.createdAt, ascending: false)],
//        animation: .default
//    )
//    private var items: FetchedResults<SavedItem>
//
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(items) { item in
//                    VStack(alignment: .leading) {
//                        Text(item.text ?? "")
//                        Text(item.createdAt ?? Date(), style: .relative)
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                    }
//                }
//                .onDelete { offsets in
//                    offsets.map { items[$0] }.forEach(viewContext.delete)
//                    try? viewContext.save()
//                }
//            }
//            .navigationTitle("Saved Items")
//            .overlay {
//                if items.isEmpty {
//                    ContentUnavailableView(
//                        "Nothing Saved",
//                        systemImage: "square.and.arrow.down",
//                        description: Text("Share text from any app to save it here.")
//                    )
//                }
//            }
//            .refreshable {
//                // This does NOT work for new cross-process objects
//                viewContext.refreshAllObjects()
//            }
//            .onChange(of: scenePhase) {
//                if scenePhase == .active {
//                    viewContext.refreshAllObjects()
//                }
//            }
//        }
//    }
//}


// MARK: - The Working Approach (NSFetchedResultsController)

class SavedItemListViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var items: [SavedItem] = []

    private let fetchedResultsController: NSFetchedResultsController<SavedItem>
    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context

        let request: NSFetchRequest<SavedItem> = NSFetchRequest(entityName: "SavedItem")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SavedItem.createdAt, ascending: false)
        ]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        super.init()

        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        items = fetchedResultsController.fetchedObjects ?? []
    }

    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>
    ) {
        items = fetchedResultsController.fetchedObjects ?? []
    }

    func reload() {
        viewContext.reset()
        try? fetchedResultsController.performFetch()
        items = fetchedResultsController.fetchedObjects ?? []
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(items[index])
        }
        try? viewContext.save()
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm: SavedItemListViewModel

    init() {
        let context = PersistenceController.shared.container.viewContext
        _vm = StateObject(wrappedValue: SavedItemListViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.items) { item in
                    VStack(alignment: .leading) {
                        Text(item.text ?? "")
                        Text(item.createdAt ?? Date(), style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { vm.delete(at: $0) }
            }
            .navigationTitle("Saved Items")
            .overlay {
                if vm.items.isEmpty {
                    ContentUnavailableView(
                        "Nothing Saved",
                        systemImage: "square.and.arrow.down",
                        description: Text("Share text from any app to save it here.")
                    )
                }
            }
            .refreshable {
                vm.reload()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    vm.reload()
                }
            }
        }
    }
}
