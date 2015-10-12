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
    var startOfToday: NSDate!
    var startOfYesterday: NSDate!
    var now: NSDate!
    
    var goal: Int = 10 {
        // Whenever goal is set:
        //   Update progress bar (percent of green on screen)
        //   Updates the label stating steps left until goal is reached
        //   Save the new goal value into the user defaults
        willSet {
            self.progressValue = CGFloat(self.todaySteps) / CGFloat(newValue)
            
            self.goalLabel.text = "\(newValue) steps"
            self.updateUntilGoalLabel()
            
            self.goalStepper.value = Double(newValue)
            self.standardUserDefaults.setInteger(newValue, forKey: "goal")
            self.standardUserDefaults.synchronize()
        }
    }
    
    var todaySteps: Int = 0 {
        // Whenever todaySteps is set:
        //   Update progress bar (percent of green on screen)
        willSet {
            self.progressValue = CGFloat(newValue) / CGFloat(self.goal)
        }
    }
    
    var progressValue: CGFloat = 0.0 {
        // Whenever the progressValue is going to be set:
        //   Change the UI for the progress bar (percent of green on screen)
        willSet {
            dispatch_async(dispatch_get_main_queue()) {
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadUserDefaults()
        
        updateTimeValues()
        
        // If the activity manager is available, get the current user activity
        if CMMotionActivityManager.isActivityAvailable() {
            self.activityManager.startActivityUpdatesToQueue(NSOperationQueue())
                { (activity) -> Void in
                    if let activity = activity {
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
        }
            
        // If pedometer is available, get steps taken today
        if CMPedometer.isStepCountingAvailable(){
            pedometer.startPedometerUpdatesFromDate(self.startOfToday)
                { (pedData, error) -> Void in
                    if pedData != nil && error == nil {
                        self.todaySteps = Int(pedData!.numberOfSteps)
                        
                        // Update label with today's steps and update steps until goal reached
                        dispatch_async(dispatch_get_main_queue()) {
                            self.todayLabel.text = "\(pedData!.numberOfSteps) steps"
                            self.updateUntilGoalLabel()
                        }
                    }
            }
        }
        
        // If pedometer is available, get steps taken yesterday
        if CMPedometer.isStepCountingAvailable() {
            self.pedometer.queryPedometerDataFromDate(self.startOfYesterday, toDate: startOfToday)
                { (pedData, error) -> Void in
                    if pedData != nil && error == nil {
                        // Update label for yesterday's steps
                        dispatch_async(dispatch_get_main_queue()) {
                            self.yesterdayLabel.text = "\(pedData!.numberOfSteps) steps"
                        }
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
    
    func loadUserDefaults() {
        // Retrieve value for goal from user defaults
        var goal = self.standardUserDefaults.integerForKey("goal")
        if (goal == 0) {
            goal = 10
        }
        self.goal = goal
    }

    // Get NSDate objects for midnight today, midnight yesterday, and right now
    func updateTimeValues() {
        let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        cal?.timeZone = NSTimeZone.systemTimeZone()
        let comp = cal?.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: NSDate())
        comp?.minute = 0
        comp?.hour = 0
        
        self.startOfToday = cal?.dateFromComponents(comp!)
        self.startOfYesterday = startOfToday.dateByAddingTimeInterval(-60*60*24)
        self.now = NSDate()
    }
    
    // Calculate the steps left to take before the goal is reached
    func updateUntilGoalLabel() {
        let goalDiff = self.goal - Int(self.todaySteps)
        
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

