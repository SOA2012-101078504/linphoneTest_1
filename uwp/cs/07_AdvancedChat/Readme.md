Linphone X UWP tutorial 07_AdvancedChat
========================================

You reached the last step of this tutorial ! Well done ! In this step we will show you
how to create group chat, enable encryption and send ephemeral messages.

Linphone provides end-to-end encryption to your Flexisip chat with LIME. We will learn
in this step how to enable and use LIME to secure our ChatRoom. If you want more 
informations about LIME take a look to [this page](https://linphone.org/technical-corner/lime).

To test a secure chat room try to create a group chat room and tick the check box 
"I want a secure chat room". Most of the new and documented code can be found in
CoreService.cs. 

One-to-one encryption is similar to group chat encryption as it uses LIME. To learn
how to create a one-to-one encrypted chat room also see CoreService.cs. You can also try to create one
yourself using the new "Create a new secure ChatRoom" on top of the ChatsPage.

Ephemeral messages are meant to disappear after a certain amount of time has elapsed.
You can enable the ephemeral mode directly on a ChatRoom object, see ChatPage.xaml.cs to
learn how to enable/disable it. And finally take a look at the new code in MessageDisplay.xaml(.cs)
to see how to handle ephemeral messages.


New/updated files :

```
07_AdvancedChat
└───Controls :
│   │
│   │   MessageDisplay.xaml(.cs) : A user control to display chat bubbles from message event.
│   │               Ephemeral messages handling is added here in this step !
└───Service :
│   │   CoreService.cs : A singleton service which contains the Linphone.Core.
│   │               Updated to allow creation of encrypted group chat room.
│   │
│
└───Shared :
│   │   ChatRoomToStringConverter.cs : a class that implement IValueConverter to display the 
│   │               the chat room name according to its type. Now we display a SECURE tag
│   │               for secure chat rooms
│   │
└───Views :
│   │    
│   │   ChatPage.xaml(.cs) : This is the frame displayed when you select a chat room.
│   │               You can now enable/disable ephemeral mode here.
│   │     
│   │   ChatsPage.xaml(.cs) : ChatRoom list with a new "Create a new secure ChatRoom" button.
│   │        
```