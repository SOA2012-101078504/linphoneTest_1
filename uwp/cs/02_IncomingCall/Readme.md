Linphone X UWP tutorial 02_IncomingCall
========================================

This time we are going to receive our first calls !

Because the architecture of the first two tutorials were a bit too simple for a larger app we moved things a bit.
All the code about the core (creation, iterate, log in...) is now in the class Service/CoreService.

The page LoginPage is updated and now redirects to a new page (NavigationRoot) this page only contains a NavigationView.
If you are note familiar with NavigationView you can take a look at [the NavigationView doc](https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/navigationview), 
but this is not mandatory since it contains no Linphone code and is only here for navigation.

By default the NavigationView load the new page CallsPage (the only one for now), on this page you can answer or decline incoming calls.

If you don't have SIP friends to make tests we recommend you to install Linphone on your mobile device (Android or iOS) and to make calls to yourself.

Don't forget to install those NuGet packages :
 - LinphoneSDK (can be found here : https://www.linphone.org/snapshots/windows/sdk/)
 - Microsoft.NETCore.UniversalWindowsPlatform (version 6.2.12 recommended)

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
│   │   CallsPage.xaml(.cs) : This is the new page where you can make calls.
│   │               This is where you will find the new Linphone's uses.
│   │       
│   │   LoginPage.xaml(.cs) : The same login page as the previous step, now in his own file.
│   │
│   │   NavigationRoot.xaml(.cs) : The new page containing the NavigationView and the main app Frame.
│
```