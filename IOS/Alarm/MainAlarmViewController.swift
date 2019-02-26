//
//  MainAlarmViewController.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 15-2-28.
//  Copyright (c) 2015年 LongGames. All rights reserved.
//

import UIKit

class MainAlarmViewController: UITableViewController {

    var alarmScheduler = AlarmScheduler()
    var alarmModel: AlarmModel = AlarmModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        alarmScheduler.checkNotification()
        tableView.allowsSelectionDuringEditing = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        alarmModel = AlarmModel()
        tableView.reloadData()
        //dynamically append the edit button
        if alarmModel.alarmCount != 0 {
            self.navigationItem.leftBarButtonItem = editButtonItem
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if alarmModel.alarmCount == 0 {
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        } else {
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        }
        return alarmModel.alarmCount
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            let sender = SegueInfo(curCellIndex: indexPath.row,
                    isEditMode: true, label: alarmModel.alarms[indexPath.row].label,
                    mediaLabel: alarmModel.alarms[indexPath.row].mediaLabel,
                    mediaID: alarmModel.alarms[indexPath.row].mediaID,
                    repeatWeekdays: alarmModel.alarms[indexPath.row].repeatWeekdays,
                    enabled: alarmModel.alarms[indexPath.row].enabled,
                    snoozeEnabled: alarmModel.alarms[indexPath.row].snoozeEnabled)

            performSegue(withIdentifier: AlarmAppIdentifiers.editSegueIdentifier, sender: sender)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: AlarmAppIdentifiers.alarmCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(
                    style: UITableViewCell.CellStyle.subtitle,
                    reuseIdentifier: AlarmAppIdentifiers.alarmCellIdentifier)
        }

        //cell text
        cell!.selectionStyle = .none
        cell!.tag = indexPath.row
        let alarm: Alarm = alarmModel.alarms[indexPath.row]
        let amAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 20.0)]
        let attributedTimeText = NSMutableAttributedString(string: alarm.formattedTime(), attributes: amAttributes)
        let timeAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 45.0)]

        let timeRange = NSRange(location: 0, length: attributedTimeText.length - 2)
        attributedTimeText.addAttributes(timeAttr, range: timeRange)
        cell!.textLabel?.attributedText = attributedTimeText
        cell!.detailTextLabel?.text = alarm.label
        //append switch button
        let uiSwitch = UISwitch(frame: CGRect())
        uiSwitch.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        //tag is used to indicate which row had been touched
        uiSwitch.tag = indexPath.row
        uiSwitch.addTarget(
                self,
                action: #selector(MainAlarmViewController.switchTapped(_:)),
                for: UIControl.Event.valueChanged)

        if alarm.enabled {
            cell!.backgroundColor = UIColor.white
            cell!.textLabel?.alpha = 1.0
            cell!.detailTextLabel?.alpha = 1.0
            uiSwitch.setOn(true, animated: false)
        } else {
            cell!.backgroundColor = UIColor.groupTableViewBackground
            cell!.textLabel?.alpha = 0.5
            cell!.detailTextLabel?.alpha = 0.5
        }
        cell!.accessoryView = uiSwitch

        //delete empty seperator line
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        return cell!
    }

    @IBAction func switchTapped(_ sender: UISwitch) {
        let index = sender.tag
        alarmModel.alarms[index].enabled = sender.isOn
        if sender.isOn {
            print("switch on")
            alarmScheduler.setNotificationWithDate(alarmModel.alarms[index].date,
                    onWeekdaysForNotify: alarmModel.alarms[index].repeatWeekdays,
                    snoozeEnabled: alarmModel.alarms[index].snoozeEnabled,
                    onSnooze: false, soundName: alarmModel.alarms[index].mediaLabel,
                    index: index)

            tableView.reloadData()
        } else {
            print("switch off")
            alarmScheduler.recreateNotificationsFromDataModel()
            tableView.reloadData()
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            let index = indexPath.row
            alarmModel.alarms.remove(at: index)
            let cells = tableView.visibleCells
            for cell in cells {
                if let uiSwitch = cell.accessoryView as? UISwitch {
                    //adjust saved index when row deleted
                    if uiSwitch.tag > index {
                        uiSwitch.tag -= 1
                    }
                }
            }
            if alarmModel.alarmCount == 0 {
                self.navigationItem.leftBarButtonItem = nil
            }

            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            alarmScheduler.recreateNotificationsFromDataModel()
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        guard let destinationViewController = segue.destination as? UINavigationController else {
            print("ERROR: Destination view controller is not a navigation controller")
            return
        }
        guard let addEditController = destinationViewController.topViewController as? AlarmAddEditViewController else {
            print("ERROR: Destination top view controller is not a AlarmAddEditViewController")
            return
        }

        if segue.identifier == AlarmAppIdentifiers.addSegueIdentifier {
            addEditController.navigationItem.title = "Add Alarm"
            addEditController.segueInfo = SegueInfo(curCellIndex: alarmModel.alarmCount,
                    isEditMode: false, label: "Alarm", mediaLabel: "bell", mediaID: "",
                    repeatWeekdays: [], enabled: false, snoozeEnabled: false)

        } else if segue.identifier == AlarmAppIdentifiers.editSegueIdentifier {
            addEditController.navigationItem.title = "Edit Alarm"

            if let segueInfo = sender as? SegueInfo {
                addEditController.segueInfo = segueInfo
            } else {
                print("SHIT!")
            }
        }
    }

    @IBAction func unwindFromAddEditAlarmView(_ segue: UIStoryboardSegue) {
        isEditing = false
    }

    public func changeSwitchButtonState(index: Int) {
        //let info = notification.userInfo as! [String: AnyObject]
        //let index: Int = info["index"] as! Int
        alarmModel = AlarmModel()
        if alarmModel.alarms[index].repeatWeekdays.isEmpty {
            alarmModel.alarms[index].enabled = false
        }
        let cells = tableView.visibleCells
        for cell in cells where cell.tag == index {

            if let uiSwitch = cell.accessoryView as? UISwitch {
                if alarmModel.alarms[index].repeatWeekdays.isEmpty {
                    uiSwitch.setOn(false, animated: false)
                    cell.backgroundColor = UIColor.groupTableViewBackground
                    cell.textLabel?.alpha = 0.5
                    cell.detailTextLabel?.alpha = 0.5
                }
            }
        }
    }

}
