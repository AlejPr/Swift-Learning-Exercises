/*

 127. Word Ladder

 A transformation sequence from word beginWord to word endWord using a dictionary wordList is a
 sequence beginWord -> s1 -> s2 -> ... -> sk such that every adjacent pair of words differs by a
 single letter, every si (1 <= i <= k) is in wordList, and sk == endWord.

 Return the number of words in the shortest transformation sequence from beginWord to endWord, or
 0 if no such sequence exists.

 Input: beginWord = "hit", endWord = "cog", wordList = ["hot","dot","dog","lot","log","cog"]
 Output: 5

 https://leetcode.com/problems/word-ladder/

 */

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
