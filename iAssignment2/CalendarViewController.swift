//
//  CalendarViewController.swift
//  assignment2IPE
//
//  Created by vichaya sunsern on 20/05/2015.
//  Copyright (c) 2015 RMIT. All rights reserved.
//

import UIKit
import EventKit

import Alamofire
import SwiftyJSON

class CalendarViewController: UIViewController, CVCalendarViewDelegate  {
  
  @IBOutlet weak var calendarView: CVCalendarView!
  @IBOutlet weak var menuView: CVCalendarMenuView!
  @IBOutlet weak var monthLabel: UILabel!
  var  firstLoaded: Bool!
  var calendar: EKCalendar!
  var shouldShowDaysOut = true
  var animationFinished = true
  var eventStore : EKEventStore!
  var selectedDate : NSDate!
  
  //  required init(coder aDecoder: NSCoder) {
  //    fatalError("init(coder:) has not been implemented")
  //  }
  
  @IBAction func synceCalendar(sender: AnyObject) {
    //Read events from google calendar
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var token = ""
    if let t = defaults.stringForKey("token") {
      token = t
    }
    var url = "https://www.googleapis.com/calendar/v3/calendars/primary/events?access_token=" + token
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.ZZZZZ"
    Alamofire.request(.GET, url)
      .responseJSON { (req, res, json, error) in
        if(error != nil) {
          
          println(token)
          NSLog("Error: \(error)")
        } else {
          
          var j = JSON(json!)
          var isError = false
          if(j["error"] != nil){
            println(j["error"])
            isError = true;
            self.loginToGoogle()
            self.synceCalendar(sender)
          }else{
          var id = "", title = "", location = ""
          var attendees = [""]
          var startDate:NSDate!,  endDate:NSDate!
          var model:EventModel!
          let db = SQLiteConnection()
          db.dropTable()
          db.createEventsTable()
          for items in j["items"]{
            
            id = items.1["id"].stringValue
            title = items.1["summary"].stringValue
            location = items.1["location"].stringValue
            //let title = items.1["summary"]
            startDate = dateFormatter.dateFromString(items.1["start"]["dateTime"].stringValue)
            endDate = dateFormatter.dateFromString(items.1["end"]["dateTime"].stringValue)
            for attendee in items.1["attendees"]{
              if attendee.1 != nil{
                attendees.append(attendee.1["email"].stringValue)
              }
            }
            
            var model = EventModel(eventID: id, title: title, startDate: startDate, endDate: endDate)
            model.setLocation(location)
            model.setAttendees(attendees)
            
            db.insertEvent(model)
          }
            if isError != true{
              var alert = UIAlertController(title: "Sync Events", message: "Complete sync all events from google calendar",preferredStyle: UIAlertControllerStyle.Alert)
              // alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
              var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                UIAlertAction in
                self.viewDidLoad()
                self.viewDidAppear(true)
                self.calendarView.toggleTodayMonthView()
                self.calendarView.setNeedsDisplay()
                NSLog("OK Pressed")
                //self.viewDidLoad()
                //self.viewDidAppear(true)
              }
              
              alert.addAction(okAction)
              self.presentViewController(alert, animated: true, completion: nil)
            }
            
         }
        }
    }
    //self.calendarView.commitCalendarViewUpdate()
    //self.menuView.commitMenuViewUpdate()
  }
  
  func loginToGoogle(){
      var eventView = GoogleAPI()
      self.presentViewController(eventView, animated: true, completion:nil)
      self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.hasProblemWithLogin()
    self.eventStore = EKEventStore()
    firstLoaded = true
    switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent){
      
    case .Authorized:
      extractEventEntityCalendarsOutOfStore(eventStore)
    case .Denied:
      displayAccessDenied()
    case .NotDetermined:
      eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion:
        {[weak self] (granted: Bool, error: NSError!) -> Void in
          if granted{
            //self!.extractEventEntityCalendarsOutOfStore(self.eventStore)
          } else {
            self!.displayAccessDenied()
          }
      })
    case .Restricted:
      displayAccessRestricted()
    }
    
    
    let calendars =
    self.eventStore.calendarsForEntityType(EKEntityTypeReminder)
    
    for calendar in calendars as [EKCalendar] {
      println("Calendar = \(calendar.title)")
    }
   
    self.monthLabel.text = CVDate(date: NSDate()).description()
  }
  
  
  func hasProblemWithLogin()->Bool{
    let defaults = NSUserDefaults.standardUserDefaults()
    var token = ""
    if let t = defaults.stringForKey("token") {
      token = t
    }
    var isError = false;
    var url = "https://www.googleapis.com/calendar/v3/calendars/primary/events?access_token=" + token
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"
    
    
    
    var req = Alamofire.request(.GET, url)
      .responseJSON { (req, res, json, error) in
        if(error != nil) {
          NSLog("Error: \(error)")
        } else {
          println(" res = \(res)")
          let result = JSON(json!)
          println(result["error"]["code"].stringValue == "403")
          println(result["error"] == nil)
          
          if(result["error"] != nil){
            self.loginToGoogle()
            
          }
          println("Error = \(isError)")
        }
    }
    println("TTT \(req.description)")
    println("asd \(isError)")
    return isError
    
  }

  
  func extractEventEntityCalendarsOutOfStore(eventStore: EKEventStore){
    
    let calendarTypes = [
      "Local",
      "CalDAV",
      "Exchange",
      "Subscription",
      "Birthday",
    ]
    
    self.calendar = eventStore.defaultCalendarForNewEvents
    
    
    
  }
  
 
  
  func displayAccessDenied(){
    println("Access to the event store is denied.")
  }
  
  func displayAccessRestricted(){
    println("Access to the event store is restricted.")
  }
  
  
  typealias EKEventStoreRequestAccessCompletionHandler = (Bool, NSError!) -> Void
  
  @IBAction func cancelToCalendarViewController(segue:UIStoryboardSegue) {
    
    
  }
  
  @IBAction func saveEventDetail(segue:UIStoryboardSegue) {
  
    
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
   
    self.calendarView.commitCalendarViewUpdate()
    self.menuView.commitMenuViewUpdate()
  }
  
  @IBAction func todayMonthView() {
    
    println("todayMonthView Function")
    self.calendarView.toggleTodayMonthView()
  }
  
  // MARK: Calendar View Delegate
  
  func shouldShowWeekdaysOut() -> Bool {
   
    return self.shouldShowDaysOut
  }
  
  func didSelectDayView(dayView: CVCalendarDayView) {
    
    if (!firstLoaded){
      self.selectedDate = dayView.date?.date2
      self.performSegueWithIdentifier("showEventList", sender: self)
    }
    // TODO:
  }
  
  func dotMarker(colorOnDayView dayView: CVCalendarDayView) -> UIColor {
   
    if self.hasEventsFromDB(dayView.date?.date2 as NSDate!) {
      return .blueColor()
    }
    return .whiteColor()
  }
  
  func dotMarker(shouldShowOnDayView dayView: CVCalendarDayView) -> Bool {

    
    if self.hasEventsFromDB(dayView.date?.date2 as NSDate!) {
      return true
    } else {
      return false
    }
  }
  
  func dotMarker(shouldMoveOnHighlightingOnDayView dayView: CVCalendarDayView) -> Bool {
    
    return false
  }
  
  func topMarker(shouldDisplayOnDayView dayView: CVCalendarDayView) -> Bool {
    //To protect calling the Events List segue
    if (dayView.isCurrentDay == true && firstLoaded == true){
      firstLoaded = false
    }
    return true
  }

  
  // Fetch all events happening in the next 24 hours
  func hasEvents(startDate : NSDate!)-> Bool
  {
    
    
    self.extractEventEntityCalendarsOutOfStore(self.eventStore)
    var calendarArray  = [self.eventStore.defaultCalendarForNewEvents as EKCalendar?]
    var hasEvents = false;
    
    if(startDate != nil){
      let dateFormatter = NSDateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
    //Create the end date components
    var tomorrowDateComponents = NSDateComponents()
    tomorrowDateComponents.day = 1
    
    var endDate =  NSCalendar.currentCalendar().dateByAddingComponents(tomorrowDateComponents, toDate: startDate, options: NSCalendarOptions(0))
    
    // We will only search the default calendar for our events
    // Obj-C using NSArray arraywithobject
    
    // Create the predicate
    var predicate:NSPredicate = eventStore.predicateForEventsWithStartDate(startDate!, endDate: endDate!, calendars: calendarArray as [EKCalendar!])
    
    
    var events = eventStore.eventsMatchingPredicate(predicate) as [EKEvent]!
    //var events :NSMutableArray!
    if events != nil{
      hasEvents = true;
    }
    
    }
    return hasEvents;
  }
  
  // Fetch all events happening in the next 24 hours
  func hasEventsFromDB(startDate : NSDate!)-> Bool
  {
    
    
    self.extractEventEntityCalendarsOutOfStore(self.eventStore)
    var calendarArray  = [self.eventStore.defaultCalendarForNewEvents as EKCalendar?]
    var hasEvents = false;
    
    if(startDate != nil){
      
      let dateFormatter = NSDateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      var eventModelList:[EventModel] = []
      var db = SQLiteConnection()
      db.createEventsTable();
      var results:FMResultSet = db.searchByStartDate(dateFormatter.stringFromDate(startDate))
      if results.next(){
        hasEvents = true;
      }
      db.closeConnection()
      
    }
    return hasEvents;
  }


  
  
  func presentedDateUpdated(date: CVDate) {
    if self.monthLabel.text != date.description() && self.animationFinished {
      let updatedMonthLabel = UILabel()
      updatedMonthLabel.textColor = monthLabel.textColor
      updatedMonthLabel.font = monthLabel.font
      updatedMonthLabel.textAlignment = .Center
      updatedMonthLabel.text = date.description
      updatedMonthLabel.sizeToFit()
      updatedMonthLabel.alpha = 0
      updatedMonthLabel.center = self.monthLabel.center
      
      
      let offset = CGFloat(48)
      updatedMonthLabel.transform = CGAffineTransformMakeTranslation(0, offset)
      updatedMonthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
      
      UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
        self.animationFinished = false
        self.monthLabel.transform = CGAffineTransformMakeTranslation(0, -offset)
        self.monthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
        self.monthLabel.alpha = 0
        
        updatedMonthLabel.alpha = 1
        updatedMonthLabel.transform = CGAffineTransformIdentity
        
        }) { (finished) -> Void in
          self.animationFinished = true
          self.monthLabel.frame = updatedMonthLabel.frame
          self.monthLabel.text = updatedMonthLabel.text
          self.monthLabel.transform = CGAffineTransformIdentity
          self.monthLabel.alpha = 1
          updatedMonthLabel.removeFromSuperview()
      }
      println("presentedDateUpdated Function")
      self.view.insertSubview(updatedMonthLabel, aboveSubview: self.monthLabel)
    }
  }
  
  func toggleMonthViewWithMonthOffset(offset: Int) {
    let calendar = NSCalendar.currentCalendar()
    let calendarManager = CVCalendarManager.sharedManager
    let components = calendarManager.componentsForDate(NSDate()) // from today
    
    components.month += offset
    
    let resultDate = calendar.dateFromComponents(components)!
    println("toggleMonthViewWithMonthOffset Function")
    self.calendarView.toggleMonthViewWithDate(resultDate)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showEventList"{
      let addEventTableController = segue.destinationViewController as AddEventTableViewController
      addEventTableController.navigationItem.title = "Event List"
      
      let dateFormatter3 = NSDateFormatter()
      dateFormatter3.dateFormat = "EEEE-dd-MMM-yyyy"
      let tempDate = split(dateFormatter3.stringFromDate(self.selectedDate!)){$0 == "-"}
      addEventTableController.selectedDateString = "\(tempDate[0]), \(tempDate[1]) \(tempDate[2]) \(tempDate[3])"
      addEventTableController.selectedDate = self.selectedDate
      println(self.selectedDate)
    }
  }
  
}