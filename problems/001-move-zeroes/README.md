# Move Zeroes

- LeetCode No: 283
- Problem: https://leetcode.com/problems/move-zeroes/
- Study Plan: https://leetcode.com/studyplan/leetcode-75/
- Status: Done
- Approach Used: Temp Array

## Approach

Use a temporary array approach.

- First collect all non-zero values into `tempnums`.
- Then append zeros to `tempnums` based on how many zeros are in the original array.
- Finally copy all values from `tempnums` back into `nums`.
- This keeps the non-zero values in order and moves all zeros to the end.

## Complexity

- Time: `O(n)`
- Space: `O(n)`
