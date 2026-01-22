# SugarRecord

A lightweight Swift persistence helper for iOS / macOS.
Focus: ergonomic APIs, testability, and modern Swift Concurrency.

---

## Installation

### Swift Package Manager

Add to **Package.swift**:

```swift
.package(url: "https://github.com/aporat/SugarRecord.git", from: "1.1.0")
```

Then add `"SugarRecord"` to your target dependencies.

### CocoaPods

```ruby
pod 'SugarRecord'
```

---

## Quick Start

Define a store using `SugarRecord` (Core Data wrapper):

```swift
import SugarRecord

@MainActor
final class NotesStore {
    private let db: SugarRecord

    init() throws {
        let model = CoreDataObjectModel.named("MyModel", .main)
        let store = CoreDataStore.named("Notes.sqlite")
        self.db = try SugarRecord(store: store, model: model)
    }

    func createNote(title: String) async throws {
        let note: Note = try db.mainContext.new()
        note.title = title
        note.createdAt = Date()
        try await db.mainContext.saveToPersistentStore()
    }

    func fetchNotes() async throws -> [Note] {
        let request = FetchRequest<Note>(db.mainContext)
            .sorted(key: "createdAt", ascending: false)
        return try await request.fetch()
    }
}
```

---

## Core Concepts

- **`SugarRecord`**
  Main Core Data stack manager. Provides `mainContext` for UI operations and `performBackgroundTask` for background work.

- **`NSManagedObjectContext` Extensions**
  Extended with convenient methods: `fetch`, `new`, `remove`, `saveToPersistentStore`, and batch operations.

- **`FetchRequest<T>`**
  Lightweight builder for queries. Supports filtering, sorting, pagination.

```swift
let request = FetchRequest<Note>(db.mainContext)
    .filtered(key: "title", equalTo: "Hello")
    .sorted(key: "createdAt", ascending: false)
    .limit(20)

let notes = try await request.fetch()
```

- **Async/Await Support**
  All context operations support both sync and async variants for flexibility.

---

## Features

- Async/await support for all operations
- Predictable thread confinement (Core Data contexts under the hood)
- In-memory stores for testing
- Small surface area, minimal boilerplate
- Batch update & delete support
- Background task execution with automatic merge to main context

---

## Platform Support

| Platform | Minimum |
| -------- | ------- |
| iOS      | 17      |
| macOS    | 14      |

---

## Documentation

- Unit tests in `Tests/` (in-memory stores, Core Data smoke tests)

---

## Contributing

- Follow [Conventional Commits](https://www.conventionalcommits.org)
- All PRs require passing CI (build + tests + lint)
- See `CONTRIBUTING.md`

---

## License

MIT
