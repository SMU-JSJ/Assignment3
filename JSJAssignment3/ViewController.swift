//
//  ViewController.swift
//  JSJAssignment3
//
//  Created by ch484-mac7 on 2/25/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var yesterdayLabel: UILabel!
    @IBOutlet weak var todayLabel: UILabel!
    @IBOutlet weak var untilGoalLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    
    @IBOutlet weak var debugLabel: UILabel!
    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    
    var goal: Int = 0
    var yesterdaySteps = 0.0
    var todaySteps = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
        goal = standardUserDefaults.integerForKey("goal")
        
        var cal = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        cal?.timeZone = NSTimeZone.systemTimeZone()
        var comp = cal?.components(.YearCalendarUnit | .MonthCalendarUnit | .DayCalendarUnit | .HourCalendarUnit | .MinuteCalendarUnit, fromDate: NSDate())
        comp?.minute = 0
        comp?.hour = 0
        
        let startOfToday = cal?.dateFromComponents(comp!)
        let startOfYesterday = startOfToday?.dateByAddingTimeInterval(-60*60*24)
        let now = NSDate()
        
        self.pedometer.queryPedometerDataFromDate(startOfYesterday, toDate: startOfToday)
            { (pedData: CMPedometerData!, error: NSError!) -> Void in
                dispatch_async(dispatch_get_main_queue()){
                    self.yesterdayLabel.text = "\(pedData.numberOfSteps) steps"
            }
        }
        
        if CMMotionActivityManager.isActivityAvailable(){
            self.activityManager.startActivityUpdatesToQueue(NSOperationQueue())
                { (activity:CMMotionActivity!) -> Void in
                    dispatch_async(dispatch_get_main_queue()){
                        if (activity.walking) {
                            self.activityLabel.text = "Walking"
                        } else if (activity.running) {
                            self.activityLabel.text = "Running"
                        } else if (activity.cycling) {
                            self.activityLabel.text = "Cycling"
                        } else if (activity.automotive && activity.stationary) {
                            self.activityLabel.text = "Stationary in a Car"
                        } else if (activity.automotive) {
                            self.activityLabel.text = "Moving in a Car"
                        } else {
                            self.activityLabel.text = "Stationary"
                        }
                    }
            }
        }
    }

    @IBAction func stepperChanged(sender: UIStepper) {
        goal = Int(sender.value)
        self.goalLabel.text = "Goal: \(goal) steps"
    }

}

