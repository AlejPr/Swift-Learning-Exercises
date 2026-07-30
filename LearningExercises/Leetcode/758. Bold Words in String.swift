/*
 
 758. Bold Words in String
 
 Given an array of keywords words and a string s, make all appearances of all keywords words[i] in s bold. Any letters between <b> and </b> tags become bold.

 Return s after adding the bold tags. The returned string should use the least number of tags possible, and the tags should form a valid combination.
 
 Input: words = ["ab","bc"], s = "aabcd"
 Output: "a<b>abc</b>d"
 
 */


fileprivate class Solution {

    private final class TrieNode { 
        var children = [Character: TrieNode]()
        var endOfWord = false

        subscript(_ i: Character) -> TrieNode? { 
            get { children[i] }
            set(new) { children[i] = new }
        }

        public func insert(_ word: String) { 
            var cur = self 
            for char in word { 
                if cur[char] == nil { cur[char] = TrieNode() }
                cur = cur[char]!
            }
            cur.endOfWord = true
        }

    }

    func boldWords(_ words: [String], _ s: String) -> String {
        let trie = words.reduce(into: TrieNode()) { $0.insert($1) }
        let s = Array(s), n = s.count

        var bold = Array(repeating: false, count: n), end = 0
        for i in s.indices { 
            var node = trie , j = i 

            while j < n, let next = node[s[j]] {
                node = next
                j += 1

                if node.endOfWord { end = max(end, j) }
            }

            bold[i] = end > i
        }

        var ans = ""
        var curBold = false
        for i in s.indices { 
            if bold[i] && !curBold { 
                curBold = true 
                ans.append("<b>")
            }
            else if !bold[i] && curBold { 
                curBold = false 
                ans.append("</b>")
            }
            ans.append(s[i])
        }
        if curBold { ans.append("</b>")}

        return ans
    }
}
