//Doubly Linked List Implementation

private class Allocator {

    final internal class ListNode {
        var mID: Int
        var index: Int
        var size: Int
        var prev: ListNode?
        var next: ListNode?
        init(_ mID: Int,_ index: Int,_ size: Int) {
            self.mID = mID; self.index = index; self.size = size
        }
        //deinit { print("deinit node with \(mID), sz of \(size)")}
    }

    let dummyHead: ListNode
    var storedAddresses = [Int: [ListNode]]()

    init(_ n: Int) {
        dummyHead = ListNode(-2, -1, -1)
        dummyHead.next = ListNode(-1, 0, n)
    }
    
    func allocate(_ size: Int, _ mID: Int) -> Int {
        var cur = dummyHead.next
        while cur != nil, (cur!.mID != -1 || cur!.size < size) { cur = cur?.next }
        guard let cur else { return -1 }
        
        let freeSz = cur.size
        cur.mID = mID
        cur.size = size
        if freeSz - size > 0 {
            //insert new node
            let newNode = ListNode(-1, cur.index + size, freeSz - size)
            let next = cur.next
            next?.prev = newNode; cur.next = newNode
            newNode.prev = cur; newNode.next = next
        }

        storedAddresses[mID, default: []].append(cur)
        return cur.index
    }
    
    func freeMemory(_ mID: Int) -> Int {
        guard let refs = storedAddresses[mID] else { return 0 }

        var total = 0
        for ref in refs {
            total += ref.size
            deallocate(ref)
        }

        storedAddresses.removeValue(forKey: mID)
        return total
    }

    private func deallocate(_ node: ListNode) {
        node.mID = -1
        var cur = node

        if let prev = cur.prev, prev.mID == -1 {
            prev.size += cur.size
            prev.next = cur.next
            cur.next?.prev = prev
            cur.prev = nil
            cur.next = nil
            cur = prev
        }

        while let next = cur.next, next.mID == -1 {
            cur.size += next.size
            cur.next = next.next
            next.next?.prev = cur

            next.prev = nil
            next.next = nil
        }

    }
}
