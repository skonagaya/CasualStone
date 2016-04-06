//
//  AppDelegate.swift
//  Hearthstone Notifications
//
//  Created by Sean Konagaya on 4/2/16.
//  Copyright © 2016 Sean Konagaya. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var aboutWindow: NSPanel!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    let icon = NSImage(named:"statusIcon")
    let checkIcon = NSImage(named:"checkIcon")
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let aboutBox = NSImageView()
    
    var userNameItem = NSMenuItem()
    var targetList: [String] = []
    var playerValid = true
    var targetDetection: [String] = ["",""]
    
    func usernameMenuClicked(sender : NSMenuItem) {
        let userInput = promptAlert("Enter Username", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
        if (userInput != "") {
            defaults.setObject(userInput, forKey: "username")
            defaults.synchronize()
            userNameItem.title = "Playing as: " + (defaults.objectForKey("username") as! String)
        } else {return}
    }
    
    func quitMenuClicked(sender : NSMenuItem) {
        NSApp.terminate(self)
    }
    
    func aboutMenuClicked(sender : NSMenuItem) {
        NSRunningApplication.currentApplication().activateWithOptions(NSApplicationActivationOptions.ActivateIgnoringOtherApps)
        aboutWindow.setIsVisible(true)
    }
    
    func subMenuClicked(sender : NSMenuItem) {
        
        if (sender.state > 0) {return} // Do nothing if already selected
        
        if (sender.title == " Show for Opponent" ||
            sender.title == " Show for Player") {
            if (sender.title == " Show for Opponent") {
                targetList[sender.representedObject!["index"] as! Int] = "OPPONENT"
                playerValid = true
            } else if (sender.title == " Show for Player") {
                targetList[sender.representedObject!["index"] as! Int] = "PLAYER"
                playerValid = true
            }
            
            if (!userNameExists())
            {
                let userInput = promptAlert("Need more info", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
                if (userInput != "") {
                    defaults.setObject(userInput, forKey: "username")
                    defaults.synchronize()
                    userNameItem.title = "Playing as: " + (defaults.objectForKey("username") as! String)
                } else {return}
            }
        } else if (sender.title == " None") {
            
            targetList[sender.representedObject!["index"] as! Int] = "NONE"
            //targetList[sender.representedObject!["index"]] = "NONE"
        }
        else if (sender.title == " Show for Both") {
            
            targetList[sender.representedObject!["index"] as! Int] = "BOTH"
            playerValid = true
        }
        
        defaults.setObject(targetList, forKey: "targetList")
        defaults.synchronize()
        NSLog("Synchronized changes to user defaults")
        
        sender.state = Int(!Bool(sender.state))
        if(sender.action == #selector(AppDelegate.subMenuClicked(_:))){
            for itemMore in sender.menu!.itemArray as [NSMenuItem!]{
                if (itemMore.action == sender.action){
                    itemMore.state = (itemMore == sender) ? NSOnState : NSOffState;
                }
            }
        }
    }
    
    func createMenuItem(name: String, content: String, command: String, index: Int, target: String, usesUsername: Bool, isCustom: Bool, imageLocation: String) {
        
        let editMenuItem = NSMenuItem()
        let editSubMenu = NSMenu()
        let repObj = ["index": index, "target": target ]
        //let notifImage = NSImage(contentsOfFile: imageLocation)
        
        editMenuItem.title = name
        editMenuItem.submenu = editSubMenu
        statusMenu.addItem(editMenuItem)
        
        
        if usesUsername {
            
            let editSubMenuItemPlayer = NSMenuItem()
            if  target == "PLAYER" {
                editSubMenuItemPlayer.state = 1
            }
            else {
                editSubMenuItemPlayer.state = 0
            }
            editSubMenuItemPlayer.title = " Show for Player"
            editSubMenuItemPlayer.representedObject = repObj
            editSubMenuItemPlayer.onStateImage = checkIcon
            editSubMenuItemPlayer.action = #selector(AppDelegate.subMenuClicked(_:))
            editSubMenu.addItem(editSubMenuItemPlayer)
            
            let editSubMenuItemOpponent = NSMenuItem()
            if  target == "OPPONENT" {
                editSubMenuItemOpponent.state = 1
            }
            else {
                editSubMenuItemOpponent.state = 0
            }
            editSubMenuItemOpponent.title = " Show for Opponent"
            editSubMenuItemOpponent.representedObject = repObj
            editSubMenuItemOpponent.onStateImage = checkIcon
            editSubMenuItemOpponent.action = #selector(AppDelegate.subMenuClicked(_:))
            editSubMenu.addItem(editSubMenuItemOpponent)
        }
        
        let editSubMenuItemBoth = NSMenuItem()
        if  target == "BOTH" {
            editSubMenuItemBoth.state = 1
        }
        else {
            editSubMenuItemBoth.state = 0
        }
        editSubMenuItemBoth.title = " Show for Both"
        editSubMenuItemBoth.representedObject = repObj
        editSubMenuItemBoth.onStateImage = checkIcon
        editSubMenuItemBoth.action = #selector(AppDelegate.subMenuClicked(_:))
        editSubMenu.addItem(editSubMenuItemBoth)
        
        let editSubMenuItemNone = NSMenuItem()
        if  target == "NONE" {
            editSubMenuItemNone.state = 1
        }
        else {
            editSubMenuItemNone.state = 0
        }
        editSubMenuItemNone.title = " None"
        editSubMenuItemNone.representedObject = repObj
        editSubMenuItemNone.onStateImage = checkIcon
        editSubMenuItemNone.action = #selector(AppDelegate.subMenuClicked(_:))
        editSubMenu.addItem(editSubMenuItemNone)
        
        
        
        let task = NSTask()
        let pipe = NSPipe()
        
        task.standardOutput = pipe
        task.launchPath = "/bin/sh"
        
        task.arguments = ["-c", command]

        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        
        var obs1 : NSObjectProtocol!
        //var obs2 : NSObjectProtocol!
        
        obs1 = NSNotificationCenter.defaultCenter().addObserverForName(
            NSFileHandleDataAvailableNotification,
            object: outHandle,
            queue: nil) {
                notification -> Void in
                let data = outHandle.availableData
                if data.length > 0 {
                    
                    if let str = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        let trimmedStr = str.stringByReplacingOccurrencesOfString("\n", withString: "")
                        let notifText = content.stringByReplacingOccurrencesOfString("_output_", withString: trimmedStr as String)
                        let notification: NSUserNotification = NSUserNotification()
                        notification.title = name
                        notification.informativeText = String(notifText)
                        //notification.contentImage = notifImage
                        notification.contentImage = NSImage(contentsOfFile: NSBundle.mainBundle().pathForResource(imageLocation, ofType: "png")!)
                        NSLog("Received: " + trimmedStr + " for Setting: " + name)
                        
                        if name == "Start Game"{
                            self.playerValid = true
                            NSLog("Starting game, setting playerValid to true")
                            NSLog("str: " + (str as String))
                            NSLog("trimmed: " + (str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())))
                            
                            
                            let players = str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).componentsSeparatedByString("  ")
                            NSLog("players: " + players.description)
                            
                            for player in players {
                                for target in self.targetDetection {
                                    if player == target{
                                        NSLog("FOUND THE REAL SLIM SHADY")
                                        self.defaults.setObject(player, forKey: "username")
                                        self.userNameItem.title = "Playing as: " + (self.defaults.objectForKey("username") as! String)
                                    }
                                }
                            }
                            
                            var tempIndex = 0
                            for player in players {
                                self.targetDetection[tempIndex] = player
                                tempIndex = tempIndex + 1
                            }
                            
                            
                            
                        }
                        
                        
                        switch self.targetList[index] as String{
                        case "BOTH":
                            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                        case "OPPONENT":
                            if ((self.defaults.objectForKey("username") != nil) &&
                            (self.defaults.objectForKey("username") as! String != ""))
                            {
                                let playerName = self.defaults.objectForKey("username") as! String
                                if String(notifText).lowercaseString.rangeOfString(playerName) == nil {
                                    if !self.playerValid {
                                        NSLog("User name \"" + (self.defaults.objectForKey("username") as! String) + "\" was not found")
                                        notification.title = "User not found"
                                        notification.informativeText = "Your user name \"" + (self.defaults.objectForKey("username") as! String) + "\" was not found in the match"
                                        notification.contentImage = NSImage(contentsOfFile: NSBundle.mainBundle().pathForResource("warning", ofType: "png")!)
                                    }
                                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                                    self.playerValid = false

                                } else if usesUsername {
                                    self.playerValid = true
                                }
                            }
                        case "PLAYER":
                            if ((self.defaults.objectForKey("username") != nil) &&
                                (self.defaults.objectForKey("username") as! String != ""))
                            {
                                let playerName = self.defaults.objectForKey("username") as! String
                                if String(notifText).lowercaseString.rangeOfString(playerName) != nil {
                                   
                                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                                    self.playerValid = true
                                } else if (!self.playerValid) {
                                    NSLog("User name \"" + (self.defaults.objectForKey("username") as! String) + "\" was not found")
                                    notification.title = "User not found"
                                    notification.informativeText = "Your user name \"" + (self.defaults.objectForKey("username") as! String) + "\" was not found in the match"
                                    notification.contentImage = NSImage(contentsOfFile: NSBundle.mainBundle().pathForResource("warning", ofType: "png")!)
                                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                                } else if (usesUsername) {
                                    self.playerValid = false
                                }
                            }
                        case "NONE":
                            NSLog("NONE!")
                        default:
                            NSLog("WTF?! This should never happen.")
                            break
                        }
                        /*
                         
                         if self.targetList[index as Int] == menuOption.BOTH {
                         NSLog("BOTH!")
                         } else if self.targetList[index as Int] == menuOption.OPPONENT {
                         
                         }
                        }*/
                        
                        
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                } else {
                    //print("EOF on stdout from process")
                    NSNotificationCenter.defaultCenter().removeObserver(obs1)
                }
        }
        /*
        obs2 = NSNotificationCenter.defaultCenter().addObserverForName(
            NSTaskDidTerminateNotification,
            object: task,
            queue: nil) {
                notification -> Void in
                //print("terminated")
                NSNotificationCenter.defaultCenter().removeObserver(obs2)
        }*/
        
        
        task.launch()
        
    }
    
    func resetDefaults () {
        
        for key in Array(defaults.dictionaryRepresentation().keys) {
            defaults.removeObjectForKey(key)
        }
        defaults.removeObjectForKey("targetList")
        defaults.setObject(nil, forKey: "targetList")
        defaults.synchronize()
    }
    
    

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        aboutWindow.title = "About Hearthstone Notifications"
        aboutWindow.level = 100
        //aboutWindow.setFloat = true
        
        icon?.template = true
        checkIcon?.template = true
        
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self;
        
        
        statusMenu.addItem(userNameItem)
        
        
        // Read the JSON file
        if let path = NSBundle.mainBundle().pathForResource("config", ofType: "json") {
            do {
                let data = try NSData(contentsOfURL: NSURL(fileURLWithPath: path), options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let jsonObj = JSON(data: data)
                if jsonObj != JSON.null {
                    
                    // We'll keep track of the JSON file in case it was modified
                    // Because if it's modified, then the defaults would become invalid (ie won't match)
                    if (defaults.objectForKey("JSON") != nil)
                    {
                        NSLog("Found pre-existing JSON")
                        if (defaults.objectForKey("JSON") as! String != jsonObj.rawString()!)
                        {
                            printAlert("Reverting Defaults", text: "We found changes to your configuration file so we're reverting to default values.")
                            resetDefaults()
                            
                        }
                    }
                    
                    // Save a copy of the config file in defaults
                    defaults.setObject(jsonObj.rawString()!, forKey: "JSON")
                    defaults.synchronize()
                    
                    var defaultTargetListFound = false
                    
                    
                    if (defaults.objectForKey("targetList") != nil)
                    {
                        targetList = (defaults.objectForKey("targetList") as! [String])
                        NSLog("Found pre-existing targetList")
                        NSLog(targetList[0])
                        defaultTargetListFound = true
                    }
                    
                    // Create a menu item for each JSON entry
                    var notifIndex = 0
                    for notifObj in jsonObj["notificationList"].arrayValue {
                        let label = notifObj["notifLabel"].stringValue
                        let content = notifObj["notifContent"].stringValue
                        let command = notifObj["commandLine"].stringValue
                        let image = notifObj["notifImageLocation"].stringValue
                        let containsUsername = notifObj["containsUsername"].boolValue
                        
                        if !defaultTargetListFound {
                            targetList.append("BOTH")
                        }
                        
                        createMenuItem(label,
                                       content: content,
                                       command: command,
                                       index: notifIndex,
                                       target: targetList[notifIndex],
                                       usesUsername: containsUsername,
                                       isCustom: false,
                                       imageLocation: image
                        )
                        notifIndex = notifIndex + 1
                    }
                    
                    NSLog(targetList.description)
                    
                    NSLog("Finished creating menu items")
                    defaults.setObject(targetList, forKey: "targetList")
                    defaults.synchronize()
                    NSLog("Synchronized initial targetList to user defaults")
                    
                    if let menuName = jsonObj["notificationList"][0]["menuName"].string {
                        NSLog(menuName)
                    }
                    
                } else {
                    printAlert("Error",text: "Unable to read configuration file. The application will close.")
                    NSApp.terminate(self)
                }
            } catch let error as NSError {
                printAlert("Error",text: error.localizedDescription)
                NSApp.terminate(self)
                print(error.localizedDescription)
            }
        } else {
            printAlert("Error",text: "Unable to locate configuration file.")
            NSApp.terminate(self)
            print("Invalid filename/path.")
        }
        
        
        statusMenu.addItem(NSMenuItem.separatorItem())
        
        let usernameMenuItem = NSMenuItem()
        usernameMenuItem.title = "Set Username"
        statusMenu.addItem(usernameMenuItem)
        usernameMenuItem.action = #selector(AppDelegate.usernameMenuClicked(_:))
        
        let aboutMenuItem = NSMenuItem()
        aboutMenuItem.title = "About"
        statusMenu.addItem(aboutMenuItem)
        aboutMenuItem.action = #selector(AppDelegate.aboutMenuClicked(_:))
        
        let quitMenuItem = NSMenuItem()
        quitMenuItem.title = "Quit"
        statusMenu.addItem(quitMenuItem)
        quitMenuItem.action = #selector(AppDelegate.quitMenuClicked(_:))
        
        
        if defaults.objectForKey("username") == nil || defaults.objectForKey("username") as! String == "" {
            
            let userInput = promptAlert("Notification Setup", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
            if (userInput != "") {
                defaults.setObject(userInput, forKey: "username")
                defaults.synchronize()
                userNameItem.title = "Playing as: " + (defaults.objectForKey("username") as! String)
            } else {
                userNameItem.title = "Username not set"
            }
        } else {
            userNameItem.title = "Playing as: " + (defaults.objectForKey("username") as! String)
        }
        

    }
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        if notification.title == "User not found" {
            let userInput = promptAlert("Need more info", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
            if (userInput != "") {
                defaults.setObject(userInput, forKey: "username")
                defaults.synchronize()
                userNameItem.title = "Playing as: " + (defaults.objectForKey("username") as! String)
            } else {return}
        } else {
                NSWorkspace.sharedWorkspace().launchApplication("/Applications/Hearthstone/Hearthstone.app")
        }
        
    }
    

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func menuClicked(sender: NSMenuItem) {
        
        
    }
    
    func printAlert(title: String, text: String){
        NSRunningApplication.currentApplication().activateWithOptions(NSApplicationActivationOptions.ActivateIgnoringOtherApps)
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = title
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
        myPopup.addButtonWithTitle("OK")
        myPopup.runModal()
    }
    
    func promptAlert(title: String, text: String) -> String {
        NSRunningApplication.currentApplication().activateWithOptions(NSApplicationActivationOptions.ActivateIgnoringOtherApps)
        let msg = NSAlert()
        msg.addButtonWithTitle("OK")      // 1st button
        msg.addButtonWithTitle("Cancel")  // 2nd button
        msg.messageText = title
        msg.informativeText = text
        
        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        txt.stringValue = ""
        
        msg.accessoryView = txt
        let response: NSModalResponse = msg.runModal()
        
        if (response == NSAlertFirstButtonReturn) {
            return txt.stringValue
        } else {
            return ""
        }
    }
    
    func userNameExists() -> Bool {
        
        return ((defaults.objectForKey("username") != nil) && (defaults.objectForKey("username") as! String != ""))
    }

}