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
    @IBOutlet weak var playGameButton: UIBarButtonItem!
    @IBOutlet weak var goalStepper: UIStepper!
    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    
    var goal: Int = 0 {
        didSet {
            self.goalLabel.text = "Goal: \(self.goal) steps"
            self.updateUntilGoalLabel()
            self.goalStepper.value = Double(self.goal)
        }
    }
    var todaySteps: Int = 0
    var startOfToday: NSDate? = nil
    var startOfYesterday: NSDate? = nil
    var now: NSDate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
        self.goal = standardUserDefaults.integerForKey("goal") ?? 10
        
        updateTimeValues()
        
        if CMMotionActivityManager.isActivityAvailable() {
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
        
        if CMPedometer.isStepCountingAvailable(){
            pedometer.startPedometerUpdatesFromDate(self.startOfToday)
                { (pedData: CMPedometerData!, error:NSError!) -> Void in
                    self.todaySteps = Int(pedData.numberOfSteps)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.todayLabel.text = "\(pedData.numberOfSteps) steps"
                        self.updateUntilGoalLabel()
                    }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        updateTimeValues()
        
        if CMPedometer.isStepCountingAvailable() {
            self.pedometer.queryPedometerDataFromDate(self.startOfYesterday, toDate: self.startOfToday)
                { (pedData: CMPedometerData!, error: NSError!) -> Void in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.yesterdayLabel.text = "\(pedData.numberOfSteps) steps"
                    }
            }

        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if CMMotionActivityManager.isActivityAvailable() {
            self.activityManager.stopActivityUpdates()
        }
        if CMPedometer.isStepCountingAvailable() {
            self.pedometer.stopPedometerUpdates()
        }
        
        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
        standardUserDefaults.setInteger(self.goal, forKey: "goal")
        standardUserDefaults.synchronize()
        
        super.viewWillDisappear(animated)
    }

    func updateTimeValues() {
        var cal = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        cal?.timeZone = NSTimeZone.systemTimeZone()
        var comp = cal?.components(.YearCalendarUnit | .MonthCalendarUnit | .DayCalendarUnit | .HourCalendarUnit | .MinuteCalendarUnit, fromDate: NSDate())
        comp?.minute = 0
        comp?.hour = 0
        
        self.startOfToday = cal?.dateFromComponents(comp!)
        self.startOfYesterday = startOfToday?.dateByAddingTimeInterval(-60*60*24)
        self.now = NSDate()
    }
    
    func updateUntilGoalLabel() {
        var goalDiff = self.goal - Int(self.todaySteps)
        if (goalDiff > 0) {
            self.untilGoalLabel.text = "\(goalDiff) steps"
            self.playGameButton.enabled = false
        } else {
            self.untilGoalLabel.text = "Goal Reached!"
            self.playGameButton.enabled = true
        }
    }
    
    @IBAction func stepperChanged(sender: UIStepper) {
        self.goal = Int(sender.value)
    }

}

