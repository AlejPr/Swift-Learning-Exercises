import Foundation


fileprivate class Solution {

    fileprivate func stringIndices(_ wordsContainer: [String], _ wordsQuery: [String]) -> [Int] {
    
        class TrieNode {
            var children = [Character: TrieNode]()
            var mindex = -1
            var minCount = Int.max
        }
        
        let root = TrieNode()
        
        for (wordIndex, word) in wordsContainer.enumerated() {
            let wordCount = word.count
            var cur = root
            
            for char in word.reversed() {
                if wordCount < cur.minCount {
                    cur.minCount = wordCount; cur.mindex = wordIndex
                }
                
                if cur.children[char] == nil {
                    cur.children[char] = TrieNode()
                }
                cur = cur.children[char]!
            }

            if wordCount < cur.minCount {
                cur.minCount = wordCount; cur.mindex = wordIndex
            }
        }
        
        return wordsQuery.map {
            var cur = root
            for char in $0.reversed() {
                guard let next = cur.children[char] else { return cur.mindex }
                cur = next
            }
            return cur.mindex
        }
        
    }

}
