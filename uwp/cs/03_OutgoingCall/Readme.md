Linphone X UWP tutorial 03_OutgoingCall
========================================

This time we are going to make our first video calls.

New/updated files :

```
03_OutgoingCall
│   Package.appxmanifest : For this step we added a new capability : Webcam.
│   
└───Service :
│   │   CoreService.cs : A singleton service which contains the Linphone.Core. 
│   │               Now updated with the ability to make video calls. 
│   │
│   │   VideoService.cs : A singleton service which contains the code to render the video call
│   │               on SwapChainPanel, using OpenGL.
│
│
└───Views :
│   │   CallsPage.xaml(.cs) : This is the page where you can make calls.
│   │               This is where you will find the new Linphone's uses.
```