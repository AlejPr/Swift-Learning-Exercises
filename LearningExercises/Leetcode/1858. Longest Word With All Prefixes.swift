/*
 
 1858. Longest Word With All Prefixes
 
 Given an array of strings words, find the longest string in words such that every prefix of it is also in words.

 For example, let words = ["a", "app", "ap"]. The string "app" has prefixes "ap" and "a", all of which are in words.
 Return the string described above. If there is more than one string with the same length, return the lexicographically smallest one, and if no string exists, return "".
 
 Input: words = ["k","ki","kir","kira", "kiran"]
 Output: "kiran"
 
 */

fileprivate class Solution {

    final private class Trie { 
        var children = [Character: Trie]()
        var end = false
        subscript(_ i: Character) -> Trie? { 
            get { children[i] }
            set(new) { children[i] = new }
        }

        public func insert(_ word: String) -> String? { 
            var cur = self
            for (index, char) in word.enumerated() { 
                if cur[char] == nil { cur[char] = Trie() }
                cur = cur[char]!
                if !cur.end && index != word.count - 1 { return nil }
            }
            cur.end = true 
            return word
        }

    }

    func longestWord(_ words: [String]) -> String {
        let trie = Trie() 
        let sorted = words.sorted() 
        var ans = ""
        for word in sorted { 
            guard let res = trie.insert(word) else { continue }
            if res.count > ans.count { ans = res }
        }
        return ans
    }
}
