//
//  AddEventTableViewController.swift
//  assignment2IPE
//
//  Created by vichaya sunsern on 20/05/2015.
//  Copyright (c) 2015 RMIT. All rights reserved.
//

import UIKit
import EventKitUI
import EventKit
import AVFoundation

import Alamofire
import SwiftyJSON

class AddEventTableViewController: UITableViewController, EKEventEditViewDelegate{
  let synth = AVSpeechSynthesizer()
  var myUtterance = AVSpeechUtterance(string: "")
  var eventStore : EKEventStore!
  
  // Default calendar associated with the above event store
  var defaultCalendar:EKCalendar!
  
  // Array of all events happening within the next 24 hours
  var  selectedDate:NSDate!
  var  selectedDateString:String!
  var  eventsList:NSMutableArray!
  var  eventsList2:[EKEvent]!
  var  eventsListFromDB:[EventModel]!
  var  startDayForSection : [String] = []
  let defaults = NSUserDefaults.standardUserDefaults()
  var token = ""
  var eventView = EKEventEditViewController()
  @IBOutlet weak var addButton: UIBarButtonItem!
  
  // Used to add events to Calendar
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.eventStore = EKEventStore()
    self.eventsList = NSMutableArray()
    self.addButton.enabled = true
    self.eventsList2 = []
    self.eventsListFromDB = [];
    //self.readEvents()
    self.checkEventStoreAccessForCalendar()
    
    if let t = defaults.stringForKey("token") {
      token = t
    }
    
    
    
