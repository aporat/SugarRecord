# SugarRecord

A lightweight Swift persistence helper for iOS / macOS / watchOS / tvOS.  
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

Define a store using `Storage` (Core Data by default):

```swift
import SugarRecord

@MainActor
final class NotesStore {
    private let db: Storage

    init() throws {
        let model = CoreDataObjectModel.named("MyModel", .main)
        let store = CoreDataStore.named("Notes.sqlite")
        self.db = try CoreDataDefaultStorage(store: store, model: model)
    }

    func createNote(title: String) async throws -> Note {
        try await db.write { ctx in
            let note: Note = try ctx.new()
            note.title = title
            note.createdAt = Date()
            return note
        }
    }

    func fetchNotes() async throws -> [Note] {
        try await db.read { ctx in
            let request = ctx.request(Note.self)
                .sorted(with: "createdAt", ascending: false)
            return try ctx.fetch(request)
        }
    }
}
```

---

## Core Concepts

- **`Storage`**  
  Abstract store (e.g. `CoreDataDefaultStorage`). Provides `mainContext` and `saveContext`.

- **`Context`**  
  Unit of work. Conforms to `Requestable`.  
  Supports fetching, inserting, querying, counting, batch operations.

- **`FetchRequest<T>`**  
  Lightweight builder for queries. Supports filtering, sorting, pagination.

```swift
let request = storage.request(Note.self)
    .filtered(with: "title", equalTo: "Hello")
    .sorted(with: "createdAt", ascending: false)
    .limit(20)

let notes = try storage.fetch(request)
```

- **Async Helpers**  
  `storage.read { ... }` and `storage.write { ... }` provide ergonomic concurrency-safe operations.

---

## Features

- Async/await `read` / `write` helpers
- Predictable thread confinement (Core Data contexts under the hood)
- In-memory stores for testing
- Small surface area, minimal boilerplate
- Batch update & delete support
- Extensible to other backends (not just Core Data)

---

## Platform Support

| Platform | Minimum |
| -------- | ------- |
| iOS      | 14      |
| macOS    | 12      |
| watchOS  | 8       |
| tvOS     | 15      |

---

## Documentation

- API reference (DocC) in `Documentation/`
- Examples in `Examples/`
- Unit tests in `Tests/` (in-memory stores, Core Data smoke tests)

---

## Contributing

- Follow [Conventional Commits](https://www.conventionalcommits.org)
- All PRs require passing CI (build + tests + lint)
- See `CONTRIBUTING.md`

---

## License

MIT
