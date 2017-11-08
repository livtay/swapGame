//
//  Array2D.swift
//  CookieCrunch
//
//  Created by Olivia Taylor on 11/7/17.
//  Copyright © 2017 oliviataylor. All rights reserved.
//


struct Array2D<T> {
    let columns: Int
    let rows: Int
    fileprivate var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(repeating: nil, count: rows*columns)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        } set {
            array[row*columns + column] = newValue
        }
    }
}










