Push notifications tutorial
====================

On mobile devices (Android & iOS), you probably want your app to be reachable even if it's not in the foreground. 

To do that you need it to be able to receive push notifications from your SIP proxy, and in this tutorial, using [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging), you'll learn how to simply send the device push information to your server.

Compared to the previous tutorials, some changes are required in `app/build.gradle` and `AndroidManifest.xml` files, and you'll need to replace the `app/google-services.json` file by yours if you're not using a `sip.linphone.org` account.