Linphone X UWP tutorial 06_group_chat
========================================

In this step we will tackle two new concepts: group chats and multipart messages. To enable 
those new features we are going to use Flexisip as a backend (see group ChatRoom creation). Flexisip
is a complete and modular SIP server suite. If you need more informations about Flexisip you can read
this [Flexisip presentation](http://linphone.org/technical-corner/flexisip) or 
[Contact us](http://linphone.org/contact). 

We will create a new page so you can prepare your participant list before creating a group chat, see 
CreateGroupChatRoom.xaml(.cs) and CoreService.cs to learn how to create group chats.

We will update the ChatPage.xaml(.cs) and the MessageDisplay.xaml(cs) so you can send and display multipart
messages correctly. Multipart messages are allowed by default in flexisip, you can try it right now in a group chat room.
In a group ChatRoom some events that can occur (subject change, admin status modification...) will also be displayed. See EventDisplay.xaml(.cs).
And lastly we will change the way we display the ChatRoom in the list (ChatsPage.xml). See ChatRoomToStringConverter.cs.


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
│   │               Take a look at the LogIn method to see how to setup a conference factory.
│
└───Shared :
│   │   ChatRoomToStringConverter.cs : a class that implements IValueConverter to display 
│   │               the chat room name depending on its type.
│   │
│   │   Utils.cs : Utility class to gather static methods used in different other classes.
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
