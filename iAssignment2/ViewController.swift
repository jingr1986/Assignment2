//
//  ViewController.swift
//  assignment2IPE
//
//  Created by vichaya sunsern on 20/05/2015.
//  Copyright (c) 2015 RMIT. All rights reserved.
//

import UIKit
import FBSDKLoginKit


class ViewController: UIViewController, FBSDKLoginButtonDelegate  {
  @IBOutlet var fbLoginView: UIView!
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    if (FBSDKAccessToken.currentAccessToken() != nil)
    {
      // User is already logged in, do work such as go to next view controller.
    }
    else
    {
      let loginView : FBSDKLoginButton = FBSDKLoginButton()
      //fbLoginView.addSubview(loginView)
      
      self.view.addSubview(loginView)
      loginView.center = self.view.center
      //loginView.center = fbLoginView.center
      loginView.readPermissions = ["public_profile", "email", "user_friends"]
      loginView.delegate = self
    }
    
    var defaults = NSUserDefaults.standardUserDefaults()
    if let events = defaults.objectForKey("allevents"){
      println("main view")
      println(events)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  // Facebook Delegate Methods
  
  func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
    println("User Logged In")
    
    if ((error) != nil)
    {
      // Process error
    }
    else if result.isCancelled {
      // Handle cancellations
    }
    else {
      // If you ask for multiple permissions at once, you
      // should check if specific permissions missing
      /*if result.grantedPermissions.contains("email")
      {
      // Do work
      }
      */
    }
  }
  
  func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
    println("User Logged Out")
  }
  
  func returnUserData()
  {
    let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
    graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
      
      if ((error) != nil)
      {
        // Process error
        println("Error: \(error)")
      }
      else
      {
        println("fetched user: \(result)")
        let userName : NSString = result.valueForKey("name") as NSString
        println("User Name is: \(userName)")
        let userEmail : NSString = result.valueForKey("email") as NSString
        println("User Email is: \(userEmail)")
      }
    })
  }
  
}

