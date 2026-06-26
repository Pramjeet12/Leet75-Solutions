class Solution:
    def reverseWords(self, s: str) -> str:
        words = s.split()
        for i in range(0, len(words) // 2):
            words[i], words[(len(words) - 1) - i] = words[(len(words) - 1) - i], words[i]
        return " ".join(words)
