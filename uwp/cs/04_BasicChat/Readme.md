Linphone X UWP tutorial 04_BasicChat
========================================

Second big step in this tutorial, we can now communicate in basic chat rooms.

In this part you are going to learn how to send and receive text messages over SIP using LinphoneSDK.
For our first step with ChatRoom we are going to create only one to one basic ChatRoom (no encryption, no ephemeral),
and for now the tutorial app will only support text message.

Don't forget to install those NuGet packages :
 - LinphoneSDK (can be found here : https://www.linphone.org/snapshots/windows/sdk/)
 - Microsoft.NETCore.UniversalWindowsPlatform (version 6.2.12 recommended)
 - ANGLE.WindowsStore (for video rendering, version 2.1.13 recommended)

New/Updated files :

```
04_BasicChat
└───Service :
│   │   CoreService.cs : A singleton service which contains the Linphone.Core. 
│   │               We added some code to create new chat rooms here.
│   │   
│   │   NavigationService.cs : A small service used to keeps reference to current pages displayed.
│
└───Views :
│   │    
│   │   ChatPage.xaml(.cs) : This is the frame displayed when you select a chat room.     
│   │               For now it's a simple page where you can send message and see your 
│   │               conversation history.
│   │     
│   │   ChatsPage.xaml(.cs) : In this page we list all the existing chat rooms. If you select 
│   │               one of them a ChatPage is render. You can also create new ChatRoom here.   
│   │
│   │   NavigationRoot.xaml(.cs) : The navigation page, you can now navigate the ChatsPage !
```