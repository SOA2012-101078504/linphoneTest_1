Linphone X UWP tutorial 05_FileTransfer
========================================

Learn how to send files over SIP using Linphone SDK.

We added a button to send file to your peer, and we improved how messages are displayed to show 
you more information about them and allow you to download files sent by the remote end.
Most of the new Linphone usage are in Controls/MessageDisplay.xaml(.cs) and ChatPage.xaml(.cs) but don't
forget to set the attribute FileTransferServer on your Core ! (see Core creation in CoreService.cs)

Don't forget to install those NuGet packages :
 - LinphoneSDK (can be found here : https://www.linphone.org/snapshots/windows/sdk/)
 - Microsoft.NETCore.UniversalWindowsPlatform (version 6.2.12 recommended)
 - ANGLE.WindowsStore (for video rendering, version 2.1.13 recommended)

New/updated files :

```
05_FileTransfer
└───Controls :
│   │   MessageDisplay.xaml(.cs) : A user control to display chat bubbles with more
│   │               information. Learn how to handle the different types of ChatMessage here.
│   │
│
└───Service :
│   │   CoreService.cs : A singleton service which contains the Linphone.Core. 
│   │               We setup FileTransferServer during core creation now.
│
└───Views :
│   │    
│   │   ChatPage.xaml(.cs) : This is the frame displayed when you select a chat room.     
│   │               You can now send file and the message display is improved (see MessageDisplay)
```