
import Foundation
import Collections

public actor SyncCoordinator {
    
    let uploadRate: Int
    let rateLimit: Int //Not Implemented
    
    var syncCallsInProgress = Set<Task<SyncReport, Never>>()
    var previousCalls = Deque<Date>()
    var currentlyUploading = 0
    var inQueue = Deque<CheckedContinuation<(), Never>>()
    
    public init(uploadRate: Int = 3, rateLimit: Int = 5) { self.uploadRate = uploadRate; self.rateLimit = rateLimit }
    
    public func sync(_ notes: [Note]) async -> SyncReport {
        let result = Task {
            
            let (succeeded, failed, cancelled) = await withTaskGroup(of: NoteResult.self) { group in
                var succeeded =  [(noteID: UUID, serverTimestamp: Date)]()
                var failed = [(noteID: UUID, error: Error)]()
                var cancelled = [UUID]()
                
                for note in notes {
                    group.addTask { [self] in
                        await acquireSlot()
                        var result: NoteResult
                        
                        do {
                            let success = try await uploadNoteWithRetries(note)
                            result = NoteResult.success(note.id, success)
                        }
                        catch is CancellationError {
                            result = NoteResult.cancelled(note.id)
                        }
                        catch {
                            result = NoteResult.failure(note.id, error)
                        }
                        
                        await releaseSlot()
                        return result
                    }
                }
                                
                for await result in group {
                    switch result {
                    case .success(let id, let timeStamp): succeeded.append((noteID: id, serverTimestamp: timeStamp))
                    case .failure(let id, let error): failed.append((id, error))
                    case .cancelled(let id): cancelled.append(id)
                    }
                }
                
                return (succeeded, failed, cancelled)
            }
            
            return SyncReport(succeeded: succeeded, failed: failed, cancelled: cancelled)
            
        }
        
        syncCallsInProgress.insert(result)
        let completion = await result.value
        syncCallsInProgress.remove(result)
        return completion
    }
    
    private enum NoteResult {
        case success(UUID, Date)
        case failure(UUID, Error)
        case cancelled(UUID)
    }
    
    private func acquireSlot() async {
        if currentlyUploading < uploadRate {
            currentlyUploading += 1
            return
        }
        await withCheckedContinuation { cont in
            inQueue.append(cont)
        }
    }
    
    
    private func releaseSlot() async {
        if let first = inQueue.popFirst() { first.resume() }
        else { currentlyUploading -= 1 }
    }
    
    
    nonisolated private func uploadNoteWithRetries(_ note: Note) async throws -> Date {
        var attempts = 0

        while true {
            print("attempting to upload note \(note.id)")
            do {
                let successDate = try await uploadNote(note)
                return successDate
            }
            
            catch is CancellationError { throw SyncError.cancelled }
            
            catch {
                attempts += 1
                if attempts == 3 { throw error as! SyncError }
                try await Task.sleep(for: .milliseconds(attempts * 200))
            }
            
        }
    }
    
    
    public func cancelAll() async {
        for call in syncCallsInProgress { call.cancel() }
    }
    
}


public struct SyncReport: Sendable {
    public let succeeded: [(noteID: UUID, serverTimestamp: Date)]
    public let failed: [(noteID: UUID, error: Error)]
    public let cancelled: [UUID]
}
