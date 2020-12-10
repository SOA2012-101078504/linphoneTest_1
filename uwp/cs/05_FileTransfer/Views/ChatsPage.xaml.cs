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

using _05_FileTransfer.Service;
using Linphone;
using System;
using System.Threading.Tasks;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _05_FileTransfer.Views
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
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			NavigationService.CurrentChatspage = null;
			CoreService.RemoveOnOnMessageReceivedDelegate(OnMessageReceiveOrSent);
			CoreService.RemoveOnMessageSentDelegate(OnMessageReceiveOrSent);
			base.OnNavigatedFrom(e);
		}

		private void OnMessageReceiveOrSent(Core core, ChatRoom chatRoom, ChatMessage message) => UpdateChatRooms();

		public void UpdateChatRooms()
		{
			ChatRoom selectedChatRoom = (ChatRoom)ChatRoomsLV.SelectedItem;
			ChatRoomsLV.Items.Clear();

			foreach (ChatRoom chatRoom in CoreService.Core.ChatRooms)
			{
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

		private void ChatRoomsLV_ItemClick(object sender, ItemClickEventArgs e)
		{
			ChatRoomsLV.SelectedItem = e.ClickedItem;
			ChatRoomFrame.Navigate(typeof(ChatPage), e.ClickedItem);
		}

		private async void NewChatRoom_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			string peerSipAddress = await InputTextDialogAsync("Enter peer sip address");
			if (!String.IsNullOrWhiteSpace(peerSipAddress))
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