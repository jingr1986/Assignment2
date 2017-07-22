//
//  CVDate.swift
//  CVCalendar
//
//  Created by Мак-ПК on 12/31/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

class CVDate: NSObject {
    private let date: NSDate?
    let year: Int?
    let month: Int?
    let week: Int?
    let day: Int?
    let date2: NSDate?
  
    init(date: NSDate) {
        super.init()
        
        let calendarManager = CVCalendarManager.sharedManager
        
        self.date = date
        self.date2 = date
        self.year = calendarManager.dateRange(date).year
        self.month = calendarManager.dateRange(date).month
        self.day = calendarManager.dateRange(date).day
    }
    
    init(day: Int, month: Int, week: Int, year: Int) {
        super.init()
    
        self.year = year
        self.month = month
        self.week = week
        self.day = day
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.date2 = dateFormatter.dateFromString("\(year)-\(month)-\(day) 00:00:00")
    }
    
    func description() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        let month = dateFormatter.stringFromDate(self.date!)
        
        return "\(month), \(self.year!)"
    }
  
}
