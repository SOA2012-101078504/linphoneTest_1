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

using _06_GroupChat.Service;
using _06_GroupChat.Shared;
using Linphone;
using System;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _06_GroupChat.Views
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
			NavigationService.CurrentChatspage = this;
			UpdateChatRooms();
			CoreService.AddOnOnMessageReceivedDelegate(OnMessageReceiveOrSent);
			CoreService.AddOnMessageSentDelegate(OnMessageReceiveOrSent);

			// We registered this callback to update the list with the new
			// name when a chat room subject is changed.
			CoreService.AddOnChatRoomSubjectChangedDelegate(AddOnChatRoomSubjectChanged);
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			NavigationService.CurrentChatspage = null;
			CoreService.RemoveOnOnMessageReceivedDelegate(OnMessageReceiveOrSent);
			CoreService.RemoveOnMessageSentDelegate(OnMessageReceiveOrSent);
			CoreService.RemoveOnChatRoomSubjectChangedDelegate(AddOnChatRoomSubjectChanged);
			base.OnNavigatedFrom(e);
		}

		private void OnMessageReceiveOrSent(Core core, ChatRoom chatRoom, ChatMessage message) => UpdateChatRooms();

		private void AddOnChatRoomSubjectChanged(Core core, ChatRoom chatRoom) => UpdateChatRooms(); // NEW!

		public void UpdateChatRooms()
		{
			ChatRoom selectedChatRoom = (ChatRoom)ChatRoomsLV.SelectedItem;
			ChatRoomsLV.Items.Clear();

			foreach (ChatRoom chatRoom in CoreService.Core.ChatRooms)
			{
				if (chatRoom.HistoryEventsSize > 0)
				{
					ChatRoomsLV.Items.Add(chatRoom);
					if (selectedChatRoom == chatRoom)
					{
						ChatRoomsLV.SelectedItem = chatRoom;
					}
				}
			}
		}

		private void ChatRoomsLV_ItemClick(object sender, ItemClickEventArgs e)
		{
			ChatRoomsLV.SelectedItem = e.ClickedItem;
			ChatRoomFrame.Navigate(typeof(ChatPage), e.ClickedItem);
		}

		private async void NewChatRoom_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			string peerSipAddress = await Utils.InputTextDialogAsync("Enter peer sip address");
			if (!string.IsNullOrWhiteSpace(peerSipAddress))
			{
				ChatRoom newChatRoom = CoreService.CreateOrGetChatRoom(peerSipAddress);
				if (newChatRoom != null)
				{
					ChatRoomFrame.Navigate(typeof(ChatPage), newChatRoom);
				}
				else
				{
					ContentDialog noSettingsDialog = new ContentDialog
					{
						Title = "ChatRoom creation error",
						Content = "An error occurred during ChatRoom creation, check sip address validity and try again.",
						CloseButtonText = "OK"
					};

					await noSettingsDialog.ShowAsync();
				}
			}
		}

		private void NewGroupChatRoom_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			// To create a new group chat room you need a list of participants and a subject.
			// See CreateGroupChatRoom.xaml(.cs) to see how to create a group chat room.
			ChatRoomFrame.Navigate(typeof(CreateGroupChatRoom));
		}
	}
}