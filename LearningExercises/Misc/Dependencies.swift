//
//  Dependencies.swift
//  
//
//  Created by Alejandro on 5/25/26.
//

import Foundation


public struct Note: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let body: String
    
    public init(id: UUID, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

public enum SyncError: Error {
    case serverError(noteID: UUID, statusCode: Int)
    case cancelled
}

// Mock server — simulates 100-400ms latency, ~10% random failure rate
public func uploadNote(_ note: Note) async throws -> Date {
    let latency = UInt64.random(in: 100_000_000...400_000_000)
    try await Task.sleep(nanoseconds: latency)
    try Task.checkCancellation()
    if Int.random(in: 0..<10) == 0 {
        throw SyncError.serverError(noteID: note.id, statusCode: 500)
    }
    return Date()  // server-confirmed timestamp
}




public enum BuildStatus: Equatable, Sendable {
    case queued
    case running(progress: Double)  // 0.0 to 1.0
    case succeeded
    case failed(reason: String)
}

public enum TrackerError: Error {
    case buildNotFound
    case networkError
}

public actor MockBuildServer {
    private struct BuildState {
        let startTime: Date
        let totalDuration: TimeInterval
        let shouldFail: Bool
    }
    
    private var builds: [UUID: BuildState] = [:]
    
    /// Register a build before tracking it.
    public func registerBuild(
        id: UUID,
        duration: TimeInterval = 8.0,
        shouldFail: Bool = false
    ) {
        builds[id] = BuildState(
            startTime: Date(),
            totalDuration: duration,
            shouldFail: shouldFail
        )
    }
    
    public func status(for buildID: UUID) async throws -> BuildStatus {
        try await Task.sleep(nanoseconds: UInt64.random(in: 50_000_000...150_000_000))
        
        guard let build = builds[buildID] else {
            throw TrackerError.buildNotFound
        }
        
        let elapsed = Date().timeIntervalSince(build.startTime)
        if elapsed < 1.0 { return .queued }
        if elapsed >= build.totalDuration {
            return build.shouldFail
                ? .failed(reason: "Compilation error")
                : .succeeded
        }
        let progress = (elapsed - 1.0) / (build.totalDuration - 1.0)
        return .running(progress: progress)
    }
}
