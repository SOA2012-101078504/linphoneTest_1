Linphone X UWP tutorial 05_FileTransfer
========================================

Learn how to send files over SIP using Linphone SDK.

We will add a button to send files to your peer, and improve the display of messages to
include more metadata and allow the user to download files sent by the remote end.
Most of the new Linphone uses are in Controls/MessageDisplay.xaml(.cs) and ChatPage.xaml(.cs) but don't
forget to set the attribute FileTransferServer on your Core ! (see Core creation in CoreService.cs)


New/updated files :

```
05_FileTransfer
└───Controls :
│   │   MessageDisplay.xaml(.cs) : A user control to display chat bubbles with more
│   │               information. Learn how to handle the different types of ChatMessage's here.
│   │
│
└───Service :
│   │   CoreService.cs : A singleton service which contains the Linphone.Core. 
│   │               We setup FileTransferServer during core creation now.
│
└───Views :
│   │    
│   │   ChatPage.xaml(.cs) : This is the frame displayed when you select a chat room.     
│   │               You can now send files and message display is improved (see MessageDisplay)
```