//
//  MainAlarmViewController.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 15-2-28.
//  Copyright (c) 2015年 LongGames. All rights reserved.
//

import UIKit

class MainAlarmViewController: UITableViewController {

    var alarmModelController: AlarmModelController!
    var alarmToEdit: Alarm?

    override func viewDidLoad() {
        super.viewDidLoad()
        //self.alarmModelController.alarmScheduler.disableAlarmsIfOutdated()
        tableView.allowsSelectionDuringEditing = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
        //dynamically append the edit button
        if alarmModelController.alarmCount != 0 {
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
        if alarmModelController.alarmCount == 0 {
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        } else {
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        }
        return alarmModelController.alarmCount
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {

            self.alarmToEdit = self.alarmModelController.getAlarmAtTableIndex(index: indexPath.row)
            performSegue(withIdentifier: Identifier.Segue.editAlarm, sender: nil)
        }
    }

    private func obtainAlarmTableCell(tableView: UITableView) -> UITableViewCell {

        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.TableCell.alarm) {
            return cell
        }

        return UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: Identifier.TableCell.alarm)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = self.obtainAlarmTableCell(tableView: tableView)
        guard let alarm = self.alarmModelController.getAlarmAtTableIndex(index: indexPath.row) else {
            return cell
        }

        //cell text
        cell.selectionStyle = .none
        cell.tag = indexPath.row

        let amAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 20.0)]
        let attributedTimeText = NSMutableAttributedString(string: alarm.formattedTime(), attributes: amAttributes)
        let timeAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 45.0)]

        let timeRange = NSRange(location: 0, length: attributedTimeText.length - 2)
        attributedTimeText.addAttributes(timeAttr, range: timeRange)
        cell.textLabel?.attributedText = attributedTimeText
        cell.detailTextLabel?.text = alarm.alarmName
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
            cell.backgroundColor = UIColor.white
            cell.textLabel?.alpha = 1.0
            cell.detailTextLabel?.alpha = 1.0
            uiSwitch.setOn(true, animated: false)
        } else {
            cell.backgroundColor = UIColor.groupTableViewBackground
            cell.textLabel?.alpha = 0.5
            cell.detailTextLabel?.alpha = 0.5
        }
        cell.accessoryView = uiSwitch

        //delete empty separator line
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        return cell
    }

    @IBAction func switchTapped(_ sender: UISwitch) {

        let index = sender.tag

        guard let alarm = self.alarmModelController.getAlarmAtTableIndex(index: index) else {
            print("No alarm to toggle")
            return
        }

        alarm.enabled = sender.isOn

        if sender.isOn {
            print("switch on")
        } else {
            print("switch off")
        }

        tableView.reloadData()

        self.alarmModelController.alarmScheduler.recreateNotificationsFromDataModel()
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

            let index = indexPath.row
            self.alarmModelController.removeAlarmAtIndex(index: index)

            let cells = tableView.visibleCells
            for cell in cells {
                if let uiSwitch = cell.accessoryView as? UISwitch {
                    //adjust saved index when row deleted
                    if uiSwitch.tag > index {
                        uiSwitch.tag -= 1
                    }
                }
            }
            if alarmModelController.alarmCount == 0 {
                self.navigationItem.leftBarButtonItem = nil
            }

            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        guard let navVC = segue.destination as? UINavigationController else {
            print("ERROR: Destination view controller is not a navigation controller")
            return
        }
        guard let alarmAddEditController = navVC.topViewController as? AlarmAddEditViewController else {
            print("ERROR: Destination top view controller is not a AlarmAddEditViewController")
            return
        }

        // inject dependencies
        alarmAddEditController.alarmModelController = self.alarmModelController

        // inject SegueInfo
        if segue.identifier == Identifier.Segue.addAlarm {
            alarmAddEditController.navigationItem.title = "Add Alarm"
            let newAlarm = Alarm()
            alarmAddEditController.segueInfo = SegueInfo(isEditMode: false, alarmToEdit: newAlarm)

        } else if segue.identifier == Identifier.Segue.editAlarm {

            alarmAddEditController.navigationItem.title = "Edit Alarm"
            guard let alarmToEdit = self.alarmToEdit else {
                return
            }
            alarmAddEditController.segueInfo = SegueInfo(isEditMode: true, alarmToEdit: alarmToEdit)
        }
    }

    @IBAction func unwindFromAddEditAlarmView(_ segue: UIStoryboardSegue) {
        isEditing = false
    }

    public func changeSwitchButtonState(index: Int) {

        guard let alarm = self.alarmModelController.getAlarmAtTableIndex(index: index) else {
            return
        }

        if alarm.repeatAtWeekdays.isEmpty {
            alarm.enabled = false
        }
        let cells = tableView.visibleCells
        for cell in cells where cell.tag == index {

            guard let uiSwitch = cell.accessoryView as? UISwitch else {
                continue
            }

            if alarm.repeatAtWeekdays.isEmpty {
                uiSwitch.setOn(false, animated: false)
                cell.backgroundColor = UIColor.groupTableViewBackground
                cell.textLabel?.alpha = 0.5
                cell.detailTextLabel?.alpha = 0.5
            }
        }
    }
}
