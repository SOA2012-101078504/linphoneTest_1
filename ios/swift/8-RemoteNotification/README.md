Remote Push notifications tutorial
====================

On mobile devices (Android & iOS), you probably want your app to be reachable even if it's not in the foreground. 

To do that you need it to be able to receive push notifications from your SIP proxy, and in this tutorial, using [Apple Push Notification Service](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html), you'll learn how to simply send the device push information to your server.


Compared to the previous tutorials, some changes have been required in `RemoteNotification.xcodeproj` in order to enable `Push Notifications`, `BackGround Modes (Remote Notifications)`, and 'App Groups' in the capabilities of your project.

A Notification App Service Extension target has also been added to the project. This extension implements UNNotificationServiceExtension, which will call the 'didReceive' when the app receives a notification in the background, or is terminated. We will then have a maximum of 30 second to process the notification, and customise the displayed contents, before it pops on the phone's screen.

The "group.org.linphone.tutorials.notification" App Group will allow the app extension to share files, such as the linphonerc configuration file, with the main app. This way, we can start the shared core in the background, register, and process the sip message that flexisip sent us.
