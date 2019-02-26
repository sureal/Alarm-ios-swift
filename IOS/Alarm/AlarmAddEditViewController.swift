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

    var alarmScheduler = AlarmScheduler()
    var alarmModel: AlarmModel = AlarmModel()
    var segueInfo: SegueInfo!
    var snoozeEnabled: Bool = false
    var enabled: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        alarmModel = AlarmModel()
        tableView.reloadData()
        snoozeEnabled = segueInfo.snoozeEnabled
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func saveEditAlarm(_ sender: AnyObject) {

        let date = datePicker.date.toSecondsRoundedDate()
        let index = segueInfo.curCellIndex
        var tempAlarm = Alarm()
        tempAlarm.date = date
        tempAlarm.label = segueInfo.label
        tempAlarm.enabled = true
        tempAlarm.mediaLabel = segueInfo.mediaLabel
        tempAlarm.mediaID = segueInfo.mediaID
        tempAlarm.snoozeEnabled = snoozeEnabled
        tempAlarm.repeatWeekdays = segueInfo.repeatWeekdays
        tempAlarm.uuid = UUID().uuidString
        tempAlarm.onSnooze = false
        if segueInfo.isEditMode {
            alarmModel.alarms[index] = tempAlarm
        } else {
            alarmModel.alarms.append(tempAlarm)
        }
        self.performSegue(withIdentifier: AlarmAppIdentifiers.saveSegueIdentifier, sender: self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        if segueInfo.isEditMode {
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: AlarmAppIdentifiers.settingIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1,
                    reuseIdentifier: AlarmAppIdentifiers.settingIdentifier)
        }
        if indexPath.section == 0 {

            if indexPath.row == 0 {

                cell!.textLabel!.text = "Repeat"
                cell!.detailTextLabel!.text = self.repeatText(weekdays: segueInfo.repeatWeekdays)
                cell!.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            } else if indexPath.row == 1 {
                cell!.textLabel!.text = "Label"
                cell!.detailTextLabel!.text = segueInfo.label
                cell!.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            } else if indexPath.row == 2 {
                cell!.textLabel!.text = "Sound"
                cell!.detailTextLabel!.text = segueInfo.mediaLabel
                cell!.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            } else if indexPath.row == 3 {

                cell!.textLabel!.text = "Snooze"
                let uiSwitch = UISwitch(frame: CGRect())
                uiSwitch.addTarget(self,
                        action: #selector(AlarmAddEditViewController.snoozeSwitchTapped(_:)),
                        for: UIControl.Event.touchUpInside)

                if snoozeEnabled {
                    uiSwitch.setOn(true, animated: false)
                }

                cell!.accessoryView = uiSwitch
            }
        } else if indexPath.section == 1 {
            cell = UITableViewCell(
                    style: UITableViewCell.CellStyle.default, reuseIdentifier: AlarmAppIdentifiers.settingIdentifier)
            cell!.textLabel!.text = "Delete Alarm"
            cell!.textLabel!.textAlignment = .center
            cell!.textLabel!.textColor = UIColor.red
        }

        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: AlarmAppIdentifiers.weekdaysSegueIdentifier, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            case 1:
                performSegue(withIdentifier: AlarmAppIdentifiers.labelSegueIdentifier, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            case 2:
                performSegue(withIdentifier: AlarmAppIdentifiers.soundSegueIdentifier, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            default:
                break
            }
        } else if indexPath.section == 1 {
            //delete alarm
            alarmModel.alarms.remove(at: segueInfo.curCellIndex)
            performSegue(withIdentifier: AlarmAppIdentifiers.saveSegueIdentifier, sender: self)
        }

    }

    @IBAction func snoozeSwitchTapped(_ sender: UISwitch) {
        snoozeEnabled = sender.isOn
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == AlarmAppIdentifiers.saveSegueIdentifier {

            if let destinationViewController = segue.destination as? MainAlarmViewController {

                let cells = destinationViewController.tableView.visibleCells
                for cell in cells {
                    if let uiSwitch = cell.accessoryView as? UISwitch {
                        if uiSwitch.tag > segueInfo.curCellIndex {
                            uiSwitch.tag -= 1
                        }
                    }
                }
                alarmScheduler.recreateNotificationsFromDataModel()
            }

        } else if segue.identifier == AlarmAppIdentifiers.soundSegueIdentifier {

            if let destinationViewController = segue.destination as? MediaViewController {

                destinationViewController.mediaID = segueInfo.mediaID
                destinationViewController.mediaLabel = segueInfo.mediaLabel
            }

        } else if segue.identifier == AlarmAppIdentifiers.labelSegueIdentifier {
            if let destinationViewController = segue.destination as? LabelEditViewController {

                destinationViewController.label = segueInfo.label
            }

        } else if segue.identifier == AlarmAppIdentifiers.weekdaysSegueIdentifier {
            if let destinationViewController = segue.destination as? WeekdaysViewController {

                destinationViewController.weekdays = segueInfo.repeatWeekdays
            }
        }
    }

    @IBAction func unwindFromLabelEditView(_ segue: UIStoryboardSegue) {
        if let sourceViewController = segue.source as? LabelEditViewController {
            segueInfo.label = sourceViewController.label
        }
    }

    @IBAction func unwindFromWeekdaysView(_ segue: UIStoryboardSegue) {
        if let sourceViewController = segue.source as? WeekdaysViewController {
            segueInfo.repeatWeekdays = sourceViewController.weekdays
        }
    }

    @IBAction func unwindFromMediaView(_ segue: UIStoryboardSegue) {
        if let sourceViewController = segue.source as? MediaViewController {
            segueInfo.mediaLabel = sourceViewController.mediaLabel
            segueInfo.mediaID = sourceViewController.mediaID
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
