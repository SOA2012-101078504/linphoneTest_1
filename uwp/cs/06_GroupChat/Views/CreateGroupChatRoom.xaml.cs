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
using Linphone;
using System;
using System.Collections.ObjectModel;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace _06_GroupChat.Views
{
	public sealed partial class CreateGroupChatRoom : Page
	{
		private CoreService CoreService { get; } = CoreService.Instance;

		private readonly ObservableCollection<Address> addresses = new ObservableCollection<Address>();

		public ObservableCollection<Address> DisplayedAddresses
		{
			get { return addresses; }
		}

		public CreateGroupChatRoom()
		{
			InitializeComponent();
		}

		private async void Create_Click(object sender, RoutedEventArgs e)
		{
			// The purpose of this page is to allow the user to choose the subject of
			// their group chat room and to prepare the list of participants.
			// With these two things we can create a group chat room, see CoreService.CreateGroupChatRoom
			// to learn how to create it !
			ChatRoom newChatRoom = CoreService.CreateGroupChatRoom(DisplayedAddresses, Subject.Text);
			if (newChatRoom != null)
			{
				Frame.Navigate(typeof(ChatPage), newChatRoom);
			}
			else
			{
				ContentDialog errorDialog = new ContentDialog
				{
					Title = "ChatRoom creation error",
					Content = "An error occurred during group ChatRoom creation, check sip addresses validity and try again.",
					CloseButtonText = "OK"
				};

				await errorDialog.ShowAsync();
			}
		}

		private void AddAddress_Click(object sender, RoutedEventArgs e)
		{
			if (!string.IsNullOrWhiteSpace(Address.Text))
			{
				DisplayedAddresses.Add(CoreService.Core.InterpretUrl(Address.Text));
				AddressesLV.ItemsSource = DisplayedAddresses;
			}
		}
	}
}