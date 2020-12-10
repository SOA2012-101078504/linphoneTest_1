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

using _05_FileTransfer.Controls;
using _05_FileTransfer.Service;
using Linphone;
using System;
using Windows.Storage;
using Windows.Storage.Pickers;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _05_FileTransfer.Views
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
			ChatHeaderText.Text += ChatRoom.PeerAddress.Username;
			ChatRoom.Listener.OnMessageReceived += OnMessageReceived;
			foreach (ChatMessage chatMessage in ChatRoom.GetHistory(0))
			{
				AddMessage(chatMessage);
			}
			ChatRoom.MarkAsRead();

			NavigationService.CurrentNavigationRoot.UpdateUnreadMessageCount();
			NavigationService.CurrentChatspage.UpdateChatRooms();

			PeerUsername.Text += ChatRoom.PeerAddress.Username;
			YourUsername.Text += ChatRoom.LocalAddress.Username;
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			ChatRoom.Listener.OnMessageReceived -= OnMessageReceived;
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
			// Instead of simply display a TextBlock we now create a
			// MessageDisplay object to show more informations about the message.
			// See Controls/MessageDisplay.xaml(.cs)
			MessageDisplay messageDisplay = new MessageDisplay(chatMessage);

			MessagesList.Children.Add(messageDisplay);

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

		/// <summary>
		/// Method called when the "Send file" button is clicked
		/// </summary>
		private async void SendFileButton_Click(object sender, RoutedEventArgs e)
		{
			// Basic Windows code to let the user select a file and gain
			// read access to a StorageFile object.
			FileOpenPicker picker = new FileOpenPicker();
			picker.ViewMode = PickerViewMode.List;
			picker.SuggestedStartLocation = PickerLocationId.DocumentsLibrary;
			picker.FileTypeFilter.Add("*");
			StorageFile file = await picker.PickSingleFileAsync();

			if (file != null)
			{
				// We create a Linphone.Content object from the StorageFile object
				// see CoreService.CreateContentFromFile(StorageFile file)
				Content content = await CoreService.CreateContentFromFile(file);

				// To create a text ChatMessage for a chat room we use ChatRoom.CreateMessage(string message);
				// Here we want to create a file transfer message so we must use
				// ChatRoom.CreateFileTransferMessage(Content initialContent) to create it.
				ChatMessage fileMessage = ChatRoom.CreateFileTransferMessage(content);

				// Then simply call ChatMessage.Send() to send the message to the remote.
				fileMessage.Send();

				AddMessage(fileMessage);
			}
		}
	}
}