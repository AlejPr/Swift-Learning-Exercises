/*
 
 3336. Find the Number of Subsequences With Equal GCD
 
 You are given an integer array nums.

 Your task is to find the number of pairs of non-empty subsequences (seq1, seq2) of nums that satisfy the following conditions:

 The subsequences seq1 and seq2 are disjoint, meaning no index of nums is common between them.
 The GCD of the elements of seq1 is equal to the GCD of the elements of seq2.
 Return the total number of such pairs.

 Since the answer may be very large, return it modulo 109 + 7.
 
 */


//Knapsack like Top down DP; for each element in nums, we can either skip it, add it to sequence1, or sequence2.
//If adding to s1 or s2, we have to compute the new greatest common denominator; note that the sequence lengths do not matter. DP will compute all possibilities and the states are mutually exclusive; you cannot add a num to s1 and s2 at the same time.
//If we reach the end of nums and have chosen at least 1 element from each sequence, gcd of s1 and gcd of s2 must be equal to be a valid answer.
fileprivate func subsequencePairCount(_ nums: [Int]) -> Int {
    let ct = nums.count
    let mod = 1_000_000_000 + 7

    var memo = Array(repeating: Array(repeating: Array(repeating: -1, count: 201), count: 201), count: ct + 1)
    func search(at i: Int,_ gcd1: Int,_ gcd2: Int) -> Int {
        if i == ct {
            //If either gcd1 or gcd2 is equal to zero, no number was chosen from a subsequence, not valid.
            //if gcd1 does not equal gcd2, then it is not a valid answer according to the problem statement.
            return ((gcd1 != 0) && (gcd1 == gcd2)) ? 1 : 0
        }
        if memo[i][gcd1][gcd2] != -1 { return memo[i][gcd1][gcd2] }
        let num = nums[i]

        //skip
        var res = search(at: i + 1, gcd1, gcd2)

        //try to include in s1
        let gd1 = (gcd1 == 0) ? num : gcd(num, gcd1)
        res = (res + search(at: i + 1, gd1, gcd2)) % mod

        //try to include in s2
        let gd2 = (gcd2 == 0) ? num : gcd(num, gcd2)
        res = (res + search(at: i + 1, gcd1, gd2)) % mod

        memo[i][gcd1][gcd2] = res
        return res
    }

    return search(at: 0, 0, 0)
}

//GCD function I got from cp-algorithms.com
fileprivate func gcd(_ x: Int,_ y: Int) -> Int {
    var x = x, y = y
    while x != 0 {
        y %= x
        swap(&x, &y)
    }
    return y
}

