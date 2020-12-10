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
using System.Linq;
using Windows.UI.Xaml.Controls;

namespace _06_GroupChat.Controls
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

			// We register to those callbacks so every time the participant list is
			// modified we can update our GUI, see OnParticipantListUpdate and UpdateList.
			ChatRoom.Listener.OnParticipantAdded += OnParticipantListUpdate;
			ChatRoom.Listener.OnParticipantRemoved += OnParticipantListUpdate;

			// Every time the admin status of one participant is changed this callback is called.
			// We use this to update GUI because we display the admin status of each participant,
			// see OnParticipantAdminStatusChanged and UpdateList. We also made a check to our admin
			// status on this ChatRoom to see if we have access to the different controls (rename chat
			// room, add/remove participant...)
			ChatRoom.Listener.OnParticipantAdminStatusChanged += OnParticipantAdminStatusChanged;
		}

		private void GroupChatDisplay_Unloaded(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			// Don't forget to unregister to avoid memory leak
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
			// We check out our admin status with ChatRoom.Me.IsAdmin and if we
			// aren't admin the controls are disabled.
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

			// You can find the participant list in the ChatRoom.Participants attribute.
			// You can note that the participant list doesn't contain yourself.
			foreach (Participant participant in ChatRoom.Participants)
			{
				if (participant.Address != null && !String.IsNullOrWhiteSpace(participant.Address.Username))
				{
					ParticipantsLV.Items.Add(participant);
				}
			}
		}

		/// <summary>
		/// This method is called when the remove button near a participant username is clicked.
		/// </summary>
		private void Remove_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			Participant participantToRemove = (Participant)((Button)sender).Tag;

			// To remove a participant simply use the RemoveParticipant(Participant participant) method
			// on a ChatRoom object. If you are admin and the participant is present in the ChatRoom he
			// will be removed.
			// The method RemoveParticipants(IEnumerable<Participant> participants) also exist if you want to
			// remove multiple participant at once.
			ChatRoom.RemoveParticipant(participantToRemove);
		}

		/// <summary>
		/// This method is called when the button to add a participant is clicked.
		/// </summary>
		private async void AddParticipant_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			string peerSipAddress = await Utils.InputTextDialogAsync("Enter peer sip address");
			Address address = CoreService.Core.InterpretUrl(peerSipAddress);
			if (address != null)
			{
				// To add a participant simply call the method AddParticipant(Address addr).
				// If you are admin and the participant have a device that can handle
				// group chat connected to the conference server he will be added.
				// You can use AddParticipants(IEnumerable<Address> addresses) to add multiple
				// participants at once.
				// Here we use Core.InterpretUrl to transform a string sip address to a valid
				// Linphone.Address object as we done multiple times before.
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

		/// <summary>
		/// This method is called when you switch the admin status of a participant
		/// </summary>
		private void AdminSwitch_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			Participant participantToUpgrade = (Participant)((Button)sender).Tag;

			// Use the SetParticipantAdminStatus(Participant participant, bool isAdmin) to change
			// the admin of a participant, you must be admin yourself if you want this action to work.
			ChatRoom.SetParticipantAdminStatus(participantToUpgrade, !participantToUpgrade.IsAdmin);
		}

		/// <summary>
		/// This method is called when the "Rename group chat" button is clicked
		/// </summary>
		private async void RenameGroupChat_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
		{
			string newName = await Utils.InputTextDialogAsync("Enter new name for group");

			// To change the subject of a ChatRoom simply update the Subject attribute of a ChatRoom.
			ChatRoom.Subject = newName;
		}
	}
}