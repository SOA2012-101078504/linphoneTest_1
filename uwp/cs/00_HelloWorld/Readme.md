Linphone X UWP tutorial 00_HelloWorld
======================================

The first tutorial is just here to display a hello world app with the current Linphone's version number.

Don't forget to install those NuGet packages :
 - LinphoneSDK (can be found here : https://www.linphone.org/snapshots/windows/sdk/)
 - Microsoft.NETCore.UniversalWindowsPlatform (version 6.2.12 recommended)

Main files :
```
00_HelloWorld
│   README.md : you are here  
│   App.xaml(.cs) : Default Windows Application file, nothing special here
│   MainPage.xaml(.cs) : This is were the magic happen, 
│       jump into this file to learn about Linphone core creation and how to display a hello world.
│
└───Assets : default UWP app assets
    │   LockScreenLogo.scale-200.png
    │   ...
```