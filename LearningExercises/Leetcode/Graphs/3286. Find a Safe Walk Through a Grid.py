"""
3286. Find a Safe Walk Through a Grid

You are given an m x n binary matrix grid and an integer health.

You start on the upper-left corner (0, 0) and would like to get to the lower-right corner (m - 1, n - 1).

You can move up, down, left, or right from one cell to another adjacent cell as long as your health remains positive.

Cells (i, j) with grid[i][j] = 1 are considered unsafe and reduce your health by 1.

Return true if you can reach the final cell with a health value of 1 or more, and false otherwise.

https://leetcode.com/problems/find-a-safe-walk-through-a-grid/
"""

from collections import deque

class Solution:
    def findSafeWalk(self, grid: List[List[int]], health: int) -> bool:
        m = len(grid); n = len(grid[0])
        visited = [[False] * n for _ in range(m)]

        startHealth = health - grid[0][0]
        if startHealth == 0: return False
        visited[0][0] = True

        queue = deque([(0, 0, startHealth)])
        while len(queue) != 0:
            first = queue.popleft()
            if first[0] == m - 1 and first[1] == n - 1: return True

            for delta in [(0, 1), (1, 0), (-1, 0), (0, -1)]:
                newR = first[0] + delta[0]; newC = first[1] + delta[1]
                if newR < 0 or newR >= m or newC < 0 or newC >= n: continue
                if visited[newR][newC]: continue

                if grid[newR][newC] == 0:
                    queue.appendleft((newR, newC, first[2]))
                    visited[newR][newC] = True

                else:
                    newHealth = first[2] - 1
                    if newHealth == 0: continue
                    queue.append((newR, newC, newHealth))
                    visited[newR][newC] = True

        return False

