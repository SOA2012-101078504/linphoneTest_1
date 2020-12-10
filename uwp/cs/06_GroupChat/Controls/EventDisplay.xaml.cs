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

namespace _06_GroupChat.Controls
{
	public sealed partial class EventDisplay : UserControl
	{
		public EventDisplay(EventLog eventLog)
		{
			// An EventDisplay is always linked to an EventLog object and is displayed at the center
			// of the message list.
			this.InitializeComponent();

			// After we simply create the text we want to display based on the type on event
			// and from information we get from the EventLog object.
			switch (eventLog.Type)
			{
				case EventLogType.ConferenceCreated:
					// For example here we use the Subject attribute to display the name of the conference
					// when it is created.
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
					// Or you can access a ParticipantAddress attribute when the type of
					// event is linked to a participant.
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
			}
		}
	}
}