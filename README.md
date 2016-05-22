# Casual Stone (OS X Only)
Add notifications to your favorite pass-time application. Parses game application logs and displays specific events to OSX notification center. The purpose of this app is to make the gameplay experience more efficient. If you agree with this movement, consider giving the project a star and contributing!

![compatibility](https://raw.githubusercontent.com/skonagaya/CasualStone/master/CasualStone/demo.png)

![demo](https://giant.gfycat.com/EsteemedRegalKitty.gif)

## Download
Get the app [here](https://github.com/skonagaya/CasualStone/releases/download/1.3.2/CasualStone.dmg) until I find a better way to distribute.

## Features
Notifications can be sent for the following events:
- **Game Start**: The end of queue and start of mulligan phase.
- **Turn End**: The end of a players turn.
- **Concede**: A player concedes from the current match.

Notifications can be configured to only show for Player, Opponent, or Both.

## How to Use
1. **Open the application** and an icon will appear in your menu bar. There are no dock icons for Casual Stone.
2. **(Optional) Enter your username.** If it is your first time opening Casual Stone, the application will ask for your card game username. If a username is not provided, Casual Stone will not allow the selection of `Show for Player` and `Show for Opponent`. Casual Stone uses username information to distinguish events between the Player and the Opponent. 
3. **Click on Casual Stone Menu Icon** to open the navigation menu. If a username was entered, that username will be displayed at the top of the menu.
4. **Hover over an event** that you want notifications for and
5. **Select the player** you want to show notifications for. For example, if you only want notifications for when your turn starts, Hover over `Start Turn >` and select `Show for Player`
6. **Play and enjoy** the card game. Alt + Tab till your heart's content.

Casual Stone will remember the settings that were used the last time the application was launched, including username. If the Player's username is different (ie user logged into another account), set the username by clicking on the `Set Username` menu button. Additionally, Casual Stone will let you know if the username configured was not found in the current card game match.

>Note: If a username was not set by user, Casual Stone will learn this information from the Logs, eventually. Casual Stone will assume a Player username after three successive games. Basically, the app assumes that the username appearing three times in a row is, you, the Player. This has potential for ~~a bug~~ known issue.

## Tested Devices
Application has been successfully tested on:
- OS X El Capitan 10.11.3

## Troubleshooting
Casual Stone uses the card game application's log files. If the application cannot locate the log file, notifications will fail. The application expects the logs to be found at `/Applications/Hearthstone/Logs/Power.log`

## Contact
Suggestions, issues, and comments can be submitted to swkonagaya@gmail.com

The purpose of this app is to make the gameplay experience more efficient. 
If you agree that this has helped you save time, please consider donating to motivate support for this application.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=swkonagaya%40gmail%2ecom&lc=US&item_name=Sean%20Konagaya&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted)
