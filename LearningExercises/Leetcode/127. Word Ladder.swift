fileprivate class Solution {
    func ladderLength(_ beginWord: String, _ endWord: String, _ wordList: [String]) -> Int {
        guard beginWord != endWord else { return 0 }
        let endWord = Array(endWord)

        var wordList = Set(wordList.map { Array($0)} )
        
        var queue = WordQueue()
        queue.w.append(Array(beginWord))
        var depth = 1
        
        while queue.w.count > 0 { 
            let newQueue = WordQueue()
            for word in queue.w { 
                if word == endWord { return depth }
                var word = word

                for (index, char) in word.enumerated() { 
                    for newChar in "abcdefghijklmnopqrstuvwxyz" { 
                        word[index] = newChar 
                        if wordList.contains(word) { 
                            newQueue.w.append(word) 
                            wordList.remove(word)
                        }
                    }
                    word[index] = char
                }
            }

            queue = newQueue
            depth += 1
        }

        return 0
    }

    final private class WordQueue { 
        var w = [[Character]]()
    }
}
