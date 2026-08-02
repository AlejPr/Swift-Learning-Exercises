"""
288. Unique Word Abbreviation

The abbreviation of a word is a concatenation of its first letter, the number of characters between the first and last letter, and its last letter. If a word has only two characters, then it is an abbreviation of itself.

For example:

dog --> d1g because there is one letter between the first letter 'd' and the last letter 'g'.
internationalization --> i18n because there are 18 letters between the first letter 'i' and the last letter 'n'.
it --> it because any word with only two characters is an abbreviation of itself.
Implement the ValidWordAbbr class:

ValidWordAbbr(String[] dictionary) Initializes the object with a dictionary of words.
boolean isUnique(string word) Returns true if either of the following conditions are met (otherwise returns false):
There is no word in dictionary whose abbreviation is equal to word's abbreviation.
For any word in dictionary whose abbreviation is equal to word's abbreviation, that word and word are the same.

https://leetcode.com/problems/unique-word-abbreviation/
"""

class ValidWordAbbr:

    abbrev = { }

    def __init__(self, dictionary: List[str]):
        self.abbrev = { }
        for word in dictionary:
            stored = self.abbrev.setdefault(self.abbreviate(word), set())
            stored.add(word)

    def isUnique(self, word: str) -> bool:
        wordAbbrev = self.abbreviate(word)
        stored = self.abbrev.get(wordAbbrev)
        if stored is None: return True
        return len(stored) == 1 and word in stored

    def abbreviate(self, word: str) -> str:
        if len(word) <= 2: return word
        return word[0] + str(len(word) - 2) + word[len(word) - 1]
