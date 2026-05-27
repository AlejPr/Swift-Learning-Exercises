import Collections

class Excel {

    private var mat = [[ExcelEntry]]()
    private var graph = [SumFunction: Set<SumFunction>]()

    init(_ height: Int, _ width: Character) {
        self.mat = Array(repeating: Array(repeating: 0, count: Int(width.asciiValue!) - 65 + 1), count: height)
    }
    
    func set(_ row: Int, _ column: Character, _ val: Int) {
        let cell = Cell(row, column)
        if let oldFunc = mat[cell.row][cell.col] as? SumFunction { removeFromGraph(oldFunc) }
        mat[cell.row][cell.col] = val
        recalculateSums(for: cell)
    }
    
    func get(_ row: Int, _ column: Character) -> Int {
        let cell = Cell(row, column)
        return mat[cell.row][cell.col].intValue
    }
    
    func sum(_ row: Int, _ column: Character, _ numbers: [String]) -> Int {
        let cell = Cell(row, column)
        let newFunc = SumFunction(cell, numbers)
        mat[cell.row][cell.col] = newFunc
        appendToGraph(newFunc)
        recalculateSums(for: cell)
        return newFunc.intValue
    }

    private func appendToGraph(_ newFunc: SumFunction) {
        graph[newFunc] = Set<SumFunction>()
        for node in graph.keys where newFunc.isChild(of: node) {
            graph[newFunc]!.insert(node)
        }
    }
    
    private func removeFromGraph(_ oldFunc: SumFunction) {
        for node in graph where node.value.contains(oldFunc) {
            graph[node.key]?.remove(oldFunc)
        }
        graph.removeValue(forKey: oldFunc)
    }

    //topological sort
    //cell is unused, entire graph is recalculated
    private func recalculateSums(for cell: Cell) {
        guard !graph.isEmpty else { return }

        var inDegree = graph.reduce(into: [SumFunction: Int]()) { r, p in r[p.key] = p.value.count }
        var queue = inDegree.reduce(into: Deque<SumFunction>()) { r, p in
            if p.value == 0 { r.append(p.key) }
        }

        while let first = queue.popFirst() {
            first.calculateSum(with: mat)
            
            for node in graph where node.value.contains(first) {
                inDegree[node.key]! -= 1
                if inDegree[node.key] == 0 {
                    queue.append(node.key)
                    inDegree.removeValue(forKey: node.key)
                }
            }
        }
        
    }

}


private class SumFunction: ExcelEntry, Hashable {
    var intValue: Int = 0
    var location: Cell
    var cells: [[Cell]]
    init(_ location: Cell, _ cells: [String]) {
        self.location = location
        self.cells = Self.formattedCells(cells)
    }

    static func formattedCells(_ cells: [String]) -> [[Cell]] {
        return cells.reduce(into: [[Cell]]()) { r, p in
            let split = p.split(separator: ":")
            if split.count == 1 {
                r.append([Cell(split[0])])
            } else {
                r.append([Cell(split[0]), Cell(split[1])])
            }
        }
    }

    func calculateSum(with mat: [[ExcelEntry]]) {
        var res = 0
        for value in cells {
            if value.count == 1 {
                let cell = value[0]
                res += mat[cell.row][cell.col].intValue
            }
            else { res += Self.scan(mat, value[0], value[1]) }
        }
        self.intValue = res
    }

    private static func scan(_ mat: [[ExcelEntry]], _ topLeft: Cell,_ bottomRight: Cell) -> Int {
        var res = 0
        for row in topLeft.row...bottomRight.row {
            for col in topLeft.col...bottomRight.col {
                res += mat[row][col].intValue
            }
        }
        return res
    }
    
    func isChild(of parentNode: SumFunction) -> Bool {
        for cells in parentNode.cells {
            if self.location == cells[0] { return true }
            guard cells.count == 2 else { continue }
            let topLeft = cells[0], bottomRight = cells[1]
            if (topLeft.row <= location.row && bottomRight.row >= location.row) && (topLeft.col <= location.col && bottomRight.col >= location.col) { return true }
        }
        return false
    }

    static func == (lhs: SumFunction, rhs: SumFunction) -> Bool {
        return lhs.location == rhs.location
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }

}


protocol ExcelEntry {
    var intValue: Int { get }
}

extension Int: ExcelEntry {
    var intValue: Int { return self }
}

struct Cell: Hashable {
    let row: Int
    let col: Int
    
    init(_ row: Int,_ col: Character) {
        self.row = row - 1
        self.col = Int(col.asciiValue!) - 65
    }
    
    init(_ s: String.SubSequence) {
        self.row = s[s.index(after: s.startIndex)].hexDigitValue! - 1
        self.col = Int(s[s.startIndex].asciiValue!) - 65
    }
    
}

