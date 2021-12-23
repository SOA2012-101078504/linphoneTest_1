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

namespace _06_GroupChat.Controls
{
	public sealed partial class MessageDisplay : UserControl
	{
		private readonly ChatMessage ChatMessage;

		public MessageDisplay(ChatMessage message)
		{
			this.InitializeComponent();
			ChatMessage = message;
			UpdateLayoutFromMessage();
			UpdateLayoutFromContents();
		}

		private void MessageDisplay_Loaded(object sender, RoutedEventArgs e)
		{
			ChatMessage.Listener.OnMsgStateChanged += OnMessageStateChanged;
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
			// Here we keep only the informations kept at the ChatMessage level
			MessageState.Text = "The message state is : " + ChatMessage.State;
			ReceiveDate.Text = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddSeconds(ChatMessage.Time).ToLocalTime().ToString("HH:mm");
			SenderName.Text += ChatMessage.FromAddress.Username;

			if (ChatMessage.IsOutgoing)
			{
				HorizontalAlignment = HorizontalAlignment.Right;
			}
			else
			{
				HorizontalAlignment = HorizontalAlignment.Left;
			}
		}

		private void UpdateLayoutFromContents()
		{
			ContentsStack.Children.Clear();

			// We iterate over the Contents list to display all the contents
			// in a multipart message.
			// This code is the same for Basic and Flexisip ChatRoom so even if
			// another SIP client doesn't follow the basic chat room rules and
			// and sends multipart content we can display it.
			foreach (Content content in ChatMessage.Contents)
			{
				AddContent(content);
			}
		}

		private void AddContent(Content content)
		{
			// A Content object can itself be multipart
			if (content.IsMultipart)
			{
				// So we make this method recursive
				foreach (Content innerContent in content.Parts)
				{
					AddContent(innerContent);
				}
				return;
			}

			// And we create a content display for each content. You can look at the code
			// in content ContentDisplay.xaml(.cs).
			ContentDisplay contentDisplay = new ContentDisplay(content, ChatMessage);
			ContentsStack.Children.Add(contentDisplay);
		}
	}
}