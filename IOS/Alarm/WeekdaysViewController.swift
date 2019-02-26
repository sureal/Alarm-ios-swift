//
//  WeekdaysViewController.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 15/10/15.
//  Copyright (c) 2015年 LongGames. All rights reserved.
//

import UIKit

class WeekdaysViewController: UITableViewController {

    var weekdays: [Int]!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        performSegue(withIdentifier: AlarmAppIdentifiers.weekdaysUnwindIdentifier, sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        for weekday in weekdays where weekday == (indexPath.row + 1) {

            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!

        if let index = weekdays.index(of: (indexPath.row + 1)) {
            weekdays.remove(at: index)
            cell.setSelected(true, animated: true)
            cell.setSelected(false, animated: true)
            cell.accessoryType = UITableViewCell.AccessoryType.none
        } else {
            //row index start from 0, weekdays index start from 1 (Sunday), so plus 1
            weekdays.append(indexPath.row + 1)
            cell.setSelected(true, animated: true)
            cell.setSelected(false, animated: true)
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark

        }
    }
}
