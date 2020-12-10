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

using _07_AdvancedChat.Service;
using Linphone;
using System;
using System.Collections.ObjectModel;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace _07_AdvancedChat.Views
{
	public sealed partial class CreateGroupChatRoom : Page
	{
		private CoreService CoreService { get; } = CoreService.Instance;

		private readonly ObservableCollection<Address> addresses = new ObservableCollection<Address>();

		public ObservableCollection<Address> DisplayedAddresses
		{
			get { return this.addresses; }
		}

		public CreateGroupChatRoom()
		{
			this.InitializeComponent();
		}

		private async void Create_Click(object sender, RoutedEventArgs e)
		{
			ChatRoom newChatRoom = CoreService.CreateGroupChatRoom(DisplayedAddresses, Subject.Text, SecureCheckBox.IsChecked ?? false);
			if (newChatRoom != null)
			{
				this.Frame.Navigate(typeof(ChatPage), newChatRoom);
			}
			else
			{
				ContentDialog noSettingsDialog = new ContentDialog
				{
					Title = "ChatRoom creation error",
					Content = "An error occurred during group ChatRoom creation, check sip addresses validity and try again.",
					CloseButtonText = "OK"
				};

				await noSettingsDialog.ShowAsync();
			}
		}

		private void AddAddress_Click(object sender, RoutedEventArgs e)
		{
			if (!String.IsNullOrWhiteSpace(Address.Text))
			{
				DisplayedAddresses.Add(CoreService.Core.InterpretUrl(Address.Text));
				AddressesLV.ItemsSource = DisplayedAddresses;
			}
		}
	}
}