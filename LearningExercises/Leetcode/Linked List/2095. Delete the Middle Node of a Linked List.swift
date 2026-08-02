/*

 2095. Delete the Middle Node of a Linked List

 Given the head of a linked list, delete the middle node and return the head of the modified list. The middle node is the ⌊n / 2⌋-th node from the start (0-indexed), where n is the number of nodes.

 https://leetcode.com/problems/delete-the-middle-node-of-a-linked-list/

 */

import Foundation

//Two (in this case 3) pointers, fast races to the end of the list, slow ends up being the middle node, prev is the node behind the middle.
//Prev cuts off the middle node (slow) after the fast pointer reaches the end of the list
//O(1) space and O(n) time with 1 pass
fileprivate class Solution {
    func deleteMiddle(_ head: ListNode?) -> ListNode? {
        if head?.next == nil { return nil }

        var fast = head, slow = head, prev = head

        while fast?.next != nil {
            fast = fast?.next?.next
            prev = slow
            slow = slow?.next
        }

        prev?.next = slow?.next
        slow?.next = nil

        return head
    }
}


fileprivate class ListNode {
    public var val: Int
    public var next: ListNode?
    public init() { self.val = 0; self.next = nil; }
    public init(_ val: Int) { self.val = val; self.next = nil; }
    public init(_ val: Int, _ next: ListNode?) { self.val = val; self.next = next; }
 }
