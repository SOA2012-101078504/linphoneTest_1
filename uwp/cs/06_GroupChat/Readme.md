Linphone X UWP tutorial 06_group_chat
========================================

In this step we are going to approach to new concepts: group chat and multipart message. To enable 
those new features we are going to use Flexisip as a backend (see group ChatRoom creation). Flexisip
is a complete and modular SIP server suite. If you need more informations about Flexisip you can read
this [Flexisip presentation](http://linphone.org/technical-corner/flexisip) or 
[Contact us](http://linphone.org/contact). 

We created a new page so you can prepare your participant list before creating a group chat, see 
CreateGroupChatRoom.xaml(.cs) and CoreService.cs to learn how to create group chat.

We also updated the ChatPage.xaml(.cs) and the MessageDisplay.xaml(cs) so you can send and display multipart
messages correctly. Multipart message are allowed by default in flexisip, you can try it right now in group chat room.
In group ChatRoom some events that can occur (subject change, admin status modification...) are also displayed, see EventDisplay.xaml(.cs).
And last we change the way we display the ChatRoom in the list (ChatsPage.xml) see ChatRoomToStringConverter.cs.


Don't forget to install those NuGet packages :
 - LinphoneSDK (can be found here : https://www.linphone.org/snapshots/windows/sdk/)
 - Microsoft.NETCore.UniversalWindowsPlatform (version 6.2.12 recommended)
 - ANGLE.WindowsStore (for video rendering, version 2.1.13 recommended)

New/updated files :

```
06_group_chat

└───Controls :
│   │   ContentDisplay.xaml(.cs) : Inner control now used in MessageDisplay. Contains the code to display
│   │               one Linphone.Content object. 
│   │
│   │   EventDisplay.xaml(.cs) : Inner control used in ChatPage to display all events that
│   │               are not messages. 
│   │
│   │   GroupChatDisplay.xaml(.cs) : A control used in the ChatPage to display the participant list
│   │               and some group chat controls. 
│   │
│   │   MessageDisplay.xaml(.cs) : A user control to display chat bubbles with more
│   │               information. Improved from the previous step to display all the 
│   │               contents of multipart messages (using ContentDisplay).
│   │
│
└───Service :
│   │   CoreService.cs : A singleton service which contains the Linphone.Core. 
│   │               Watch the LogIn method to see how to setup a conference factory.
│
└───Shared :
│   │   ChatRoomToStringConverter.cs : a class that implement IValueConverter to display the 
│   │               the chat room name according to its type.
│   │
│   │   Utils.cs : Utility class to regroup static methods used in different other classes.
│
└───Views :
│   │    
│   │   ChatPage.xaml(.cs) : This is the frame displayed when you select a chat room.     
│   │               You can now send and receive multipart when you are in a group chat room.
│   │               And when you open a group chat room you have access to a new menu with
│   │               the participants list and new controls (see GroupChatDisplay).
│   │     
│   │   ChatsPage.xaml(.cs) : ChatRoom list, updated to display different information according
│   │               to the chat room type (also see ChatRoomToStringConverter.cs)
│   │        
│   │
```
