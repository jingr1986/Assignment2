//
//  EventModel.swift
//  Assignment1
//
//  Created by vichaya sunsern on 26/05/2015.
//  Copyright (c) 2015 RMIT. All rights reserved.
//

import Foundation

class EventModel:NSObject {
  
  var eventID:String!
  var title:String!
  var location:String!
  var allDay: Int!
  var startDate: String!
  var endDate: String!
  var NSstartDate: NSDate!
  var NSendDate: NSDate!
  var url: String!
  var note: String!
  var attendees: [String]! = Array<String>()
  let dateFormatter = NSDateFormatter()
  
  init(title: String, startDate:NSDate, endDate: NSDate){
    super.init()
    
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    self.title = title
    self.startDate = dateFormatter.stringFromDate(startDate)
    self.endDate = dateFormatter.stringFromDate(endDate)
    self.NSstartDate = startDate
    self.NSendDate = endDate
    self.allDay = 0
    self.url = ""
    self.note=""
  }
  
  init(eventID:String, title: String, startDate:NSDate, endDate: NSDate){
    super.init()
    
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    self.eventID = eventID
    self.title = title
    self.startDate = dateFormatter.stringFromDate(startDate)
    self.endDate = dateFormatter.stringFromDate(endDate)
    self.NSstartDate = startDate
    self.NSendDate = endDate
    self.allDay = 0
    self.url = ""
    self.note=""
  }
  
  
  
  init(eventID:String, title: String, startDate: String, endDate: String){
    super.init()
    
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    self.eventID = eventID
    self.title = title
    self.startDate = startDate
    self.endDate = endDate
    self.allDay = 0
    self.url = ""
    self.note=""
  }
  
  func setEventID(eventID:String){
    self.eventID = eventID
  }
  
  func setAllDay(isAllDay:Int){
    self.allDay = isAllDay
  }
  
  func setLocation(location:String){
    self.location = location
  }
  
  func setUrl(url:String){
    self.url = url
  }
  
  func setNote(note:String){
    self.note = note
  }
  
  func setAttendees(attendees:[String]?){
    self.attendees = attendees
  }
  
  func getAttendeesString() -> String {
    if self.attendees.count > 0 {
      return ",".join(self.attendees)
    } else {
      return ""
    }
  }

  
}
