# 1358. Number of Substrings Containing All Three Characters
# Given a string s consisting only of characters a, b and c.
# Return the number of substrings containing at least one occurrence of all these characters a, b and c.

 
 class Solution:
 
    def numberOfSubstrings(self, s: str) -> int:
        ans = 0; left = 0; right = 0

        freq = [0] * 3
        while right < len(s):
            freq[ord(s[right]) - ord("a")] += 1

            while self.isValid(freq):
                ans += len(s) - right
                freq[ord(s[left]) - ord("a")] -= 1
                left += 1

            right += 1

        return ans

    def isValid(self, freq) -> Bool:
        return freq[0] > 0 and freq[1] > 0 and freq[2] > 0
