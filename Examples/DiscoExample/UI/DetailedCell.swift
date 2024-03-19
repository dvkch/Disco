//
//  DetailedCell.swift
//  DiscoExample
//
//  Created by syan on 19/06/2023.
//

import UIKit

class DetailedCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
