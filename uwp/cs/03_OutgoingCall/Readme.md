Linphone X UWP tutorial 03_OutgoingCall
========================================

This time we are going to make our first video calls.

Note the new ANGLE.WindowsStore package that was added. This is required for video rendering.
(If you restored NuGet packages for the solution as indicated in the parent Readme, it should
already be installed, and no additional action is needed on your side.)

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
│   │               on a SwapChainPanel, using OpenGL.
│
│
└───Views :
│   │   CallsPage.xaml(.cs) : This is the page where you can make calls.
│   │               Also contains new Linphone-related code.
```