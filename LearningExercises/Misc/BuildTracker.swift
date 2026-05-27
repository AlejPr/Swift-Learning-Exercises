import Foundation


public actor BuildTracker {
    
    let server: MockBuildServer
    let pollInterval: Duration
    
    var activeStreams = [UUID: Task<(), Error>]()
    
    public init(server: MockBuildServer, pollInterval: Duration = .seconds(1)) { self.server = server; self.pollInterval = pollInterval }
    
    public func track(buildID: UUID) -> AsyncStream<BuildStatus> {
        
        let stream = AsyncStream<BuildStatus> { continuation in
            let streamTask = Task {
                defer { continuation.finish() }
                
                var consecutiveErrors = 0
                var previousStatus: BuildStatus?
                
                func emit(_ status: BuildStatus) {
                    consecutiveErrors = 0
                    guard previousStatus != status else { return }
                    previousStatus = status
                    continuation.yield(status)
                }

                
                while !Task.isCancelled {
                    do {
                        let status = try await server.status(for: buildID)
                        switch status {
                            
                        case .queued:
                            emit(status)
                            
                        case .running(progress: _):
                            emit(status)
                            
                        case .succeeded, .failed(reason: _):
                            emit(status); return
                            
                        }
                    } catch {
                        print(error)
                        consecutiveErrors += 1
                        if consecutiveErrors == 3 { return }
                    }
                    
                    if Task.isCancelled { break }
                    else { try await Task.sleep(for: pollInterval) }
                }
            }
            
            self.activeStreams[buildID] = streamTask
            
            continuation.onTermination = { @Sendable _ in
                Task { await self.stopTracking(buildID: buildID) }
            }
        }
                
        return stream
    }
    
    
    public func stopTracking(buildID: UUID) async {
        guard let stream = activeStreams[buildID] else { return }
        activeStreams.removeValue(forKey: buildID)
        stream.cancel()
    }
    
    public func currentlyTracking() async -> Set<UUID> {
        Set<UUID>(activeStreams.keys)
    }
    
}
