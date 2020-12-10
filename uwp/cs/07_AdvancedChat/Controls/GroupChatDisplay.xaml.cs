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
using _07_AdvancedChat.Shared;
using Linphone;
using System;
using System.Linq;
using Windows.UI.Xaml.Controls;

namespace _07_AdvancedChat.Controls
{
	public sealed partial class GroupChatDisplay : UserControl
	{
		private CoreService CoreService { get; } = CoreService.Instance;

		private readonly ChatRoom ChatRoom;

		public GroupChatDisplay(ChatRoom chatRoom)
		{
			this.InitializeComponent();
			ChatRoom = chatRoom;
		}

		private void GroupChatDisplay_Loaded(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			UpdateList();
			UpdateGuiFromAdminState();

			ChatRoom.Listener.OnParticipantAdded += OnParticipantListUpdate;
			ChatRoom.Listener.OnParticipantRemoved += OnParticipantListUpdate;
			ChatRoom.Listener.OnParticipantAdminStatusChanged += OnParticipantAdminStatusChanged;
		}

		private void GroupChatDisplay_Unloaded(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			ChatRoom.Listener.OnParticipantAdded -= OnParticipantListUpdate;
			ChatRoom.Listener.OnParticipantRemoved -= OnParticipantListUpdate;
			ChatRoom.Listener.OnParticipantAdminStatusChanged -= OnParticipantAdminStatusChanged;
		}

		private void OnParticipantAdminStatusChanged(ChatRoom chatRoom, EventLog eventLog)
		{
			UpdateList();
			UpdateGuiFromAdminState();
		}

		private void UpdateGuiFromAdminState()
		{
			AddParticipant.IsEnabled = ChatRoom.Me.IsAdmin;
			foreach (var control in GroupChatDisplayGrid.Children.OfType<Control>())
			{
				control.IsEnabled = ChatRoom.Me.IsAdmin;
			}
		}

		private void OnParticipantListUpdate(ChatRoom chatRoom, EventLog eventLog) => UpdateList();

		private void UpdateList()
		{
			ParticipantsLV.Items.Clear();
			foreach (Participant participant in ChatRoom.Participants)
			{
				if (participant.Address != null && !String.IsNullOrWhiteSpace(participant.Address.Username))
				{
					ParticipantsLV.Items.Add(participant);
				}
			}
		}

		private void Remove_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			Participant participantToRemove = (Participant)((Button)sender).Tag;
			ChatRoom.RemoveParticipant(participantToRemove);
		}

		private async void AddParticipant_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			string peerSipAddress = await Utils.InputTextDialogAsync("Enter peer sip address");
			Address address = CoreService.Core.InterpretUrl(peerSipAddress);
			if (address != null)
			{
				ChatRoom.AddParticipant(address);
			}
			else
			{
				ContentDialog badAddressDialog = new ContentDialog
				{
					Title = "Adding participant failed",
					Content = "An error occurred during address interpretation, check sip address validity and try again.",
					CloseButtonText = "OK"
				};

				await badAddressDialog.ShowAsync();
			}
		}

		private void AdminSwitch_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			Participant participantToUpgrade = (Participant)((Button)sender).Tag;
			ChatRoom.SetParticipantAdminStatus(participantToUpgrade, !participantToUpgrade.IsAdmin);
		}

		private async void RenameGroupChat_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			string newName = await Utils.InputTextDialogAsync("Enter new name for group");
			ChatRoom.Subject = newName;
		}
	}
}