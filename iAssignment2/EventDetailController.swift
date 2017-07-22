
//EventDetailController.swift
//Assignment1
//
//Created by Ryan Jing on 25/05/2015.
//    Copyright (c) 2015 RMIT. All rights reserved.


import UIKit
import MapKit
import EventKitUI
import EventKit
import Alamofire
import SwiftyJSON

class EventDetailController: UIViewController,UITextFieldDelegate{
    
    var emailAdd = ""
    var eventID = ""
    let db = SQLiteConnection()
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var token = ""
    
    var location = ""
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var attendeesLabel: UILabel!
    
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let t = defaults.stringForKey("token") {
            token = t
        }
        email.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        loadData()
    }
    
    func loadData() {
      println(eventID)
        var ret : FMResultSet = db.searchByID(eventID)
        while ret.next(){
            titleLabel.text = ret.stringForColumn("TITLE")
            startLabel.text = ret.stringForColumn("STARTDATE")
            endLabel.text = ret.stringForColumn("ENDDATE")
            attendeesLabel.text = ret.stringForColumn("ATTENDEES")
            location = ret.stringForColumn("LOCATION")
             db.closeConnection()
            let geocoder = CLGeocoder()
            println("Location = \(location)")
            geocoder.geocodeAddressString(location, completionHandler: { (placemarkers, error) -> Void in
                let top : CLPlacemark = placemarkers[0] as CLPlacemark
                let placemark: MKPlacemark = MKPlacemark(placemark: top)
                let span = MKCoordinateSpanMake(0.01, 0.01)
                let region = MKCoordinateRegion(center: placemark.location.coordinate, span: span)
                self.map.setRegion(region, animated: true)
                self.map.addAnnotation(placemark)
                self.map.zoomEnabled = true
            })
        }
    }
    
    @IBAction func invite(sender: AnyObject) {
        
        emailAdd = email.text
        
        var url = "https:www.googleapis.com/calendar/v3/calendars/primary/events/\(self.eventID)?access_token=\(self.token)"
        
        var att = [Dictionary<String, String>]()
        
        Alamofire.request(.GET, url)
            .responseJSON { (req, res, json, error) in
                if(error != nil) {
                    NSLog("Error: \(error)")
                } else {
                    var j = JSON(json!)
                    for a in j["attendees"].arrayValue {
                        att.append(["email": a["email"].stringValue])
                    }
                    
                    att.append(["email": self.emailAdd])
                    
                    var url = "https:www.googleapis.com/calendar/v3/calendars/primary/events/\(self.eventID)?alwaysIncludeEmail=true&maxAttendees=50&sendNotifications=true&access_token=\(self.token)"
                    let parameters : Dictionary<String, AnyObject> = [
                        "attendees": att
                    ]
                    
                    Alamofire.request(.PATCH, url, parameters: parameters, encoding: .JSON)
                        .responseJSON { (req, res, json, error) in
                            if(error != nil) {
                                NSLog("Error: \(error)")
                            } else {
                                var j = JSON(json!)
                                println(j)
                                var eventModel = EventModel(eventID: self.eventID, title: self.titleLabel.text!, startDate: self.startLabel.text!, endDate: self.endLabel.text!)
                                eventModel.setLocation(self.location)
                                
                                var emails = Array<String>()
                                for a in att {
                                    emails.append(a["email"]!)
                                }
                                eventModel.setAttendees(emails);
                                
                                self.db.update(eventModel)
                                self.loadData()
                            }
                    }
                    
                }
        }
    }
    
    @IBAction func DeleteEvent(sender: AnyObject) {
        
        var url = "https:www.googleapis.com/calendar/v3/calendars/primary/events/\(self.eventID)?access_token=\(self.token)&sendNotifications=true"
        
        Alamofire.request(.DELETE, url, encoding: .JSON)
            .responseJSON { (req, res, json, error) in
                if(error != nil) {
                    NSLog("Error: \(error)")
                } else {
                    self.db.deleteByGoogleId(self.eventID)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
//        Dispose of any resources that can be recreated.
    }
    
}

 