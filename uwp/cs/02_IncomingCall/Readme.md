Linphone X UWP tutorial 02_IncomingCall
========================================

This time we are going to receive our first calls !

The architecture of the first two tutorials was a bit simple for a larger app, so we moved things a bit.
All the core-related code (creation, iterate, log in...) is now in the class Service/CoreService.

The LoginPage now redirects to a new page (NavigationRoot) this page only contains a NavigationView.
If you are unfamiliar with NavigationView you can take a look at [the NavigationView doc](https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/navigationview), 
but this is not mandatory since it contains no Linphone code and is only here for navigation.

By default the NavigationView loads the new CallsPage (the only one for now), on this page you can answer or decline incoming calls.

If you don't have SIP friends to test with, you can also install Linphone on your mobile device (Android or iOS) and call yourself with a different account.

New/updated files :

```
02_outgoing_call
│
│   Package.appxmanifest : For this step we added new capabilities : Microphone, VOIP calling
│   
└───Service :
│   │   CoreService.cs : A singleton service which contains the Linphone.Core. 
│   │               You can find here all the previous tutorial code and the new code 
│   │               for calls !
│   │
│
│
└───Views :
│   │   CallsPage.xaml(.cs) : This is the new page from which you can make calls.
│   │                         Also contains new Linphone-related code.
│   │       
│   │   LoginPage.xaml(.cs) : The same login page as the previous step, now in its own file.
│   │
│   │   NavigationRoot.xaml(.cs) : The new page containing the NavigationView and the main app Frame.
│
```