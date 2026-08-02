# 224. Basic Calculator
# Given a string s representing a valid expression, implement a basic calculator to evaluate it,
# and return the result of the evaluation.
# s consists of digits, '+', '-', '(', ')', and ' '. The expression may contain nested parentheses
# and unary minus. You are not allowed to use any built-in function which evaluates strings as
# mathematical expressions, such as eval().
# https://leetcode.com/problems/basic-calculator/

#easier to understand but slower
class RecursiveSolution:
    def calculate(self, s: str) -> int:
        stack = []
        ans = 0; cur = 0; mul = 1

        for c in s:
            if c.isdigit():
                cur *= 10
                cur += int(c)

            #base case
            elif c == ")":
                ans += (cur * mul)
                cur = 0
                prev_mul = stack.pop()
                prev_ans = stack.pop()
                ans = prev_ans + (prev_mul * ans)

            #recurse to solve the next parenthesis
            elif c == "(":
                stack.append(ans); stack.append(mul)
                cur = 0; ans = 0; mul = 1

            #addition or subtraction operation, add current values and clean states for next value
            elif c == "+":
                ans += mul * cur
                cur = 0; mul = 1

            elif c == "-":
                ans += mul * cur
                cur = 0; mul = -1

        ans += mul * cur
        return ans


# optimized solution
class IterativeFlatSolution:
    def calculate(self, s: str) -> int:
        stack = []
        ans = 0; cur = 0; mul = 1

        for c in s:
            if c.isdigit():
                cur *= 10
                cur += int(c)

            #base case
            elif c == ")":
                ans += (cur * mul)
                cur = 0
                prev_mul = stack.pop()
                prev_ans = stack.pop()
                ans = prev_ans + (prev_mul * ans)

            #recurse to solve the next parenthesis
            elif c == "(":
                stack.append(ans); stack.append(mul)
                cur = 0; ans = 0; mul = 1

            #addition or subtraction operation, add current values and clean states for next value
            elif c == "+":
                ans += mul * cur
                cur = 0; mul = 1

            elif c == "-":
                ans += mul * cur
                cur = 0; mul = -1

        ans += mul * cur
        return ans
