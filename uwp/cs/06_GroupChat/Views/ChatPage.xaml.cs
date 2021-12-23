/*
 * Copyright (c) 2010-2020 Belledonne Communications SARL.
 *
 * This file is part of Linphone TutorialCS.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

using _06_GroupChat.Controls;
using _06_GroupChat.Service;
using Linphone;
using System;
using Windows.Storage;
using Windows.Storage.Pickers;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _06_GroupChat.Views
{
	public sealed partial class ChatPage : Page
	{
		private NavigationService NavigationService { get; } = NavigationService.Instance;
		private CoreService CoreService { get; } = CoreService.Instance;

		private ChatRoom ChatRoom;

		public ChatPage()
		{
			this.InitializeComponent();
		}

		protected override void OnNavigatedTo(NavigationEventArgs e)
		{
			base.OnNavigatedTo(e);
			ChatRoom = ((ChatRoom)e.Parameter);

			ChatRoom.Listener.OnMessageReceived += OnMessageReceived;

			// Here we register to almost all the different events that can happen on a conference.
			// We use the same method AddEvent to handle all of them.
			ChatRoom.Listener.OnConferenceLeft += AddEvent;
			ChatRoom.Listener.OnConferenceJoined += AddEvent;
			ChatRoom.Listener.OnParticipantDeviceRemoved += AddEvent;
			ChatRoom.Listener.OnSubjectChanged += AddEvent;
			ChatRoom.Listener.OnParticipantRemoved += AddEvent;
			ChatRoom.Listener.OnParticipantAdminStatusChanged += AddEvent;
			ChatRoom.Listener.OnParticipantAdded += AddEvent;

			// If the peer address is null it means we are not in a basic
			// ChatRoom, and that we have to wait for the answer from the
			// conference server.
			if (ChatRoom.PeerAddress != null)
			{
				UpdateGUI();
			}
			else
			{
				// So we register to the OnConferenceJoined to be notified and update
				// the frame when the ChatRoom is ready.
				ChatHeaderText.Text = "Creation in progress";
				ChatRoom.Listener.OnConferenceJoined += OnConferenceJoin;
			}
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			ChatRoom.Listener.OnMessageReceived -= OnMessageReceived;
			ChatRoom.Listener.OnConferenceLeft -= AddEvent;
			ChatRoom.Listener.OnConferenceJoined -= AddEvent;
			ChatRoom.Listener.OnParticipantDeviceRemoved -= AddEvent;
			ChatRoom.Listener.OnSubjectChanged -= AddEvent;
			ChatRoom.Listener.OnParticipantRemoved -= AddEvent;
			ChatRoom.Listener.OnParticipantAdminStatusChanged -= AddEvent;
			ChatRoom.Listener.OnParticipantAdded -= AddEvent;

			ChatRoom.Listener.OnConferenceJoined -= OnConferenceJoin;

			base.OnNavigatedFrom(e);
		}

		private void OnConferenceJoin(ChatRoom chatRoom, EventLog eventLog)
		{
			UpdateGUI();
		}

		private void UpdateGUI()
		{
			ChatHeaderText.Text = "Your conversation with : " + ChatRoom.PeerAddress.Username;

			// From now on we are not only iterating over messages (GetHistory) but over all
			// events : ChatRoom.GetHistoryEvents(int nb). As for GetHistory, 0 as a parameter
			// means everything for GetHistoryEvents.
			foreach (EventLog eventLog in ChatRoom.GetHistoryEvents(0))
			{
				// If the event is a message we do as before
				if (EventLogType.ConferenceChatMessage.Equals(eventLog.Type))
				{
					AddMessage(eventLog.ChatMessage);
				}
				else
				{
					// And if it is an other type of event we use the same AddEvent method we used
					// to register to the callbacks.
					AddEvent(null, eventLog);
				}
			}

			ChatRoom.MarkAsRead();

			NavigationService.CurrentNavigationRoot.UpdateUnreadMessageCount();
			NavigationService.CurrentChatspage.UpdateChatRooms();

			PeerUsername.Text += ChatRoom.PeerAddress.Username;
			YourUsername.Text += ChatRoom.LocalAddress.Username;

			if (ChatRoom.HasCapability((int)ChatRoomCapabilities.Conference))
			{
				GroupChatDisplay participantsDisplay = new GroupChatDisplay(ChatRoom);
				GroupChatDisplayBorder.Child = participantsDisplay;
				GroupChatDisplayBorder.Visibility = Visibility.Visible;
			}

			// We don't allow the user to send multipart messages in a basic ChatRoom
			if (ChatRoom.HasCapability((int)ChatRoomCapabilities.Basic))
			{
				SendMultipartButton.Visibility = Visibility.Collapsed;
			}
		}

		private void OnMessageReceived(ChatRoom chatRoom, ChatMessage message)
		{
			if (ChatRoom != null)
			{
				AddMessage(message);
				chatRoom.MarkAsRead();
			}
		}

		private void AddMessage(ChatMessage chatMessage)
		{
			MessageDisplay messageDisplay = new MessageDisplay(chatMessage);

			MessagesList.Children.Add(messageDisplay);

			ScrollToBottom();
		}

		private void AddEvent(ChatRoom chatRoom, EventLog eventLog)
		{
			// Here we simply create an event display control ...
			EventDisplay eventDisplay = new EventDisplay(eventLog);

			// ... and add it to the message list.
			MessagesList.Children.Add(eventDisplay);

			// See EventDisplay.xaml(.cs) to see how we handle events.

			ScrollToBottom();
		}

		private void ScrollToBottom()
		{
			MessagesScroll.UpdateLayout();
			MessagesScroll.ChangeView(1, MessagesScroll.ExtentHeight, 1);
		}

		private void OutgoingMessageButton_Click(object sender, RoutedEventArgs e)
		{
			if (ChatRoom != null && OutgoingMessageText.Text != null && OutgoingMessageText.Text.Length > 0)
			{
				ChatMessage chatMessage = ChatRoom.CreateMessage(OutgoingMessageText.Text);
				chatMessage.Send();
				AddMessage(chatMessage);
			}
			OutgoingMessageText.Text = "";
		}

		private async void SendFileButton_Click(object sender, RoutedEventArgs e)
		{
			FileOpenPicker picker = new FileOpenPicker
			{
				ViewMode = PickerViewMode.List,
				SuggestedStartLocation = PickerLocationId.DocumentsLibrary
			};
			picker.FileTypeFilter.Add("*");

			StorageFile file = await picker.PickSingleFileAsync();
			if (file != null)
			{
				Content content = await CoreService.CreateContentFromFile(file);
				ChatMessage fileMessage = ChatRoom.CreateFileTransferMessage(content);
				fileMessage.Send();
				AddMessage(fileMessage);
			}
		}

		private async void SendMultipartButton_Click(object sender, RoutedEventArgs e)
		{
			if (ChatRoom != null && OutgoingMessageText.Text != null && OutgoingMessageText.Text.Length > 0)
			{
				// To create a multipart message simply create a message like we did before
				ChatMessage multipartMessage = ChatRoom.CreateMessage(OutgoingMessageText.Text);

				FileOpenPicker picker = new FileOpenPicker
				{
					ViewMode = PickerViewMode.List,
					SuggestedStartLocation = PickerLocationId.DocumentsLibrary
				};
				picker.FileTypeFilter.Add("*");

				StorageFile file = await picker.PickSingleFileAsync();
				if (file != null)
				{
					Content content = await CoreService.CreateContentFromFile(file);

					// And use "AddFileContent", "AddTextContent" or "AddUtf8TextContent" to add more
					// contents to your message. It's as simple as that.
					multipartMessage.AddFileContent(content);

					multipartMessage.Send();
					AddMessage(multipartMessage);
				}
			}
			OutgoingMessageText.Text = "";
		}
	}
}