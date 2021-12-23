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

using _07_AdvancedChat.Controls;
using _07_AdvancedChat.Service;
using Linphone;
using System;
using Windows.Storage;
using Windows.Storage.Pickers;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _07_AdvancedChat.Views
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

			ChatRoom = (ChatRoom)e.Parameter;

			ChatRoom.Listener.OnMessageReceived += OnMessageReceived;
			ChatRoom.Listener.OnConferenceLeft += AddEvent;
			ChatRoom.Listener.OnConferenceJoined += AddEvent;
			ChatRoom.Listener.OnParticipantDeviceRemoved += AddEvent;
			ChatRoom.Listener.OnSubjectChanged += AddEvent;
			ChatRoom.Listener.OnParticipantRemoved += AddEvent;
			ChatRoom.Listener.OnParticipantAdminStatusChanged += AddEvent;
			ChatRoom.Listener.OnParticipantAdded += AddEvent;
			ChatRoom.Listener.OnEphemeralEvent += AddEvent;

			// In this step we want to test the ephemeral messages. This feature is only
			// available if you are using a Flexisip backend.
			if (ChatRoom.CurrentParams.Backend == ChatRoomBackend.FlexisipChat)
			{
				if (!ChatRoom.EphemeralEnabled)
				{
					// In this step when the ephemeral feature is available we enable it
					// by default. Just set the EphemeralEnabled to true to activate the
					// ephemeral mode, after this point every message sent will be marked
					// as ephemeral
					ChatRoom.EphemeralEnabled = true;

					// You can choose how long you want the message to be displayed before
					// getting destroyed with EphemeralLifetime, the value is in second.
					// Here we set a low value for testing purpose.
					ChatRoom.EphemeralLifetime = 15;

					// You can choose to disable the ephemeral mode at any time by setting EphemeralEnabled to false.
					// See the EphemeralCheckBox_Unchecked method.
				}
			}
			else
			{
				// If the backend is not a Flexisip one we hide the ephemeral feature in the ChatPage
				// because it doesn't support it.
				EphemeralCheckBox.Visibility = Visibility.Collapsed;
			}

			if (ChatRoom.PeerAddress != null)
			{
				UpdateGUI();
			}
			else
			{
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
			foreach (var eventLog in ChatRoom.GetHistoryEvents(0))
			{
				if (EventLogType.ConferenceChatMessage.Equals(eventLog.Type))
				{
					AddMessage(eventLog.ChatMessage);
				}
				else
				{
					AddEvent(null, eventLog);
				}
			}

			ChatRoom.MarkAsRead();

			NavigationService.CurrentNavigationRoot.UpdateUnreadMessageCount();
			NavigationService.CurrentChatspage.UpdateChatRooms();

			PeerUsername.Text += ChatRoom.PeerAddress.Username;
			YourUsername.Text += ChatRoom.LocalAddress.Username;

			// We only display the GroupChatDisplay if we are in a real group chat,
			// we don't if it's a OneToOne secure ChatRoom.
			if (ChatRoom.HasCapability((int)ChatRoomCapabilities.Conference)
				&& !ChatRoom.HasCapability((int)ChatRoomCapabilities.OneToOne))
			{
				GroupChatDisplay participantsDisplay = new GroupChatDisplay(ChatRoom);
				GroupChatDisplayBorder.Child = participantsDisplay;
				GroupChatDisplayBorder.Visibility = Visibility.Visible;
			}

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
			EventDisplay eventDisplay = new EventDisplay(eventLog);

			MessagesList.Children.Add(eventDisplay);

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
					multipartMessage.AddFileContent(content);

					multipartMessage.Send();
					AddMessage(multipartMessage);
				}
			}
			OutgoingMessageText.Text = "";
		}

		private void EphemeralCheckBox_Checked(object sender, RoutedEventArgs e)
		{
			if (ChatRoom != null)
			{
				ChatRoom.EphemeralEnabled = true;
			}
		}

		private void EphemeralCheckBox_Unchecked(object sender, RoutedEventArgs e)
		{
			if (ChatRoom != null)
			{
				ChatRoom.EphemeralEnabled = false;
			}
		}
	}
}