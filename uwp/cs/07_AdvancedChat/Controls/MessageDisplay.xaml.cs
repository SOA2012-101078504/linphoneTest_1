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
using System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace _07_AdvancedChat.Controls
{
	public sealed partial class MessageDisplay : UserControl
	{
		private readonly ChatMessage ChatMessage;

		private readonly DispatcherTimer Timer;
		private int Basetime;

		public MessageDisplay(ChatMessage message)
		{
			this.InitializeComponent();
			ChatMessage = message;
			UpdateLayoutFromMessage();
			UpdateLayoutFromContents();

			// Used to create a second by second count down.
			Timer = new DispatcherTimer
			{
				Interval = new TimeSpan(0, 0, 1)
			};
			Timer.Tick += Timer_Tick;
		}

		private void MessageDisplay_Loaded(object sender, RoutedEventArgs e)
		{
			ChatMessage.Listener.OnMsgStateChanged += OnMessageStateChanged;

			// The countdown for ephemeral lifetime start only when the message status is "Displayed".
			// So we register to this callback to be notified when to start the countdown.
			// See OnEphemeralMessageTimerStarted to see how we setup the countdown.
			ChatMessage.Listener.OnEphemeralMessageTimerStarted += OnEphemeralMessageTimerStarted;

			// Even if we setup a client side countdown we will be notified by the OnEphemeralMessageDeleted
			// callback when we should destroy the message.
			ChatMessage.Listener.OnEphemeralMessageDeleted += OnEphemeralMessageDeleted;
		}

		private void MessageDisplay_Unloaded(object sender, RoutedEventArgs e)
		{
			ChatMessage.Listener = null;
		}

		private void OnMessageStateChanged(ChatMessage message, ChatMessageState state)
		{
			MessageState.Text = "The message state is : " + state;

			switch (state)
			{
				case ChatMessageState.FileTransferError:
				case ChatMessageState.FileTransferDone:
					UpdateLayoutFromContents();
					return;
			}
		}

		private void UpdateLayoutFromMessage()
		{
			MessageState.Text = "The message state is : " + ChatMessage.State;
			ReceiveDate.Text = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddSeconds(ChatMessage.Time).ToLocalTime().ToString("HH:mm");
			SenderName.Text += ChatMessage.FromAddress.Username;

			if (ChatMessage.IsOutgoing)
			{
				this.HorizontalAlignment = HorizontalAlignment.Right;
			}
			else
			{
				this.HorizontalAlignment = HorizontalAlignment.Left;
			}
		}

		private void UpdateLayoutFromContents()
		{
			ContentsStack.Children.Clear();

			foreach (Content content in ChatMessage.Contents)
			{
				AddContent(content);
			}
		}

		private void AddContent(Content content)
		{
			if (content.IsMultipart)
			{
				foreach (Content innerContent in content.Parts)
				{
					AddContent(innerContent);
				}
				return;
			}

			ContentDisplay contentDisplay = new ContentDisplay(content, ChatMessage);
			ContentsStack.Children.Add(contentDisplay);
		}

		private void OnEphemeralMessageTimerStarted(ChatMessage message)
		{
			// Here we create a basic timer with the windows UI library, you can
			// just note that we can found the ephemeral lifetime of this message
			// as a read only attribute (ChatMessage.EphemeralLifetime).
			Basetime = ChatMessage.EphemeralLifetime;
			EphemeralLifetime.Text = $"{Basetime.ToString()} remaining before deletion";

			// See Timer_Tick
			Timer.Start();
		}

		private void OnEphemeralMessageDeleted(ChatMessage message)
		{
			// When this callback is triggered we erase the message from the view.
			// Be careful, if you communicate with different clients some can choose
			// to keep the message displayed even if it was an ephemeral one !
			this.Content = new TextBlock
			{
				Text = "deleted ephemeral message"
			};
		}

		private void Timer_Tick(object sender, object e)
		{
			// Every second we update the text under the ephemeral message
			Basetime -= 1;
			EphemeralLifetime.Text = $"{Basetime} remaining before deletion";
			if (Basetime == 0)
			{
				Timer.Stop();
			}
		}
	}
}