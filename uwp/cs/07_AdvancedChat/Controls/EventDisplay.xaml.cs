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

using Linphone;
using Windows.UI.Xaml.Controls;

namespace _07_AdvancedChat.Controls
{
	public sealed partial class EventDisplay : UserControl
	{
		public EventDisplay(EventLog eventLog)
		{
			this.InitializeComponent();
			switch (eventLog.Type)
			{
				case EventLogType.ConferenceCreated:
					EventText.Text = $"The conference {eventLog.Subject} is created";
					break;

				case EventLogType.ConferenceTerminated:
					EventText.Text = $"The conference {eventLog.Subject} is terminated";
					break;

				case EventLogType.ConferenceCallStart:
					EventText.Text = "Call start";
					break;

				case EventLogType.ConferenceCallEnd:
					EventText.Text = "Call end";
					break;

				case EventLogType.ConferenceParticipantAdded:
					EventText.Text = $"{eventLog.ParticipantAddress.Username} is added";
					break;

				case EventLogType.ConferenceParticipantRemoved:
					EventText.Text = $"{eventLog.ParticipantAddress.Username} is removed";
					break;

				case EventLogType.ConferenceParticipantSetAdmin:
					EventText.Text = $"{eventLog.ParticipantAddress.Username} is now admin";
					break;

				case EventLogType.ConferenceParticipantUnsetAdmin:
					EventText.Text = $"{eventLog.ParticipantAddress.Username} admin status removed";
					break;

				case EventLogType.ConferenceSubjectChanged:
					EventText.Text = $"The conference subject is now {eventLog.Subject}";
					break;

				// With the ephemeral mode handling new event types can appear.
				case EventLogType.ConferenceEphemeralMessageDisabled:
					EventText.Text = "Ephemeral message mode is disabled";
					break;

				case EventLogType.ConferenceEphemeralMessageEnabled:
					EventText.Text = "Ephemeral message mode is enabled";
					break;

				case EventLogType.ConferenceEphemeralMessageLifetimeChanged:
					EventText.Text = $"Ephemeral message lifetime is now {eventLog.EphemeralMessageLifetime}";
					break;
			}
		}
	}
}