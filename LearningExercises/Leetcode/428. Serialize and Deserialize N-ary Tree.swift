

//Definition for a Node.
fileprivate class Node {
  public var val: Int
  public var children: [Node]
  public init(_ val: Int) {
      self.val = val
      self.children = []
  }
}
 

extension Node { 
    public func serialize() -> String { 
        let children = (self.children.map { $0.serialize() }).joined(separator: ",")
        return "{\(self.val)\(children.count > 0 ? "[\(children)]" : "" )}"
    }
}

//MARK: - Recursive Serialization / Deserialization
fileprivate class Codec {
    func serialize(_ root: Node?) -> String {
    	return root?.serialize() ?? ""
    }
    
    func deserialize(_ data: String) -> Node? {
        guard data != "" else { return nil }
        let data = Array(data)
        var i = 1

        func deserialize(_ i: inout Int) -> Node { 
            var curVal = 0 
            var children = [Node]()
            while i < data.count { 
                let char = data[i]

                if char.isHexDigit { 
                    curVal *= 10
                    curVal += char.hexDigitValue!
                }

                else if char == "[" || char == "," { 
                    i += 1
                    children.append(deserialize(&i))
                    continue
                }

                else if char == "}" { i += 1; break }

                i += 1 
            }

            let node = Node(curVal); node.children = children
            return node
        }
    	
        return deserialize(&i) 
    }
}


//MARK: - Iterative Deserialization
private class IterativeDeserializationCodec {
    func serialize(_ root: Node?) -> String {
        return root?.serialize() ?? ""
    }
    
    func deserialize(_ data: String) -> Node? {
        guard data != "" else { return nil }
        let data = Array(data)

        var curVal = 0
        var nodeStack = [Int](), childrenStack = [[Node]]()
        var curNode: Node!, children = [Node]()
        for char in data {

            if char.isHexDigit {
                curVal *= 10
                curVal += char.hexDigitValue!
            }
            else if char == "{" {
                childrenStack.append(children)
                children = [Node]()
                curVal = 0
            }
            else if char == "[" {
                nodeStack.append(curVal)
                curVal = 0
            }
            else if char == "," {
                children.append(curNode)
            }
            else if char == "]" {
                children.append(curNode)
                curVal = nodeStack.popLast()!
            }
            else if char == "}" {
                curNode = Node(curVal)
                curNode.children = children
                children = childrenStack.popLast()!
                curVal = 0
            }

        }
        
        return curNode
    }
}
