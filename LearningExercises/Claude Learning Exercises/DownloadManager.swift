import Foundation
import Collections

actor DownloadManager {
    
    internal var queued = Deque<(UUID, CheckedContinuation<Bool, Never>)>()
    internal var pending = [UUID : (Task<(), Never>, DownloadState)]() //Stores the stream task and latest download state
    internal var finished = [UUID: DownloadState]()
    
    internal let concurrentDownloadLimit: Int
    internal var currentInFlightDownloadCount: Int = 0
    internal let downloadsDirectory: String
    internal let networkManager: NetworkManager
    
    init(_ networkManager: NetworkManager, concurrentDownloadLimit: Int, downloadsDirectory: String) {
        self.networkManager = networkManager
        self.concurrentDownloadLimit = concurrentDownloadLimit
        self.downloadsDirectory = downloadsDirectory
    }
    
    public func startDownload(_ objectURL: URL) async -> (UUID, AsyncStream<DownloadState>) {
        let token = UUID()
        let destinationURL = URL(filePath: downloadsDirectory).appending(path: token.uuidString)

        let progressStream = AsyncStream<DownloadState>() { continuation in
            let streamTask = Task {

                var finalState = DownloadState.completed(fileURL: destinationURL)
                var acquiredSlot = false
                defer {
                    pending.removeValue(forKey: token)
                    finished[token] = finalState
                    continuation.yield(finalState)
                    continuation.finish()
                    if shouldDeleteUnfinishedFile(finalState) { deleteUnfinishedFile(destinationURL) }
                    if acquiredSlot { signal() }
                }

                //Await semaphore
                acquiredSlot = await acquire(token)

                //Cancellation point 1, task cancelled before inflight (killed while queued)
                guard !Task.isCancelled else { finalState = DownloadState.cancelled; return }
                let (downloadStream, totalBytes) = await networkManager.streamObjectFromURL(objectURL)

                guard let outputStream = OutputStream(url: destinationURL, append: false) else {
                    finalState = .failed(error: DownloadError.cannotOpenOutputStream(destinationURL)); return
                }
                outputStream.open()
                defer { outputStream.close() }

                var totalBytesWritten = 0

                do {
                    for try await nextChunk in downloadStream {
                        //Cancellation point 2, task cancelled while inflight (killed while downloading)
                        guard !Task.isCancelled else { finalState = DownloadState.cancelled; return }

                        //TODO: - Implement
                        //File IO, write the chunks to the output stream
                        totalBytesWritten += nextChunk.count
                        continuation.yield(.downloading(bytesWritten: totalBytesWritten, bytesTotal: totalBytes))
                    }
                }

                catch { finalState = .failed(error: error) }
            }
            
            //Initial state
            pending[token] = (streamTask, DownloadState.queued)
        }

        return (token, progressStream)
    }
    
    public func getDownloadState(for token: UUID) -> DownloadState? {
        if let exists = pending[token] { return exists.1 }
        return nil
    }
    
    
    private func shouldDeleteUnfinishedFile(_ downloadState: DownloadState) -> Bool {
        switch downloadState {
        case .cancelled, .failed(_): return true
        default: return false
        }
    }
    
    private func deleteUnfinishedFile(_ filePath: URL) {
        
    }
    
    private func acquire(_ token: UUID) async -> Bool {
        if currentInFlightDownloadCount < concurrentDownloadLimit {
            currentInFlightDownloadCount += 1
            return true
        }

        // Suspends until either signal() hands over a slot (true) or the download is cancelled (false).
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            queued.append((token, cont))
        }
    }

    private func signal() {
        if let (_, continuation) = queued.popFirst() { continuation.resume(returning: true) }
        else { currentInFlightDownloadCount -= 1 }
    }
    
    public func cancelDownload(with token: UUID) {
        guard let (task, _) = pending[token] else { return }
        task.cancel()

        if let index = queued.firstIndex(where: { $0.0 == token }) {
            let (_, continuation) = queued.remove(at: index)
            continuation.resume(returning: false)
        }
    }

    public func cancelAll() {
        for (task, _) in pending.values { task.cancel() }
        while let (_, continuation) = queued.popFirst() { continuation.resume(returning: false) }
    }
    
    enum DownloadState {
        case downloading(bytesWritten: Int, bytesTotal: Int?)
        case completed(fileURL: URL)
        case failed(error: Error)
        case cancelled
        case queued
    }

    enum DownloadError: Error {
        case cannotOpenOutputStream(URL)
        case writeFailed
    }

}


//Mock
actor NetworkManager {
    
    public func streamObjectFromURL(_ url: URL) -> (AsyncThrowingStream<Data, Error>, Int?) {
        let stream = AsyncThrowingStream<Data, Error>() { _ in }
        let totalBytes: Int? = 10_000_000
        return (stream, totalBytes)
    }
    
}
