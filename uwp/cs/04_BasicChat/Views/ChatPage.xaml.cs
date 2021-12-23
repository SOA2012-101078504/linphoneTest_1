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

using _04_BasicChat.Service;
using Linphone;
using System.Linq;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _04_BasicChat.Views
{
	public sealed partial class ChatPage : Page
	{
		private NavigationService NavigationService { get; } = NavigationService.Instance;

		private ChatRoom ChatRoom;

		public ChatPage()
		{
			this.InitializeComponent();
		}

		protected override void OnNavigatedTo(NavigationEventArgs e)
		{
			base.OnNavigatedTo(e);
			ChatRoom = (ChatRoom)e.Parameter;

			// The ChatRoom also offers to register to some callbacks.
			// One of them is OnMessageReceived, like the one we used
			// on the core (Core.Listener.OnMessageReceived) but this one
			// is triggered only when the message received is part of this
			// ChatRoom.
			ChatRoom.Listener.OnMessageReceived += OnMessageReceived;

			// The method GetHistory gets all the ChatMessage's you have
			// in your local database for this ChatRoom. GetHistory(0)
			// means 'all of them', but you can specify a max number of messages.
			foreach (ChatMessage chatMessage in ChatRoom.GetHistory(0))
			{
				// See AddMessage(ChatMessage chatMessage) to see how we display messages
				AddMessage(chatMessage);
			}

			// Mark all the messages in the ChatRoom as read, if some messages
			// weren't, this will send read notifications to the remote.
			ChatRoom.MarkAsRead();

			// Only here to update display of unread message count on parent frames.
			// See NavigationRoot.UpdateUnreadMessageCount() to see how to get a
			// global unread message count.
			NavigationService.CurrentNavigationRoot.UpdateUnreadMessageCount();
			NavigationService.CurrentChatspage.UpdateChatRooms();

			// We can find all the info from the peer in the PeerAddress attribute
			// of a ChatRoom object.
			ChatHeaderText.Text += ChatRoom.PeerAddress.Username;
			PeerUsername.Text += ChatRoom.PeerAddress.Username;
			// And yours in LocalAddress.
			YourUsername.Text += ChatRoom.LocalAddress.Username;
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			// Don't forget to unregister delegate to avoid memory leak
			ChatRoom.Listener = null;
		}

		/// <summary>
		/// Delegate method called every time a message is received in this chat room.
		/// </summary>
		private void OnMessageReceived(ChatRoom chatRoom, ChatMessage message)
		{
			if (ChatRoom != null)
			{
				AddMessage(message);
				chatRoom.MarkAsRead();
			}
		}

		private void AddMessage(ChatMessage chatMessage)
		{
			TextBlock textBlock = new TextBlock();

			// You can find a lot of information on a ChatMessage object.
			// Here we use the IsOutgoing info to choose which side
			// of the frame the message should be displayed on.
			if (chatMessage.IsOutgoing)
			{
				textBlock.HorizontalAlignment = HorizontalAlignment.Right;
			}
			else
			{
				textBlock.HorizontalAlignment = HorizontalAlignment.Left;
			}

			// We take the first element of the Contents list of our ChatMessage. To keep
			// it simple we assume that we only send simple text message, we will talk more about multipart
			// messages and other types of messagse in the next step.
			// For now we only handle chat messages with a single content item, so we can find our text in
			// chatMessage.Contents.First().Utf8Text.
			// We wrap in a dollar string because if the message is e.g. a file transfer, the Utf8Text can be null.
			textBlock.Text = $"{chatMessage.Contents.First().Utf8Text}";

			MessagesList.Children.Add(textBlock);

			ScrollToBottom();
		}

		private void ScrollToBottom()
		{
			MessagesScroll.UpdateLayout();
			MessagesScroll.ChangeView(1, MessagesScroll.ExtentHeight, 1);
		}

		/// <summary>
		/// Method called when the "Send" button is clicked
		/// </summary>
		private void OutgoingMessageButton_Click(object sender, RoutedEventArgs e)
		{
			if (ChatRoom != null && OutgoingMessageText.Text != null && OutgoingMessageText.Text.Length > 0)
			{
				// We use the ChatRoom to create a new ChatMessage object.
				ChatMessage chatMessage = ChatRoom.CreateMessage(OutgoingMessageText.Text);

				// And simply call the Send() method to send the message.
				chatMessage.Send();

				AddMessage(chatMessage);
			}
			OutgoingMessageText.Text = "";
		}
	}
}