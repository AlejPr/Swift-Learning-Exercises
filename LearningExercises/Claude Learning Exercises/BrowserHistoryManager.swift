import Foundation

class BrowserHistoryManager {
    
    internal var navigationStacks = [TabIndex: TabHistoryStack]()
    internal var unifiedHistory = [BrowserHistoryLogItem]()
 
    public func navigate(to newTab: (url: URL, previewName: String), with tabIndex: TabIndex) {
        let newItem = BrowserHistoryLogItem(previewName: newTab.previewName, visitTime: Date(), url: newTab.url)
        unifiedHistory.append(newItem)
        navigationStacks[tabIndex, default: TabHistoryStack()].append(newItem)
    }
    
    public func navigateBack(_ tabIndex: TabIndex) -> BrowserHistoryLogItem? {
        navigationStacks[tabIndex]?.navigateBack()
    }
    
    public func navigateForward(_ tabIndex: TabIndex) -> BrowserHistoryLogItem? {
        navigationStacks[tabIndex]?.navigateForward()
    }
    
    public func clearHistory() {
        unifiedHistory.removeAll()
    }
    
    public func closeTab(_ tab: TabIndex) {
        navigationStacks.removeValue(forKey: tab)
    }
    
    public func searchHistory(for keyword: String) -> [BrowserHistoryLogItem] {
        return unifiedHistory.filter { $0.url.absoluteString.contains(keyword) || $0.previewName.contains(keyword) }
    }
    
    internal struct TabHistoryStack {
        
        var stack = [BrowserHistoryLogItem]()
        var curIndex = 0
        
        mutating func append(_ newItem: BrowserHistoryLogItem) {
            while (stack.count - 1) > curIndex { stack.removeLast() }
            
            stack.append(newItem)
            curIndex += 1
        }
        
        mutating func navigateBack() -> BrowserHistoryLogItem? {
            guard curIndex - 1 >= 0 else { return nil }
            curIndex -= 1
            return stack[curIndex]
        }
        
        mutating func navigateForward() -> BrowserHistoryLogItem? {
            guard curIndex + 1 < stack.count else { return nil }
            curIndex += 1
            return stack[curIndex]
        }
        
    }
    
}


struct TabIndex: Hashable {
    let value: Int
}

struct BrowserHistoryLogItem {
    var previewName: String
    var visitTime: Date
    var url: URL
}
