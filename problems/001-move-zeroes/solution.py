from typing import List


class Solution:
    def moveZeroes(self, nums: List[int]) -> None:
        tempnums = []

        for i in range(len(nums)):
            if nums[i] != 0:
                tempnums.append(nums[i])

        for i in range(len(nums)):
            if nums[i] == 0:
                tempnums.append(0)

        for i in range(len(nums)):
            nums[i] = tempnums[i]
