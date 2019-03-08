//
//  labelEditViewController.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 15/10/21.
//  Copyright (c) 2015年 LongGames. All rights reserved.
//

import UIKit

class AlarmNameEditViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var labelTextField: UITextField!
    var alarmNameToDisplay: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.labelTextField.becomeFirstResponder()
        // Do any additional setup after loading the view.
        self.labelTextField.delegate = self
        
        self.labelTextField.text = self.alarmNameToDisplay
        
        //defined in UITextInputTraits protocol
        self.labelTextField.returnKeyType = UIReturnKeyType.done
        self.labelTextField.enablesReturnKeyAutomatically = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getAlarmName() -> String {
        guard let alarmName = self.labelTextField.text else {
            return ""
        }
        return alarmName
    }

}
