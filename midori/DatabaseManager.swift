//
//  DatabaseManager.swift
//  midori
//
//  SQLite database for storing Midori conversation history (superjournal)
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private let dbPath: String

    private init() {
        // Store database in Application Support directory
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let midoriDir = appSupport.appendingPathComponent("Midori")

        // Create directory if needed
        try? fileManager.createDirectory(at: midoriDir, withIntermediateDirectories: true)

        dbPath = midoriDir.appendingPathComponent("midori.db").path
        print("✓ Database path: \(dbPath)")

        openDatabase()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("❌ Failed to open database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        print("✓ Database opened successfully")
    }

    private func createTables() {
        let createSQL = """
            CREATE TABLE IF NOT EXISTS superjournal (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                turn_number INTEGER NOT NULL,
                user_message TEXT NOT NULL,
                assistant_message TEXT NOT NULL,
                created_at TEXT DEFAULT (datetime('now', 'localtime'))
            );
            CREATE INDEX IF NOT EXISTS idx_superjournal_turn ON superjournal(turn_number DESC);
        """

        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, createSQL, nil, nil, &errMsg) != SQLITE_OK {
            if let errMsg = errMsg {
                print("❌ Failed to create tables: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
            return
        }
        print("✓ Database tables ready")
    }

    // MARK: - Public API

    /// Add a conversation turn to the superjournal
    /// - Returns: The turn number of the newly added turn
    @discardableResult
    func addTurn(userMessage: String, assistantMessage: String) -> Int {
        // Get the next turn number
        let nextTurn = getNextTurnNumber()

        let insertSQL = "INSERT INTO superjournal (turn_number, user_message, assistant_message) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
            print("❌ Failed to prepare insert statement")
            return nextTurn
        }

        sqlite3_bind_int(stmt, 1, Int32(nextTurn))
        sqlite3_bind_text(stmt, 2, userMessage, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 3, assistantMessage, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        if sqlite3_step(stmt) != SQLITE_DONE {
            print("❌ Failed to insert turn: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✓ Added turn \(nextTurn) to superjournal")
        }

        sqlite3_finalize(stmt)
        return nextTurn
    }

    /// Get recent conversation turns
    /// - Parameter limit: Maximum number of turns to return (default 100)
    /// - Returns: Array of turns, oldest first
    func getRecentTurns(limit: Int = 100) -> [(turn: Int, user: String, assistant: String, date: Date)] {
        let selectSQL = """
            SELECT turn_number, user_message, assistant_message, created_at
            FROM superjournal
            ORDER BY turn_number DESC
            LIMIT ?
        """

        var stmt: OpaquePointer?
        var results: [(turn: Int, user: String, assistant: String, date: Date)] = []

        guard sqlite3_prepare_v2(db, selectSQL, -1, &stmt, nil) == SQLITE_OK else {
            print("❌ Failed to prepare select statement")
            return results
        }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        while sqlite3_step(stmt) == SQLITE_ROW {
            let turn = Int(sqlite3_column_int(stmt, 0))
            let user = String(cString: sqlite3_column_text(stmt, 1))
            let assistant = String(cString: sqlite3_column_text(stmt, 2))
            let dateStr = String(cString: sqlite3_column_text(stmt, 3))
            let date = dateFormatter.date(from: dateStr) ?? Date()

            results.append((turn: turn, user: user, assistant: assistant, date: date))
        }

        sqlite3_finalize(stmt)

        // Return in chronological order (oldest first)
        return results.reversed()
    }

    /// Get all turns (no limit)
    func getAllTurns() -> [(turn: Int, user: String, assistant: String, date: Date)] {
        return getRecentTurns(limit: 1_000_000)  // Effectively unlimited, but fits in Int32
    }

    /// Get the total number of turns
    func getTurnCount() -> Int {
        let countSQL = "SELECT COUNT(*) FROM superjournal"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, countSQL, -1, &stmt, nil) == SQLITE_OK else {
            return 0
        }

        var count = 0
        if sqlite3_step(stmt) == SQLITE_ROW {
            count = Int(sqlite3_column_int(stmt, 0))
        }

        sqlite3_finalize(stmt)
        return count
    }

    /// Clear all conversation history
    func clearAll() {
        let deleteSQL = "DELETE FROM superjournal"
        var errMsg: UnsafeMutablePointer<CChar>?

        if sqlite3_exec(db, deleteSQL, nil, nil, &errMsg) != SQLITE_OK {
            if let errMsg = errMsg {
                print("❌ Failed to clear superjournal: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
            return
        }
        print("✓ Superjournal cleared")
    }

    // MARK: - Private Helpers

    private func getNextTurnNumber() -> Int {
        let maxSQL = "SELECT COALESCE(MAX(turn_number), 0) FROM superjournal"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, maxSQL, -1, &stmt, nil) == SQLITE_OK else {
            return 1
        }

        var maxTurn = 0
        if sqlite3_step(stmt) == SQLITE_ROW {
            maxTurn = Int(sqlite3_column_int(stmt, 0))
        }

        sqlite3_finalize(stmt)
        return maxTurn + 1
    }
}
