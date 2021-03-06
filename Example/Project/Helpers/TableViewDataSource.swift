//
//  TableViewDataSource.swift
//  Example
//
//  Created by Magnus Eriksson on 15/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit

class TableViewDataSource<Element, Cell: UITableViewCell>: NSObject, UITableViewDataSource {
    
    typealias ConfigureCellBlock = (Cell, Element) -> ()
    
    var elements: [Element] = []
    let templateCell: Cell
    let configureCell: ConfigureCellBlock
    
    
    init(elements: [Element], templateCell: Cell, configureCell: @escaping ConfigureCellBlock) {
        assert(templateCell.reuseIdentifier != nil, "Template cell must have a reuse identifier")
        self.templateCell = templateCell
        self.configureCell = configureCell
        self.elements = elements
        super.init()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return elements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: templateCell.reuseIdentifier!) as! Cell
        let element = elements[indexPath.row]
        configureCell(cell, element)
        return cell
    }
}
