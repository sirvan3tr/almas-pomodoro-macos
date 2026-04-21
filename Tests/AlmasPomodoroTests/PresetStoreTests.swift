import XCTest
@testable import AlmasPomodoro

final class PresetStoreTests: XCTestCase {

    private func tempURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("almas-pomodoro-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("presets.json")
    }

    func testSeedsDefaultsOnFirstLoad() throws {
        let url = tempURL()
        let store = try PresetStore(fileURL: url)
        XCTAssertEqual(store.presets.map(\.name), ["Pomodoro", "Short Break", "Long Break"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testAppendPersists() throws {
        let url = tempURL()
        let store = try PresetStore(fileURL: url)
        try store.append(Preset(name: "Deep Work", seconds: 50 * 60))

        let reopened = try PresetStore(fileURL: url)
        XCTAssertTrue(reopened.presets.contains(where: { $0.name == "Deep Work" }))
    }

    func testRemovePersists() throws {
        let url = tempURL()
        let store = try PresetStore(fileURL: url)
        let target = store.presets[0]
        let removed = try store.remove(id: target.id)
        XCTAssertTrue(removed)

        let reopened = try PresetStore(fileURL: url)
        XCTAssertFalse(reopened.presets.contains(where: { $0.id == target.id }))
    }

    func testCorruptFileIsQuarantinedAndSurfaced() throws {
        let url = tempURL()
        try "not-json".data(using: .utf8)!.write(to: url)

        XCTAssertThrowsError(try PresetStore(fileURL: url)) { err in
            if case PresetStore.StoreError.corrupt = err {
                // expected
            } else {
                XCTFail("expected .corrupt, got \(err)")
            }
        }

        // Original file should have been renamed (not silently dropped).
        let parent = url.deletingLastPathComponent()
        let siblings = try FileManager.default.contentsOfDirectory(atPath: parent.path)
        XCTAssertTrue(siblings.contains(where: { $0.contains("corrupt-") }),
                      "expected quarantined file; got \(siblings)")
    }

    func testUnknownKeysArePreserved() throws {
        let url = tempURL()
        let blob: [String: Any] = [
            "presets": [
                ["id": UUID().uuidString, "name": "Focus", "seconds": 1500]
            ],
            "schemaVersion": 7,
            "experiment": ["a": 1, "b": "two"]
        ]
        let data = try JSONSerialization.data(withJSONObject: blob, options: [.prettyPrinted])
        try data.write(to: url)

        let store = try PresetStore(fileURL: url)
        try store.append(Preset(name: "Extra", seconds: 60))

        let raw = try Data(contentsOf: url)
        let parsed = try JSONSerialization.jsonObject(with: raw) as! [String: Any]
        XCTAssertEqual(parsed["schemaVersion"] as? Int, 7)
        XCTAssertNotNil(parsed["experiment"])
    }
}
