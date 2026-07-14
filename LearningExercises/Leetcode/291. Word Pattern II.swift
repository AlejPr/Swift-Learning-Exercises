/*
 
 291. Word Pattern II
 
 Given a pattern and a string s, return true if s matches the pattern.

 A string s matches a pattern if there is some bijective mapping of single characters to non-empty strings such that if each character in pattern is replaced by the string it maps to, then the resulting string is s. A bijective mapping means that no two characters map to the same string, and no character maps to two different strings.
 
 Input: pattern = "abab", s = "redblueredblue"
 Output: true
 
 */

//Searches the string, one character from the pattern at a time, attempting to build a valid dictionary of mappings through backtracking.
//A dictionary mapping a pattern char to a subarray of s is kept to prevent recomputing characters in the pattern, and as well to ensure conformance to the "bijective mapping" requirement of the problem statement.
//A set is also kept alongside the dictionary to ensure that no two letters match to the same word.
fileprivate func wordPatternMatch(_ pattern: String, _ s: String) -> Bool {
    let pattern = Array(pattern), s = Array(s)

    func search(_ p1: Int,_ s1: Int) -> Bool {
        if s1 == s.count || p1 == pattern.count { return p1 == pattern.count && s1 == s.count }
        let char = pattern[p1]

        //p1 char already mapped to a word, check to see if it matches the current index in the string; if not this mapping is invalid.
        if let existing = dict[pattern[p1]] {
            let endIndex = s1 + existing.count - 1
            guard endIndex < s.count else { return false }
            guard String(s[s1...endIndex]) == existing else { return false }
            return search(p1 + 1, endIndex + 1)
        }

        //try mapping p1 to a sequence; expand right trying each possibility
        var cur = [Character]()
        for i in s1...s.count - 1 {
            cur.append(s[i])
            let attempt = String(cur)
            if mapped.contains(attempt) { continue }

            dict[char] = attempt; mapped.insert(attempt)
            if search(p1 + 1, i + 1) { return true }
            dict.removeValue(forKey: char); mapped.remove(attempt)
        }

        return false
    }

    var dict = [Character: String]()
    var mapped = Set<String>()
    return search(0, 0)
}

