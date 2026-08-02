/*

 3093. Longest Common Suffix Queries

 You are given two arrays of strings wordsContainer and wordsQuery. For each wordsQuery[i], you need
 to find a string from wordsContainer that has the longest common suffix with wordsQuery[i]. If there
 are two or more such strings that have the longest common suffix, find the string that is the
 shortest, and if there are two or more such strings, find the one that occurred earlier in
 wordsContainer.

 Return an array of integers ans, where ans[i] is the index of the string in wordsContainer that has
 the longest common suffix with wordsQuery[i].

 https://leetcode.com/problems/longest-common-suffix-queries/

 */

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
