//
//  SQLiteConnection.swift
//  Assignment1
//
//  Created by vichaya sunsern on 26/05/2015.
//  Copyright (c) 2015 RMIT. All rights reserved.
//

import Foundation

class SQLiteConnection{
  
  private let fileMgr: NSFileManager!
  private let dirPaths:[String]!
  private let docsDir: String!
  private let dbPath: String!
  private var connectDB:FMDatabase!
  
  init(){
    
    self.fileMgr  = NSFileManager.defaultManager()
    self.dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true) as [String]
    self.docsDir  = self.dirPaths[0]
    self.dbPath   = self.docsDir.stringByAppendingPathComponent("event.db")
  }
  
  func isDBExists()->Bool{
    return self.fileMgr.fileExistsAtPath(dbPath)
  }
  
  func createConnection(){
    
    self.connectDB = FMDatabase(path: self.dbPath as String)
    if(!isDBExists()){
      if self.connectDB == nil{
         println("Error: \(self.connectDB.lastErrorMessage())")
      }
    }
  }
  
  func createEventsTable(){
   
    self.createConnection()
    if self.connectDB.open(){
      let query = "CREATE TABLE IF NOT EXISTS EVENTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, GOOGLEID TEXT, TITLE TEXT, LOCATION TEXT, ALLDAY INTEGER, STARTDATE TEXT, ENDDATE TEXT, URL TEXT, NOTE TEXT, ATTENDEES TEXT)"
      if !self.connectDB.executeStatements(query){
        println("Error: \(self.connectDB.lastErrorMessage())")
      }
      self.connectDB.close()
    }else{
      println("Error: \(self.connectDB.lastErrorMessage())")
    }
  }
  
  
  func insertEvent(event:EventModel){
    NSLog("Insert event to event table")
    self.createConnection()
    if self.connectDB.open(){
      let insertSQL = "INSERT INTO EVENTS (GOOGLEID, TITLE, LOCATION, ALLDAY, STARTDATE, ENDDATE, URL, NOTE, ATTENDEES) VALUES ('\(event.eventID)','\(event.title)', '\(event.location)', \(event.allDay), '\(event.startDate)','\(event.endDate)','\(event.url)','\(event.note)','\(event.getAttendeesString())')"
      let result = self.connectDB.executeUpdate(insertSQL, withArgumentsInArray: nil)
      if !result {
        println("Insert Error: \(self.connectDB.lastErrorMessage())")
      }
      self.connectDB.close()
    }else{
      println("Insert Error: \(self.connectDB.lastErrorMessage())")
    }
  }
  
  
  
  func update(event:EventModel){
    self.createConnection()
    if self.connectDB.open(){
      let insertSQL = "UPDATE EVENTS SET TITLE = '\(event.title)', LOCATION = '\(event.location)', ALLDAY = \(event.allDay), STARTDATE = '\(event.startDate)', ENDDATE = '\(event.endDate)', URL = '\(event.url)', NOTE='\(event.note)', ATTENDEES = '\(event.getAttendeesString())' WHERE GOOGLEID = '\(event.eventID)'"
      let result = self.connectDB.executeUpdate(insertSQL, withArgumentsInArray: nil)
      if !result {
        println("Error: \(self.connectDB.lastErrorMessage())")
      }
      self.connectDB.close()
    }else{
      println("Error: \(self.connectDB.lastErrorMessage())")
    }
  }
  
  func searchByID(id:String)->FMResultSet!{
    NSLog("Search event by google id....")
    self.createConnection()
    if self.connectDB.open(){
      let sql = "SELECT * FROM EVENTS WHERE GOOGLEID = '\(id)'"
      let results:FMResultSet? = self.connectDB.executeQuery(sql, withArgumentsInArray: nil)
      return results
      
    }else{
      println("Error: \(self.connectDB.lastErrorMessage())")
    }
    return nil
  }
  
  
  func searchByStartDate(startDate:String)->FMResultSet!{
    
    NSLog("Search event by start date....")
    self.createConnection()
    if self.connectDB.open(){
      let sql = "SELECT * FROM EVENTS WHERE STARTDATE like '\(startDate)%'"
      let results:FMResultSet? = self.connectDB.executeQuery(sql, withArgumentsInArray: nil)
      //println(sql)
      return results
      
    }else{
      NSLog("Error: \(self.connectDB.lastErrorMessage())")
    }
    return nil
  }
  
  
  
  
  func selectAllEvents()->FMResultSet!{
    
    self.createConnection()
    if self.connectDB.open(){
      let sql = "SELECT * FROM EVENTS"
      let results:FMResultSet? = self.connectDB.executeQuery(sql, withArgumentsInArray: nil)
      
      return results
      
    }else{
      NSLog("Select Error: \(self.connectDB.lastErrorMessage())")
    }
    return nil
  }
  
  func deleteByGoogleId(googleID:String)->Bool{
    self.createConnection()
    var results = false
    if self.connectDB.open(){
      let sql = "DELETE FROM EVENTS WHERE GOOGLEID = '\(googleID)'"
      results = self.connectDB.executeUpdate(sql, withArgumentsInArray: nil)
      
    }else{
      NSLog("Select Error: \(self.connectDB.lastErrorMessage())")
    }
    self.closeConnection()
    return results
  }
  
  func dropTable(){
    self.createConnection()
    if self.connectDB.open(){
      let sql = "DELETE FROM EVENTS"
      self.connectDB.executeStatements(sql)
    }else{
      NSLog("Select Error: \(self.connectDB.lastErrorMessage())")
    }
    self.closeConnection()
  }
  
  func closeConnection(){
      self.connectDB.close()
  }

}