    //      var alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertControllerStyle.Alert)
    //      alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
    //        switch action.style{
    //        case .Default:
    //          println("default")
    //        case .Cancel:
    //          println("cancel")
    //
    //        case .Destructive:
    //          println("destructive")
    //        }
    //      }))
    //      self.presentViewController(alert, animated: true, completion: nil)
    //      //self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelAddEvent"), animated: true)
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
  }
  
  override func  viewDidAppear(animated: Bool) {
    
    self.tableView.reloadData()
    //Syndata with the Gmail
   // println(eventView.isBeingPresented())
   // println("Insert data To DB1")
    if(eventView.event != nil && eventView.event.title != nil){
      //println("Insert data To DB2")
      self.speak("You have created \(eventView.event.title) event")
      self.postEventsToGoogleCalendar(eventView.event)
    }
    self.speak(self.createStringForAccessibility())
  }
  
  
  
  
  
  //  @IBAction func unwindCalendarSegue(sender: UIStoryboardSegue) {
  //    if sender.identifier == "idunwindCalendarSegue" {
  //      println("asds")
  //    }
  //    if let calendarController = sender.sourceViewController as? CalendarViewController {
  //      println("Coming from BLUE")
  //    }else if let redViewController = sender.sourceViewController as? AddEventTableViewController {
  //      println("Coming from RED")
  //    }
  //    println("asds")
  //    self.performSegueWithIdentifier("idunwindCalendarSegue", sender: self)
  //  }
  
  
  @IBAction func addEvent(sender: AnyObject) {
    
    if(eventView.isViewLoaded()){
     
      eventView = EKEventEditViewController()
    }
    
    eventView.eventStore = self.eventStore
    eventView.editViewDelegate = self
    self.presentViewController(eventView, animated: true, completion:nil)
  }
  
  func eventEditViewController(controller: EKEventEditViewController!,
    didCompleteWithAction action: EKEventEditViewAction){
      var test : AddEventTableViewController = self
    
      test.dismissViewControllerAnimated(true, completion: {
        if( action.value != EKEventEditViewActionCanceled.value){
          dispatch_async(dispatch_get_main_queue(), {
            // Re-fetch all events happening in the next 24 hours
            test.eventsList2 = self.fetchEvents()
            
            self.createEventModelList()
            self.eventsListFromDB = self.createEventModelList()
            // Update the UI with the above events
            test.tableView.reloadData()
          })
        }
      })
      
  }
  
  func eventEditViewControllerDefaultCalendarForNewEvents(var controller : EKEventEditViewController!) -> EKCalendar
  {
    return self.eventStore.defaultCalendarForNewEvents
  }
  
  func handler(granted: Bool, error: NSError!) {
    // put your handler code here
    if(granted){
      let view: AddEventTableViewController = self
      //dispatch_async(dispatch_get_main_queue())
      let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
      dispatch_async(dispatch_get_global_queue(priority, 0)) {
        // do some task
        dispatch_async(dispatch_get_main_queue()) {
          // update some UI
          view.accessGrantedForCalendar()
        }
      }
      
      //      dispatch_async(dispatch_get_main_queue()) {
      //        view.accessGrantedForCalendar()
      //      }
      //dispatch_async(dispatch_get_main_queue(),view.accessGrantedForCalendar())
    }
  }
  
  // Prompt the user for access to their Calendar
  func requestCalendarAccess()
  {
    self.eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: handler)
  }
  
  
  // This method is called when the user has granted permission to Calendar
  func accessGrantedForCalendar()->Void
  {
    // Let's get the default calendar associated with our event store
    self.defaultCalendar = self.eventStore.defaultCalendarForNewEvents
    // Enable the Add button
    self.addButton.enabled = true
    // Fetch all events happening in the next 24 hours and put them into eventsList
    self.eventsList2 = self.fetchEvents()
    self.eventsListFromDB = self.createEventModelList()
    // Update the UI with the above events
    self.tableView.reloadData()
    //[self.tableView reloadData];
  }
  
  func createEventModelList()->[EventModel]!{
    
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateFormatter2 = NSDateFormatter()
    dateFormatter2.dateFormat = "yyyy-MM-dd"
    let dateFormatter3 = NSDateFormatter()
    dateFormatter3.dateFormat = "EEEE-dd-MMM-yyyy"
    var eventModelList:[EventModel] = []
    var db = SQLiteConnection()
    db.createEventsTable();
    //var results:FMResultSet = db.selectAllEvents()selectedDate
    var results:FMResultSet = db.searchByStartDate(dateFormatter2.stringFromDate(selectedDate))
    while results.next(){
      var eventID = results.stringForColumn("GOOGLEID")
      var startDate = dateFormatter.dateFromString(results.stringForColumn("STARTDATE"))
      var model = EventModel(title: results.stringForColumn("Title"), startDate: startDate!, endDate: dateFormatter.dateFromString(results.stringForColumn("ENDDATE"))!)
      model.setEventID(eventID)
      eventModelList.append(model)
      
      
      var startDateArr = split(results.stringForColumn("STARTDATE")) {$0 == " "}
      if self.startDayForSection.count == 0{
        self.startDayForSection.append(self.selectedDateString)
      }
//      else{
//        let total = self.startDayForSection.count
//        var i = 0 ;
//        //var isSame
//        for date in self.startDayForSection{
//          i++
//          var tmpDate = split(date) {$0 == " "}
//          if tmpDate[0] == startDateArr[0]{
//            break;
//          }else if i == total && tmpDate[0] != startDateArr[0]{
//            let tempDate = split(dateFormatter3.stringFromDate(startDate!)){$0 == "-"}
//            self.startDayForSection.append("\(tempDate[0]), \(tempDate[1]) \(tempDate[2]) \(tempDate[3])")
//            }
//          
//        }
//      }
      
    }
    db.closeConnection()
    
    return eventModelList
  }
  
  func createStringForAccessibility()->String{
      var str = ""
    if(self.eventsListFromDB.count == 0){
      str = "You don't have the events on \(self.selectedDateString)"
    }else{
      str = "You have \(self.eventsListFromDB.count) events on \(self.selectedDateString). "
      for tmpEvent in self.eventsListFromDB{
        str += "\(tmpEvent.title) event";
      }
    }
    
    return str
  }
  
  func speak(str:String){
    self.myUtterance = AVSpeechUtterance(string: str)
    self.myUtterance.rate = 0.1
    self.synth.speakUtterance(self.myUtterance)
  }
  
  // Fetch all events happening in the next 24 hours
  func fetchEvents()-> [EKEvent]!
  {
    
    
    var startDate =  NSDate()
    
    
    //Create the end date components
    var tomorrowDateComponents = NSDateComponents()
    tomorrowDateComponents.day = 1
    
    var endDate =  NSCalendar.currentCalendar().dateByAddingComponents(tomorrowDateComponents, toDate: startDate, options: NSCalendarOptions(0))
    
    // We will only search the default calendar for our events
    // Obj-C using NSArray arraywithobject
    
    var calendarArray  = [self.eventStore.defaultCalendarForNewEvents]
    
    
    // Create the predicate
    var predicate:NSPredicate = self.eventStore.predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: calendarArray)
    //ReadDataFrom DB
    
    // Fetch all events that match the predicate
    
    //events = self.eventStore.eventsMatchingPredicate(predicate) as [AnyObject]! as NSMutableArray
    //let events = NSMutableArray(array: self.eventStore.eventsMatchingPredicate(predicate)!)
    
    var events = self.eventStore.eventsMatchingPredicate(predicate) as [EKEvent]!
    //var events :NSMutableArray!
    if events == nil{
      events = []
    }
    
    self.createEventModelList()
    
    //    for var event:EKEvent! in events2 {
    //      println("events = \(event.title)")
    //
    //    }
    ////
    //      let events = NSMutableArray(array: self.eventStore.eventsMatchingPredicate(predicate) as [EKEvent])
    //    if events.count > 0{
    //      println(events.count)
    //      for event in self.eventsList2{
    //        println(" title \(event.title)")
    //      }
    //    }
    
    return events;
  }
  
  
  // Check the authorization status of our application for Calendar
  func checkEventStoreAccessForCalendar()
  {
    
    var status : EKAuthorizationStatus = EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent)
    switch (status)
    {
      // Update our UI if the user has granted access to their Calendar
    case .Authorized:
      self.accessGrantedForCalendar()
      break
      // Prompt the user for access to Calendar if there is no definitive answer
    case .NotDetermined:
      self.requestCalendarAccess()
      break
      // Display a message if the user has denied or restricted access to Calendar
    case .Denied:
      var alert = UIAlertController(title: "Privacy Warning", message: "Permission was not granted for Calendar",preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      break
    default:
      break
    }
  }
  
  func postEventsToGoogleCalendar(event:EKEvent!)->Bool{
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"
   
    var isPosted = false
    let url = "https://www.googleapis.com/calendar/v3/calendars/primary/events?access_token=" + token
    print("url = \(url)")
    if(event != nil ){
      let parameters : Dictionary<String, AnyObject> = [
        "summary": event.title,
        "location": event.location,
        "start": [ "dateTime": dateFormatter.stringFromDate(event.startDate) ],
        "end": [ "dateTime": dateFormatter.stringFromDate(event.endDate) ],
        "attendees": []
      ]
      
      println("Title Event \(event.title)")
      Alamofire.request(.POST, url, parameters: parameters, encoding: .JSON)
        .responseJSON { (req, res, json, error) in
          if(error != nil) {
            NSLog("Error: \(error)")
          } else {
            var j = JSON(json!)
            println(j["id"].stringValue)
            println(j["organizer"]["email"])
            var eventModel = EventModel(eventID:j["id"].stringValue, title: event.title, startDate: event.startDate, endDate: event.endDate)
            
            eventModel.setLocation(event.location)
            var db = SQLiteConnection()
            db.createEventsTable();
            db.insertEvent(eventModel)
            self.eventsListFromDB = self.createEventModelList()
            self.tableView.reloadData()

            var results:FMResultSet = db.selectAllEvents()
            if results.next() == true {
              println("Found record")
              let id = results.stringForColumn("GOOGLEID")
              println("Google Id = \(id)")
            }
            db.closeConnection()

          }
      }
      isPosted = true
    }
    
    return isPosted
  }
  
  
  // MARK: - Table view data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
  // #warning Potentially incomplete method implementation.
  // Return the number of sections.
  return self.startDayForSection.count
  }

  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return self.startDayForSection[section]
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete method implementation.
    // Return the number of rows in the section.
    
    //return self.eventsList2.count
    return self.eventsListFromDB.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    
    // Configure the cell...
    let cell = tableView.dequeueReusableCellWithIdentifier("eventCell", forIndexPath: indexPath) as UITableViewCell
    
    //cell.textLabel!.text = self.eventsList2[indexPath.row].title
    cell.textLabel!.text = self.eventsListFromDB[indexPath.row].title
    
    return cell
  }
  
  
  /*
  // Override to support conditional editing of the table view.
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
  // Return NO if you do not want the specified item to be editable.
  return true
  }
  */
  
  /*
  // Override to support editing the table view.
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
  if editingStyle == .Delete {
  // Delete the row from the data source
  tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
  } else if editingStyle == .Insert {
  // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
  }
  }
  */
  
  /*
  // Override to support rearranging the table view.
  override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
  
  }
  */
  
  /*
  // Override to support conditional rearranging of the table view.
  override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
  // Return NO if you do not want the item to be re-orderable.
  return true
  }
  */
  
  
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "Invite" {
      //var DesView = segue.destinationViewController as UIViewController
      var DesView = segue.destinationViewController as EventDetailController
      let eventIndex = tableView.indexPathForSelectedRow()?.row
      DesView.eventID = self.eventsListFromDB[eventIndex!].eventID
    }
  }
  
}