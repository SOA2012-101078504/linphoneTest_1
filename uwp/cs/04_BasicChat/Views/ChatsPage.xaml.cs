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

using _04_BasicChat.Service;
using Linphone;
using System;
using System.Threading.Tasks;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _04_BasicChat.Views
{
	public sealed partial class ChatsPage : Page
	{
		private CoreService CoreService { get; } = CoreService.Instance;

		private NavigationService NavigationService { get; } = NavigationService.Instance;

		public ChatsPage()
		{
			this.InitializeComponent();
		}

		protected override void OnNavigatedTo(NavigationEventArgs e)
		{
			base.OnNavigatedTo(e);

			// We just do this so we can update the list from other pages.
			NavigationService.CurrentChatspage = this;

			// Find and update the chat rooms list, see UpdateChatRooms
			UpdateChatRooms();

			// You are now familiar with those kinds of callback register.
			// Here we want to update the list every time a message is
			// received (list order and unread message count, see ChatsPage.xaml)
			// or sent (list order)
			CoreService.AddOnOnMessageReceivedDelegate(OnMessageReceivedOrSent);
			CoreService.AddOnMessageSentDelegate(OnMessageReceivedOrSent);
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			NavigationService.CurrentChatspage = null;

			// You need to unregister delegate to allow the garbage collector to
			// collect this instance when you navigate away.
			CoreService.RemoveOnOnMessageReceivedDelegate(OnMessageReceivedOrSent);
			CoreService.RemoveOnMessageSentDelegate(OnMessageReceivedOrSent);

			base.OnNavigatedFrom(e);
		}

		/// <summary>
		/// Method called to update the list every time a message is received or sent.
		/// </summary>
		private void OnMessageReceivedOrSent(Core core, ChatRoom chatRoom, ChatMessage message) => UpdateChatRooms();

		public void UpdateChatRooms()
		{
			ChatRoom selectedChatRoom = (ChatRoom)ChatRoomsLV.SelectedItem;
			ChatRoomsLV.Items.Clear();

			// In the ChatRooms list attribute you can find every ChatRooms linked
			// to your user. The list is ordered by ChatRoom last activity date
			// (most recent first).
			// You can see in ChatsPage.xaml that we only use the properties
			// UnreadMessagesCount and PeerAdress to display our chat rooms.
			// In later steps we will do more.
			foreach (ChatRoom chatRoom in CoreService.Core.ChatRooms)
			{
				// Here we use the HistorySize attribute to display only
				// ChatRooms where at least one message was exchanged.
				if (chatRoom.HistorySize > 0)
				{
					ChatRoomsLV.Items.Add(chatRoom);
					if (selectedChatRoom == chatRoom)
					{
						ChatRoomsLV.SelectedItem = chatRoom;
					}
				}
			}
		}

		/// <summary>
		/// Method called when any item of the chat rooms ListView is clicked.
		/// </summary>
		private void ChatRoomsLV_ItemClick(object sender, ItemClickEventArgs e)
		{
			ChatRoomsLV.SelectedItem = e.ClickedItem;
			ChatRoomFrame.Navigate(typeof(ChatPage), e.ClickedItem);
		}

		private async void NewChatRoom_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			string peerSipAddress = await InputTextDialogAsync("Enter peer sip address");
			if (string.IsNullOrWhiteSpace(peerSipAddress))
			{
				return;
			}

			// We create a new ChatRoom with the address the user gave us.
			// See CoreService.CreateOrGetChatRoom(string sipAddress) for more info
			ChatRoom newChatRoom = CoreService.CreateOrGetChatRoom(peerSipAddress);

			if (newChatRoom != null)
			{
				// If the ChatRoom creation succeeded, render/navigate to a ChatPage in the inner
				// frame of the ChatsPage.
				// See ChatPage.xaml.cs to understand how to get message history and how to send/receive
				// and display new messages.
				ChatRoomFrame.Navigate(typeof(ChatPage), newChatRoom);
			}
			else
			{
				ContentDialog chatRoomCreationErrDialog = new ContentDialog
				{
					Title = "ChatRoom creation error",
					Content = "An error occurred during ChatRoom creation, check sip address validity and try again.",
					CloseButtonText = "OK"
				};

				await chatRoomCreationErrDialog.ShowAsync();
			}
		}

		/// <summary>
		/// Small utility method to display a dialog with an input text
		/// </summary>
		private async Task<string> InputTextDialogAsync(string title)
		{
			TextBox inputTextBox = new TextBox
			{
				AcceptsReturn = false,
				Height = 32
			};
			ContentDialog dialog = new ContentDialog
			{
				Content = inputTextBox,
				Title = title,
				IsSecondaryButtonEnabled = true,
				PrimaryButtonText = "OK",
				SecondaryButtonText = "Cancel"
			};
			if (await dialog.ShowAsync() == ContentDialogResult.Primary)
				return inputTextBox.Text;
			else
				return "";
		}
	}
}