//
//  AlarmAddViewController.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 15-3-2.
//  Copyright (c) 2015年 LongGames. All rights reserved.
//

import UIKit
import Foundation
import MediaPlayer

class AlarmAddEditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var tableView: UITableView!

    var alarmScheduler: AlarmScheduler!
    var alarmModelController: AlarmModelController!

    var segueInfo: SegueInfo!
    var alarmToEdit: Alarm!

    override func viewDidLoad() {
        
        if self.segueInfo.isEditMode {
            self.alarmToEdit = self.segueInfo.alarmToEdit
        } else {
            self.alarmToEdit = Alarm()
        }
        
        self.datePicker.date = self.alarmToEdit.alertDate
        
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {

        // update view from alarm to be edited
        self.tableView.reloadData()

        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func saveAlarm(_ sender: UIBarButtonItem) {

        self.alarmToEdit.alertDate = datePicker.date.toSecondsRoundedDate()
        self.alarmToEdit.enabled = true
        self.alarmToEdit.onSnooze = false

        if !self.segueInfo.isEditMode {
            self.alarmModelController.addAlarm(alarm: self.alarmToEdit)
        } else {
            self.alarmModelController.persist()
        }
        
        self.performSegue(withIdentifier: Identifier.UnwindSegue.saveAddEditAlarm, sender: self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        if self.segueInfo.isEditMode {
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
            return 1
        }
    }

    func obtainTableViewCell() -> UITableViewCell {

        if let cell = self.tableView.dequeueReusableCell(withIdentifier: Identifier.TableCell.setting) {
            return cell
        }
        return UITableViewCell(
            style: UITableViewCell.CellStyle.value1,
            reuseIdentifier: Identifier.TableCell.setting)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = self.obtainTableViewCell()

        if indexPath.section == 0 {

            if indexPath.row == 0 {

                cell.textLabel!.text = "Repeat"
                cell.detailTextLabel?.text = self.repeatText(weekdays: self.alarmToEdit.repeatAtWeekdays)
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator

            } else if indexPath.row == 1 {

                cell.textLabel!.text = "Label"
                cell.detailTextLabel?.text = self.alarmToEdit.alarmName
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator

            } else if indexPath.row == 2 {

                cell.textLabel!.text = "Sound"
                cell.detailTextLabel?.text = self.alarmToEdit.mediaLabel
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator

            } else if indexPath.row == 3 {

                cell.textLabel?.text = "Snooze"
                let uiSwitch = UISwitch(frame: CGRect())
                uiSwitch.addTarget(
                        self,
                        action: #selector(AlarmAddEditViewController.snoozeSwitchTapped(_:)),
                        for: UIControl.Event.touchUpInside)

                if self.alarmToEdit.snoozeEnabled {
                    uiSwitch.setOn(true, animated: false)
                }

                cell.accessoryView = uiSwitch
            }
        } else if indexPath.section == 1 {

            cell = UITableViewCell(
                    style: UITableViewCell.CellStyle.default, reuseIdentifier: Identifier.TableCell.setting)
            cell.textLabel!.text = "Delete Alarm"
            cell.textLabel!.textAlignment = .center
            cell.textLabel!.textColor = UIColor.red
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = self.tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: Identifier.Segue.setWeekdaysRepeating, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            case 1:
                performSegue(withIdentifier: Identifier.Segue.editAlarmName, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            case 2:
                performSegue(withIdentifier: Identifier.Segue.setAlarmSound, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            default:
                break
            }
        } else if indexPath.section == 1 {
            //delete alarm
            self.alarmModelController.removeAlarm(alarm: self.alarmToEdit)
            performSegue(withIdentifier: Identifier.Segue.saveAddEditAlarm, sender: self)
        }

    }

    @IBAction func snoozeSwitchTapped(_ uiSwitch: UISwitch) {
        self.alarmToEdit.snoozeEnabled = uiSwitch.isOn
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == Identifier.Segue.saveAddEditAlarm {

            if let destinationViewController = segue.destination as? MainAlarmViewController {

                let cells = destinationViewController.tableView.visibleCells
                for cell in cells {
                    if let uiSwitch = cell.accessoryView as? UISwitch {
                        if uiSwitch.tag > self.alarmToEdit.indexInTable {
                            uiSwitch.tag -= 1
                        }
                    }
                }
                alarmScheduler.recreateNotificationsFromDataModel()
            }

        } else if segue.identifier == Identifier.Segue.setAlarmSound {

            if let destinationViewController = segue.destination as? AlarmSoundEditViewController {

                destinationViewController.mediaID = self.alarmToEdit.mediaID
                destinationViewController.mediaLabel = self.alarmToEdit.mediaLabel
            }

        } else if segue.identifier == Identifier.Segue.editAlarmName {

            if let destinationViewController = segue.destination as? AlarmNameEditViewController {

                destinationViewController.alarmNameToDisplay = self.alarmToEdit.alarmName
            }

        } else if segue.identifier == Identifier.Segue.setWeekdaysRepeating {

            if let destinationViewController = segue.destination as? WeekdaysViewController {

                destinationViewController.weekdays = self.alarmToEdit.repeatAtWeekdays
            }
        }
    }

    @IBAction func unwindFromAlarmNameEditViewController(_ segue: UIStoryboardSegue) {

        if let sourceViewController = segue.source as? AlarmNameEditViewController {

            self.alarmToEdit.alarmName = sourceViewController.getAlarmName()
        }
    }

    @IBAction func unwindFromWeekdaysViewController(_ segue: UIStoryboardSegue) {

        if let sourceViewController = segue.source as? WeekdaysViewController {

            self.alarmToEdit.repeatAtWeekdays = sourceViewController.weekdays
        }
    }

    @IBAction func unwindFromAlarmSoundEditViewController(_ segue: UIStoryboardSegue) {

        if let sourceViewController = segue.source as? AlarmSoundEditViewController {

            self.alarmToEdit.mediaLabel = sourceViewController.mediaLabel
            self.alarmToEdit.mediaID = sourceViewController.mediaID
        }
    }

    private func repeatText(weekdays: [Int]) -> String {
        if weekdays.count == 7 {
            return "Every day"
        }

        if weekdays.isEmpty {
            return "Never"
        }

        var ret = String()
        var weekdaysSorted: [Int] = [Int]()

        weekdaysSorted = weekdays.sorted(by: <)

        for day in weekdaysSorted {
            switch day {
            case 1:
                ret += "Sun "
            case 2:
                ret += "Mon "
            case 3:
                ret += "Tue "
            case 4:
                ret += "Wed "
            case 5:
                ret += "Thu "
            case 6:
                ret += "Fri "
            case 7:
                ret += "Sat "
            default:
                //throw
                break
            }
        }
        return ret
    }
}
