//  Jordan Kayse, Jessica Yeh, Story Zanetti
//  ViewController.swift
//  JSJAssignment3
//
//  Created by ch484-mac7 on 2/25/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    // Outlets
    @IBOutlet weak var yesterdayLabel: UILabel!
    @IBOutlet weak var todayLabel: UILabel!
    @IBOutlet weak var untilGoalLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var playGameButton: UIBarButtonItem!
    @IBOutlet weak var goalStepper: UIStepper!
    @IBOutlet weak var progress: UIView!
    @IBOutlet weak var progressHeight: NSLayoutConstraint!
    
    // Initialize variables
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let standardUserDefaults = NSUserDefaults.standardUserDefaults()
    var startOfToday: NSDate? = nil
    var startOfYesterday: NSDate? = nil
    var now: NSDate? = nil
    
    var goal: Int = 10 {
        // Whenever goal is set:
        //   Update progress bar (percent of green on screen)
        //   Updates the label stating steps left until goal is reached
        //   Save the new goal value into the user defaults
        didSet {
            self.progressValue = CGFloat(self.todaySteps) / CGFloat(self.goal)
            
            self.goalLabel.text = "\(self.goal) steps"
            self.updateUntilGoalLabel()
            
            self.goalStepper.value = Double(self.goal)
            self.standardUserDefaults.setInteger(self.goal, forKey: "goal")
            self.standardUserDefaults.synchronize()
        }
    }
    
    var todaySteps: Int = 0 {
        // Whenever todaySteps is set:
        //   Update progress bar (percent of green on screen)
        didSet {
            self.progressValue = CGFloat(self.todaySteps) / CGFloat(self.goal)
        }
    }
    
    var progressValue: CGFloat = 0.0 {
        // Whenever the progressValue is going to be set:
        //   Change the UI for the progress bar (percent of green on screen)
        willSet {
            if (newValue >= 0) {
                self.view.removeConstraint(self.progressHeight)
                self.progressHeight = NSLayoutConstraint(
                    item: self.progress,
                    attribute: .Height,
                    relatedBy: .Equal,
                    toItem: self.view,
                    attribute: .Height,
                    multiplier: newValue,
                    constant: 0
                )
                self.view.addConstraint(self.progressHeight)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Retrieve value for goal from user defaults
        self.goal = self.standardUserDefaults.integerForKey("goal") ?? 10
        
        updateTimeValues()
        
        // If the activity manager is available, get the current user activity
        if CMMotionActivityManager.isActivityAvailable() {
            self.activityManager.startActivityUpdatesToQueue(NSOperationQueue())
                { (activity:CMMotionActivity!) -> Void in
                    // Update label for user activity on UI
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
        
        // If pedometer is available, get steps taken today
        if CMPedometer.isStepCountingAvailable(){
            pedometer.startPedometerUpdatesFromDate(self.startOfToday)
                { (pedData: CMPedometerData!, error:NSError!) -> Void in
                    self.todaySteps = Int(pedData.numberOfSteps)
                    println(self.todaySteps)
                    
                    // Update label with today's steps and update steps until goal reached
                    dispatch_async(dispatch_get_main_queue()) {
                        self.todayLabel.text = "\(pedData.numberOfSteps) steps"
                        self.updateUntilGoalLabel()
                    }
            }
        }
        
        // If pedometer is available, get steps taken yesterday
        if CMPedometer.isStepCountingAvailable() {
            self.pedometer.queryPedometerDataFromDate(self.startOfYesterday, toDate: self.startOfToday)
                { (pedData: CMPedometerData!, error: NSError!) -> Void in
                    // Update label for yesterday's steps
                    dispatch_async(dispatch_get_main_queue()) {
                        self.yesterdayLabel.text = "\(pedData.numberOfSteps) steps"
                    }
            }

        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        // Stop activity managers
        if CMMotionActivityManager.isActivityAvailable() {
            self.activityManager.stopActivityUpdates()
        }
        if CMPedometer.isStepCountingAvailable() {
            self.pedometer.stopPedometerUpdates()
        }
        
        super.viewWillDisappear(animated)
    }

    // Get NSDate objects for midnight today, midnight yesterday, and right now
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
    
    // Calculate the steps left to take before the goal is reached
    func updateUntilGoalLabel() {
        var goalDiff = self.goal - Int(self.todaySteps)
        
        // If the goal has not been surpassed, update the label with the number
        // Otherwise, change the label to "Goal reached!"
        if (goalDiff > 0) {
            self.untilGoalLabel.text = "\(goalDiff) steps until goal"
            self.playGameButton.enabled = false
        } else {
            self.untilGoalLabel.text = "Goal reached!"
            self.playGameButton.enabled = true
        }
    }
    
    // Every time the stepper is changed, update the goal
    @IBAction func stepperChanged(sender: UIStepper) {
        self.goal = Int(sender.value)
    }

}

