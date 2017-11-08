//
//  Level.swift
//  CookieCrunch
//
//  Created by Olivia Taylor on 11/7/17.
//  Copyright © 2017 oliviataylor. All rights reserved.
//

import Foundation
import SpriteKit

let NumColumns = 9
let NumRows = 9
let NumLevels = 4
var matches = [Cookie]()

class Level {
    
    fileprivate var cookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var possibleSwaps = Set<Swap>()
    private var comboMultiplier = 1
    var targetScore = 0
    var maximumMoves = 0
    
    var horizontalArray = [Cookie]()
    var verticalArray = [Cookie]()
    
    init(filename: String) {
        guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: filename) else { return }
        guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
        for (row, rowArray) in tilesArray.enumerated() {
            let tileRow = NumRows - row - 1
            for (column, value) in rowArray.enumerated() {
                if value == 1 {
                    tiles[column, tileRow] = Tile()
                }
            }
        }
        targetScore = dictionary["targetScore"] as! Int
        maximumMoves = dictionary["moves"] as! Int
    }
    
    func tileAt(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    
    func cookieAt(column: Int, row: Int) -> Cookie? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return cookies[column, row]
    }
    
    func shuffle() -> Set<Cookie> {
        var set: Set<Cookie>
        repeat {
            set = createInitialCookies()
            detectPossibleSwaps()
//            print("possible swaps: \(possibleSwaps)")
        } while possibleSwaps.count == 0
        
        return set
    }
    
    func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    var cookieType: CookieType
                    repeat {
                        cookieType = CookieType.random()
                    } while (column >= 2 &&
                        cookies[column - 1, row]?.cookieType == cookieType &&
                        cookies[column - 2, row]?.cookieType == cookieType)
                        || (row >= 2 &&
                            cookies[column, row - 1]?.cookieType == cookieType &&
                            cookies[column, row - 2]?.cookieType == cookieType)
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    set.insert(cookie)
                }
            }
        }
        return set
    }
    
    func performSwap(swap: Swap) {
        let columnA = swap.cookieA.column
        let rowA = swap.cookieA.row
        let columnB = swap.cookieB.column
        let rowB = swap.cookieB.row
        
        cookies[columnA, rowA] = swap.cookieB
        swap.cookieB.column = columnA
        swap.cookieB.row = rowA
        
        cookies[columnB, rowB] = swap.cookieA
        swap.cookieA.column = columnB
        swap.cookieA.row = rowB
    }
    
    func detectPossibleSwaps() -> Int {
        var set = Set<Swap>()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let cookie = cookies[column, row] {
                    // Is it possible to swap this cookie with the one on the right?
                    if column < NumColumns - 1 {
                        // Have a cookie in this spot? If there is no tile, there is no cookie.
                        if let other = cookies[column + 1, row] {
                            // Swap them
                            cookies[column, row] = other
                            cookies[column + 1, row] = cookie
                            var containsSpecialType = false
                            if cookie.cookieType == .bomb || other.cookieType == .bomb {
                                containsSpecialType = true
                            }
                            // Is either cookie now part of a chain?
                            if hasChainAt(column: column + 1, row: row) || hasChainAt(column: column, row: row) || containsSpecialType {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column + 1, row] = other
                        }
                    }
                    if row < NumRows - 1 {
                        if let other = cookies[column, row + 1] {
                            cookies[column, row] = other
                            cookies[column, row + 1] = cookie
                            var containsSpecialType = false
                            if cookie.cookieType == .bomb || other.cookieType == .bomb {
                                containsSpecialType = true
                            }
                            // Is either cookie now part of a chain?
                            if hasChainAt(column: column, row: row + 1) || hasChainAt(column: column, row: row) || containsSpecialType {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column, row + 1] = other
                        }
                    }
                }
            }
        }
        possibleSwaps = set
        return possibleSwaps.count
    }
    
    private func hasChainAt(column: Int, row: Int) -> Bool {
        let cookieType = cookies[column, row]!.cookieType
        // Horizontal chain check
        var horzLength = 1
        // Left
        var i = column - 1
        while i >= 0 && cookies[i, row]?.cookieType == cookieType {
            i -= 1
            horzLength += 1
        }
        // Right
        i = column + 1
        while i < NumColumns && cookies[i, row]?.cookieType == cookieType {
            i += 1
            horzLength += 1
        }
        if horzLength >= 3 { return true }
        // Vertical chain check
        var vertLength = 1
        // Down
        i = row - 1
        while i >= 0 && cookies[column, i]?.cookieType == cookieType {
            i -= 1
            vertLength += 1
        }
        // Up
        i = row + 1
        while i < NumRows && cookies[column, i]?.cookieType == cookieType {
            i += 1
            vertLength += 1
        }
        return vertLength >= 3
    }
    
    func isPossibleSwap(_ swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        horizontalArray = []
        var set = Set<Chain>()
        for row in 0..<NumRows {
            var column = 0
            while column < NumColumns-2 {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    if cookies[column + 1, row]?.cookieType == matchType &&
                        cookies[column + 2, row]?.cookieType == matchType {
                        let chain = Chain(chainType: .horizontal)
                        repeat {
                            chain.add(cookie: cookies[column, row]!)
                            horizontalArray.append(cookies[column, row]!)
                            column += 1
                        } while column < NumColumns && cookies[column, row]?.cookieType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                column += 1
            }
        }
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        verticalArray = []
        var set = Set<Chain>()
        for column in 0..<NumColumns {
            var row = 0
            while row < NumRows-2 {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    if cookies[column, row + 1]?.cookieType == matchType &&
                        cookies[column, row + 2]?.cookieType == matchType {
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.add(cookie: cookies[column, row]!)
                            verticalArray.append(cookies[column, row]!)
                            row += 1
                        } while row < NumRows && cookies[column, row]?.cookieType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                row += 1
            }
        }
        return set
    }
    
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        //compare horizontal array and vertical array
        let horSet = Set(horizontalArray)
        let verSet = Set(verticalArray)
        matches = Array(horSet.intersection(verSet))
        
        removeCookies(chains: horizontalChains)
        removeCookies(chains: verticalChains)
        
        calculateScores(for: horizontalChains)
        calculateScores(for: verticalChains)
        
        return horizontalChains.union(verticalChains)
    }
    
    private func removeCookies(chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                if matches.count > 0 {
                    for linkCookie in matches {
                        if linkCookie.column == cookie.column && linkCookie.row == cookie.row {
                            cookie.cookieType = .bomb
                        } else {
                            cookies[cookie.column, cookie.row] = nil
                        }
                    }
                } else {
                    cookies[cookie.column, cookie.row] = nil
                }
            }
        }
    }
    
    var bombs = [Cookie]()
    var bombCount = 1
    
    func handleBombs(column: Int, row: Int) -> Int {
        bombCount += 1
        bombs = []
        for col in (column - 1)...(column + 1) {
            for r in (row - 1)...(row + 1) {
//                print("*** (\(col), \(r))")
                if col >= 0 && r >= 0 && col <= 8 && r <= 8 {
                    if tiles[col, r] != nil && cookies[col, r] != nil {
                        let cookie = cookies[col, r]
                        if let sprite = cookie?.sprite {
                            if sprite.action(forKey: "removing") == nil {
                                let scaleAction = SKAction.scale(to: 0, duration: 1.0)
                                scaleAction.timingMode = .easeOut
                                sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                                           withKey:"removing")
                            }
                        }
                        if cookie?.cookieType == .bomb {
                            bombs.append(cookie!)
                        }
                        cookies[col, r] = nil
                    }
                }
            }
        }
        for bomb in bombs {
            _ = handleBombs(column: bomb.column, row: bomb.row)
        }
        return bombCount
    }
    
    func fillHoles() -> [[Cookie]] {
        var columns = [[Cookie]]()
        for column in 0..<NumColumns {
            var array = [Cookie]()
            for row in 0..<NumRows {
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    for lookup in (row + 1)..<NumRows {
                        if let cookie = cookies[column, lookup] {
                            cookies[column, lookup] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            array.append(cookie)
                            break
                        }
                    }
                }
            }
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpCookies() -> [[Cookie]] {
        var columns = [[Cookie]]()
        var cookieType: CookieType = .unknown
        
        for column in 0..<NumColumns {
            var array = [Cookie]()
            var row = NumRows - 1
            while row >= 0 && cookies[column, row] == nil {
                if tiles[column, row] != nil {
                    var newCookieType: CookieType
                    repeat {
                        newCookieType = CookieType.random()
                    } while newCookieType == cookieType
                    cookieType = newCookieType
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    array.append(cookie)
                }
                
                row -= 1
            }
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    private func calculateScores(for chains: Set<Chain>) {
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            comboMultiplier += 1
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
    
}

















