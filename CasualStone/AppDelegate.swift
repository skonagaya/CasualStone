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
    
    let statusItem = NSStatusBar.system().statusItem(withLength: -1)
    let icon = NSImage(named:"statusIcon")
    let checkIcon = NSImage(named:"checkIcon")
    let defaults = UserDefaults.standard
    
    let aboutBox = NSImageView()
    let removeUsernameMenuItem = NSMenuItem()
    
    // used to reset all the settings to Show for Both in case usernames were purged
    var resetPointers: [NSMenuItem] = []
    
    var userNameItem = NSMenuItem()
    var targetList: [String] = []
    var playerValid = true
    var spectatorModeEnabled = false
    var targetDetection: [String] = ["",""]
    var gameIsActive = false
    
    var targetDetectionCounter = 0
    
    var usernameList: [String] = []
    
    var currentVersion = "1.5.0"
    
    func usernameMenuClicked(_ sender : NSMenuItem) {
        let userInput = promptAlert("Enter Username", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
        if (userInput != "") {
            addToUsernameListLabel(userInput)
        } else {return}
    }
    
    func removeUsernameMenuClicked(_ sender : NSMenuItem) {
        let userInput = promptRemoveUsernameAlert("Select Username", text: "Your username is used to distinguish you and your opponent.\n\nSelect a username to remove")
        if (userInput != "") {
            removeFromUsernameListLabel(userInput)
        } else {return}
    }
    
    func addToUsernameListLabel (_ usernameToAdd: String) {
        playerValid = true // assume that user fixed their problem if they're mid-match
        targetDetectionCounter = 0
        targetDetection[0] = ""
        targetDetection[1] = ""
        usernameList.append(usernameToAdd)
        defaults.set(usernameList, forKey: "username")
        defaults.synchronize()
        updateUsernameListLabel()
    }
    
    func removeFromUsernameListLabel (_ usernameToRemove: String) {
        targetDetectionCounter = 0
        targetDetection[0] = ""
        targetDetection[1] = ""
        usernameList = usernameList.filter{$0 != usernameToRemove}
        defaults.set(usernameList, forKey: "username")
        defaults.synchronize()
        updateUsernameListLabel()
    }
    
    func updateUsernameListLabel() {
        if usernameList.isEmpty{
            let userInput = promptAlert("Notification Setup", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
            if (userInput != "") {
                addToUsernameListLabel(userInput)
            } else {
                userNameItem.attributedTitle = NSAttributedString(string: "Username not set")
                removeUsernameMenuItem.isHidden = true
                for setting  in resetPointers { // revert all back to "show for both"
                    subMenuClicked(setting as NSMenuItem)
                }
            }
            
        } else {
            removeUsernameMenuItem.isHidden = false
            var usernameListString = "Playing as:"
            for username in usernameList {
                usernameListString = usernameListString + "\n  - " + username
            }
            userNameItem.attributedTitle = NSAttributedString(string: usernameListString)
        }
    }
    
    func quitMenuClicked(_ sender : NSMenuItem) {
        NSApp.terminate(self)
    }
    
    func aboutMenuClicked(_ sender : NSMenuItem) {
        NSRunningApplication.current().activate(options: NSApplicationActivationOptions.activateIgnoringOtherApps)
        aboutWindow.setIsVisible(true)
    }
    
    func subMenuClicked(_ sender : NSMenuItem) {
        
        if (sender.state > 0) {return} // Do nothing if already selected
        
        if (sender.title == " Show for Opponent" ||
            sender.title == " Show for Player") {
            if (sender.title == " Show for Opponent") {
                targetList[(sender.representedObject as! [String : Any])["index"] as! Int] = "OPPONENT"
                playerValid = true
            } else if (sender.title == " Show for Player") {
                targetList[(sender.representedObject as! [String : Any])["index"] as! Int] = "PLAYER"
                playerValid = true
            }
            
            if (!userNameExists())
            {
                let userInput = promptAlert("Need more info", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
                if (userInput != "") {
                    addToUsernameListLabel(userInput)
                } else {return}
            }
        } else if (sender.title == " None") {
            
            targetList[(sender.representedObject as! [String : Any])["index"] as! Int] = "NONE"
            //targetList[sender.representedObject!["index"]] = "NONE"
        }
        else if (sender.title == " Show for Both") {
            
            targetList[(sender.representedObject as! [String : Any])["index"] as! Int] = "BOTH"
            playerValid = true
        }
        
        defaults.set(targetList, forKey: "targetList")
        defaults.synchronize()
        NSLog("Synchronized changes to user defaults")
        
        sender.state = 1 - sender.state
        if(sender.action == #selector(AppDelegate.subMenuClicked(_:))){
            for itemMore in sender.menu!.items as [NSMenuItem?]{
                if (itemMore?.action == sender.action){
                    itemMore?.state = (itemMore == sender) ? NSOnState : NSOffState;
                }
            }
        }
    }
    
    
    
    func loggingEnabled() -> Bool {
        let task = Process()
        
        // Set the task parameters
        task.launchPath = "/bin/sh"
        task.arguments = ["-c","if ! [[ $(grep -o -m 1 --line-buffered '\\[Power\\]' ~/Library/Preferences/Blizzard/Hearthstone/log.config 2>/dev/null) = \\[Power\\] ]]; then printf '[Power]\nLogLevel=1\nFilePrinting=true\nConsolePrinting=false\nScreenPrinting=false' >> ~/Library/Preferences/Blizzard/Hearthstone/log.config; touch /Applications/Hearthstone/Logs/Power.log; echo true ; fi"]
        
        // Create a Pipe and make the task
        // put all the output there
        let pipe = Pipe()
        task.standardOutput = pipe
        
        // Launch the task
        task.launch()
        
        // Get the data
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)!.replacingOccurrences(of: "\n", with: "")
        
        /*
        let task = NSTask()
        let command = "if ! [[ $(grep -o -m 1 --line-buffered '\\[Power\\]' ~/Library/Preferences/Blizzard/Hearthstone/log.config 2>/dev/null) = \\[Power\\] \\]\\]; then printf '\\[Power\\]\nLogLevel=1\nFilePrinting=true\nConsolePrinting=false\nScreenPrinting=false' >> ~/Library/Preferences/Blizzard/Hearthstone/log.config; echo true ; fi"
        task.launchPath = "/bin/sh"
        NSLog("Command: ")
        NSLog(command)
        
        task.arguments = ["-c", command]
        
        let pipe = NSPipe()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        let trimmedStr = output.stringByReplacingOccurrencesOfString("\n", withString: "")
        NSLog("Output: ")
        NSLog(output)
 */
        return output == "true"
    }
    
    func createMenuItem(_ name: String, content: String, command: String, index: Int, target: String, usesUsername: Bool, isCustom: Bool, imageLocation: String) {
        
        let editMenuItem = NSMenuItem()
        let editSubMenu = NSMenu()
        let repObj = ["index": index, "target": target ] as [String : Any]
        var currentPlayerDetection: [String] = ["",""]
        var currentPlayerDetectionIndexed = false
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
        
        self.resetPointers.append(editSubMenuItemBoth)
        
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
        
        
        
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.launchPath = "/bin/sh"
        
        task.arguments = ["-c", command]

        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        
        var obs1 : NSObjectProtocol!
        //var obs2 : NSObjectProtocol!
        
        obs1 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: outHandle,
            queue: nil) {
                notification -> Void in
                let data = outHandle.availableData
                if data.count > 0 {
                    
                    if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                        
                        NSLog((NSWorkspace.shared().frontmostApplication)!.description)
                        
                        if (NSWorkspace.shared().frontmostApplication)!.description.range(of: "Hearthstone") != nil {
                            self.gameIsActive = true
                        } else {self.gameIsActive = false}
                        let trimmedStr = str.replacingOccurrences(of: "\n", with: "")
                        let notifText = content.replacingOccurrences(of: "_output_", with: trimmedStr as String)
                        let notification: NSUserNotification = NSUserNotification()
                        notification.title = name
                        notification.informativeText = String(notifText)
                        //notification.contentImage = notifImage
                        notification.contentImage = NSImage(contentsOfFile: Bundle.main.path(forResource: imageLocation, ofType: "png")!)
                        NSLog("Received: " + trimmedStr + " for Setting: " + name)
                        
                        if name == "Concede" || name == "Winner" {
                            NSLog("Detected Concede or Winner")
                            NSLog("Resetting player valid flag")
                            self.playerValid = true
                        }
                        
                        
                        if name == "Spectating" {
                            self.spectatorModeEnabled = true
                            NSUserNotificationCenter.default.deliver(notification)
                            NSLog("Beginning spectator mode")
                        }else if name == "Start Game"{
                            
                            if self.spectatorModeEnabled {
                                NSLog("Disabling spectator mode")
                                self.spectatorModeEnabled = false
                            }
                            self.playerValid = true
                            //NSLog("str: " + (str as String))
                            //NSLog("trimmed: " + (str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())))
                            
                            let checkDouble = str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: "  ")
                            var currentPlayer = ""
                            if checkDouble.count == 1{
                                currentPlayer = checkDouble[0]
                                NSLog("Current player: " + currentPlayer)
                                var playerIndex = 0
                                
                                if currentPlayerDetectionIndexed {playerIndex = playerIndex+1}
                                currentPlayerDetection[playerIndex] = currentPlayer
                            } else if checkDouble.count == 2 {
                                currentPlayerDetection[0] = checkDouble[0]
                                currentPlayerDetection[1] = checkDouble[1]
                                
                                currentPlayerDetectionIndexed = true
                            }
                            
                            
                            if currentPlayerDetectionIndexed {
                                var rematchCount = 0
                                var eligiblePlayer = ""
                                
                                NSLog("Comparing current players: "+currentPlayerDetection.description+" and last players: "+self.targetDetection.description)
                                
                                for player in currentPlayerDetection {
                                    for target in self.targetDetection {
                                        if player.lowercased() == target.lowercased(){
                                            rematchCount = rematchCount + 1
                                            eligiblePlayer = player
                                        }
                                    }
                                }
                                
                                if rematchCount == 1 {
                                    self.targetDetectionCounter = self.targetDetectionCounter + 1
                                    NSLog("Match found for player detection: "+eligiblePlayer+" "+String(self.targetDetectionCounter) + " time(s)")
                                    if self.targetDetectionCounter == 2 {
                                        if self.usernameList.contains(where: {$0.caseInsensitiveCompare(eligiblePlayer) == .orderedSame}) {
                                            NSLog(eligiblePlayer+" already exists in the list")
                                        } else {
                                            NSLog("Adding "+eligiblePlayer+" to list")
                                            self.addToUsernameListLabel(eligiblePlayer)
                                        }
                                    }
                                } else if rematchCount == 2 {
                                    NSLog("Rematch detected. We won't count this towards player detection")
                                }
                                
                                var tempIndex = 0
                                for currentPlayer in currentPlayerDetection {
                                    self.targetDetection[tempIndex] = currentPlayer
                                    tempIndex = tempIndex + 1
                                }
                            }
                            
                            currentPlayerDetectionIndexed = !currentPlayerDetectionIndexed
                        }
                        
                        
                        if self.spectatorModeEnabled {
                            NSLog("Spectator mode enabled. Skipping " + name)
                        } else {
                            switch self.targetList[index] as String {
                            case "BOTH":
                                if !self.gameIsActive {
                                    NSUserNotificationCenter.default.deliver(notification)
                                }
                            case "OPPONENT":
                                if (!self.usernameList.isEmpty)
                                {
                                    var playerFound = false
                                    for username in self.usernameList {
                                        if String(notifText).lowercased().range(of: username.lowercased()) != nil {
                                            playerFound = true
                                        }
                                    }
                                    if !playerFound {
                                        if !self.playerValid && String(name).range(of: "Concede") == nil && String(name).range(of: "Winner") == nil {
                                            NSLog("User name not found")
                                            notification.title = "User not found"
                                            notification.informativeText = "Your usernames were not found in the match"
                                            notification.contentImage = NSImage(contentsOfFile: Bundle.main.path(forResource: "warning", ofType: "png")!)
                                            NSUserNotificationCenter.default.deliver(notification)
                                        } else {
                                            if !self.gameIsActive {
                                                NSUserNotificationCenter.default.deliver(notification)
                                            }
                                        }
                                        self.playerValid = false

                                    } else if usesUsername {
                                        self.playerValid = true
                                    }
                                }
                            case "PLAYER":
                                if (!self.usernameList.isEmpty)
                                {
                                    var playerFound = false
                                    for username in self.usernameList {
                                        if String(notifText).lowercased().range(of: username.lowercased()) != nil {
                                            NSLog("Match found for " + username)
                                            playerFound = true
                                        }
                                    }
                                    if playerFound {
                                        
                                        if !self.gameIsActive {
                                            NSUserNotificationCenter.default.deliver(notification)
                                        }
                                        self.playerValid = true
                                    } else if (!self.playerValid) {
                                        NSLog("User name not found")
                                        notification.title = "User not found"
                                        notification.informativeText = "Your usernames were not found in the match"
                                        notification.contentImage = NSImage(contentsOfFile: Bundle.main.path(forResource: "warning", ofType: "png")!)
                                        NSUserNotificationCenter.default.deliver(notification)
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
                        }
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                } else {
                    //print("EOF on stdout from process")
                    NotificationCenter.default.removeObserver(obs1)
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
            defaults.removeObject(forKey: key)
        }
        defaults.removeObject(forKey: "targetList")
        //defaults.set(nil, forKey: "targetList")
        defaults.synchronize()
    }
    
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        if loggingEnabled() && (NSWorkspace.shared().runningApplications.description.range(of: "unity.Blizzard Entertainment.Hearthstone") != nil) {
            printAlert("Logging Enabled", text: "Please restart Hearthstone in order to start receiving notifications")
        }
        
        aboutWindow.title = "About Hearthstone Notifications"
        aboutWindow.level = 100
        //aboutWindow.setFloat = true
        
        icon?.isTemplate = true
        checkIcon?.isTemplate = true
        
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        NSUserNotificationCenter.default.delegate = self;
        
        
        statusMenu.addItem(userNameItem)
        statusMenu.addItem(NSMenuItem.separator())
        let urlString = "https://raw.githubusercontent.com/skonagaya/CasualStone/master/CasualStone/broadcast.json"
        
        if let url = URL(string: urlString) {
            if let data = try? Data(contentsOf: url, options: []) {
                let json = JSON(data: data)
                
                if json != JSON.null {
                    if (currentVersion != json["latest"]["version"].stringValue) {
                        printAlert("Version Update",text:"New version available below\n\nhttps://github.com/skonagaya/CasualStone/releases")
                            
                    }
                    
                    if (defaults.object(forKey: "logviewed") != nil) {
                        if (defaults.object(forKey: "logviewed") as! String != json["latest"]["version"].stringValue)
                        {
                            printAlert("Version Update",text:json["latest"]["logchange"].stringValue)
                            defaults.set(json["latest"]["version"].stringValue, forKey: "logviewed")
                            defaults.synchronize()
                        }
                    } else {
                        printAlert("Version Update",text:json["latest"]["logchange"].stringValue)
                        defaults.set(json["latest"]["version"].stringValue, forKey: "logviewed")
                        defaults.synchronize()
                    }
                }
            }
        }
        
        
        // Read the JSON file
        if let path = Bundle.main.path(forResource: "config", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.mappedIfSafe)
                let jsonObj = JSON(data: data)
                if jsonObj != JSON.null {
                    
                    // We'll keep track of the JSON file in case it was modified
                    // Because if it's modified, then the defaults would become invalid (ie won't match)
                    if (defaults.object(forKey: "JSON") != nil)
                    {
                        NSLog("Found pre-existing JSON")
                        if (defaults.object(forKey: "JSON") as! String != jsonObj.rawString()!)
                        {
                            printAlert("Reverting Defaults", text: "We found changes to your configuration file so we're reverting to default values.")
                            resetDefaults()
                            
                        }
                    }
                    
                    // Save a copy of the config file in defaults
                    defaults.set(jsonObj.rawString()!, forKey: "JSON")
                    defaults.synchronize()
                    
                    var defaultTargetListFound = false
                    
                    
                    if (defaults.object(forKey: "targetList") != nil)
                    {
                        targetList = (defaults.object(forKey: "targetList") as! [String])
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
                        let showInMenu = notifObj["showInMenu"].boolValue
                        
                        if !defaultTargetListFound {
                            targetList.append("BOTH")
                        }
                        
                        if (showInMenu){
                        
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
                    }
                    
                    NSLog(targetList.description)
                    
                    NSLog("Finished creating menu items")
                    defaults.set(targetList, forKey: "targetList")
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
        
        
        statusMenu.addItem(NSMenuItem.separator())
        
        let usernameMenuItem = NSMenuItem()
        usernameMenuItem.title = "Add Username"
        statusMenu.addItem(usernameMenuItem)
        usernameMenuItem.action = #selector(AppDelegate.usernameMenuClicked(_:))
        
        removeUsernameMenuItem.title = "Remove Username"
        statusMenu.addItem(removeUsernameMenuItem)
        removeUsernameMenuItem.action = #selector(AppDelegate.removeUsernameMenuClicked(_:))
        
        if usernameList.isEmpty{
            removeUsernameMenuItem.isHidden = true
        }
        
        let aboutMenuItem = NSMenuItem()
        aboutMenuItem.title = "About"
        statusMenu.addItem(aboutMenuItem)
        aboutMenuItem.action = #selector(AppDelegate.aboutMenuClicked(_:))
        
        let quitMenuItem = NSMenuItem()
        quitMenuItem.title = "Quit"
        statusMenu.addItem(quitMenuItem)
        quitMenuItem.action = #selector(AppDelegate.quitMenuClicked(_:))
        
        
        if defaults.object(forKey: "username") == nil || (defaults.object(forKey: "username") as! [String]).isEmpty {
            
            let userInput = promptAlert("Notification Setup", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
            if (userInput != "") {
                addToUsernameListLabel(userInput)
            } else {
                userNameItem.attributedTitle = NSAttributedString(string: "Username not set")
                removeUsernameMenuItem.isHidden = true
            }
        } else {
            usernameList = defaults.object(forKey: "username") as! [String]
            updateUsernameListLabel()
        }
        

    }
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if notification.title == "User not found" {
            let userInput = promptAlert("Need more info", text: "Your username is used to distinguish you and your opponent.\n\nEnter your username below:")
            if (userInput != "") {
                addToUsernameListLabel(userInput)
            } else {return}
        } else {
                NSWorkspace.shared().launchApplication("/Applications/Hearthstone/Hearthstone.app")
        }
        
    }
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func menuClicked(_ sender: NSMenuItem) {
        
        
    }
    
    func printAlert(_ title: String, text: String){
        NSRunningApplication.current().activate(options: NSApplicationActivationOptions.activateIgnoringOtherApps)
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = title
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.warning
        myPopup.addButton(withTitle: "OK")
        myPopup.runModal()
    }
    
    func promptRemoveUsernameAlert(_ title: String, text: String) -> String {
        NSRunningApplication.current().activate(options: NSApplicationActivationOptions.activateIgnoringOtherApps)
        let msg = NSAlert()
        
        msg.addButton(withTitle: "OK")      // 1st button
        msg.addButton(withTitle: "Cancel")  // 2nd button
        msg.messageText = title
        msg.informativeText = text
        
        let accessory = NSPopUpButton(frame: NSMakeRect(0,0,200,24))
        accessory.addItems(withTitles: usernameList)
        accessory.selectItem(at: 0)
        
        msg.accessoryView = accessory
        let response: NSModalResponse = msg.runModal()
        
        if (response == NSAlertFirstButtonReturn) {
            return usernameList[accessory.indexOfSelectedItem]
        } else {
            return ""
        }
    }
    
    func promptAlert(_ title: String, text: String) -> String {
        NSRunningApplication.current().activate(options: NSApplicationActivationOptions.activateIgnoringOtherApps)
        let msg = NSAlert()
        msg.addButton(withTitle: "OK")      // 1st button
        msg.addButton(withTitle: "Cancel")  // 2nd button
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
        
        return (!usernameList.isEmpty)
    }

}
