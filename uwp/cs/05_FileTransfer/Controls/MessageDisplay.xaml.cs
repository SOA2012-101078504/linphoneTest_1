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
using System.IO;
using System.Linq;
using Windows.Storage;
using Windows.System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace _05_FileTransfer.Controls
{
	public sealed partial class MessageDisplay : UserControl
	{
		private readonly ChatMessage ChatMessage;
		private Content CurrentShownContent;

		public MessageDisplay(ChatMessage message)
		{
			this.InitializeComponent();
			// We link every MessageDisplay object to a ChatMessage.
			ChatMessage = message;
			UpdateLayoutFromMessage();
		}

		private void MessageDisplay_Loaded(object sender, RoutedEventArgs e)
		{
			// Like other Linphone objects you can register to a variety
			// of callbacks on a ChatMessage object (see ChatMessage.Listener for the list).
			// Here we want to be called when the message state is updated.
			ChatMessage.Listener.OnMsgStateChanged += OnMessageStateChanged;
		}

		private void MessageDisplay_Unloaded(object sender, RoutedEventArgs e)
		{
			// Again, don't forget to unregister to avoid memory leak.
			ChatMessage.Listener = null;
		}

		private void OnMessageStateChanged(ChatMessage message, ChatMessageState state)
		{
			// We display the message state. It can be really useful for the user
			// to know if the remote only received the message (state = Delivered) or
			// if they read it (state = Displayed)
			MessageState.Text = "The message state is : " + state;

			switch (state)
			{
				// A file transfer can be in multiple states (FileTransferInProgress,
				// FileTransferDone, FileTransferError). We update the layout if the file
				// is done downloading to replace the "Download" button by an "Open file" button.
				case ChatMessageState.FileTransferDone:
					UpdateLayoutFromMessage();
					return;
			}
		}

		private void UpdateLayoutFromMessage()
		{
			MessageState.Text = "The message state is : " + ChatMessage.State;

			// You can find the sending date of a ChatMessage in ChatMessage.Time.
			// The time number follows the time_t type specification. (Unix timestamp)
			ReceiveDate.Text = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddSeconds(ChatMessage.Time).ToLocalTime().ToString("HH:mm");

			if (ChatMessage.IsOutgoing)
			{
				this.HorizontalAlignment = HorizontalAlignment.Right;
			}
			else
			{
				this.HorizontalAlignment = HorizontalAlignment.Left;
			}

			// A ChatMessage holds a list of Content objects, Contents.
			// But in a basic ChatRoom, using a basic backend, by default the multipart
			// is disabled. So in any received message there is only one Content in the list.
			// You can enable multipart on a ChatRoom object with ChatRoom.AllowMultipart() but it
			// can be risky. In fact if your remote doesn't support multipart and you send them
			// a multipart message it could not work properly.
			if (ChatMessage.Contents.Any(c => c.IsFile))
			{
				// If the Content object isFile it means that it is an already
				// downloaded file, so we display the OpenFile button. See
				// this.OpenFile_Click to understand how to find the file from
				// the Content object.
				TextStack.Visibility = Visibility.Collapsed;
				FileStack.Visibility = Visibility.Visible;
				OpenFolder.Visibility = Visibility.Visible;
				Download.Visibility = Visibility.Collapsed;

				// We can do this because we don't allowMultipart and can assume
				// they're is only one element, and ChatMessage.Contents.Any(c => c.IsFile)
				// returned true.
				Content content = ChatMessage.Contents.First((c) => c.IsFile);

				// Here we are displaying the name and the size of the file
				FileName.Text = content.Name;
				FileSize.Text = content.FileSize + " bits";
				CurrentShownContent = content;
			}
			else if (ChatMessage.Contents.Any(c => c.IsFileTransfer))
			{
				// If the Content object IsFileTransfer it means that the file is
				// not downloaded yet, so we display the Download button. See
				// this.Download_Click to understand how to download the file from
				// the Content object.
				TextStack.Visibility = Visibility.Collapsed;
				FileStack.Visibility = Visibility.Visible;
				Download.Visibility = Visibility.Visible;
				OpenFolder.Visibility = Visibility.Collapsed;

				Content content = ChatMessage.Contents.First((c) => c.IsFileTransfer);

				FileName.Text = content.Name;
				FileSize.Text = content.FileSize + " bits";
				CurrentShownContent = content;
			}
			else if (ChatMessage.Contents.Any(c => c.IsText))
			{
				// If the content isText we only display the text value like before
				TextStack.Visibility = Visibility.Visible;
				FileStack.Visibility = Visibility.Collapsed;

				Content content = ChatMessage.Contents.First((c) => c.IsText);

				TextMessage.Text = content.Utf8Text;
				CurrentShownContent = null;
			}
		}

		/// <summary>
		/// Method called when the "Download" button is clicked
		/// </summary>
		private void Download_Click(object sender, RoutedEventArgs e)
		{
			if (CurrentShownContent != null)
			{
				Download.Visibility = Visibility.Collapsed;
				FileSize.Text = "Download in progress ...";

				// We create a directory where we have write rights.
				string downloadPathFolder = ApplicationData.Current.LocalFolder.Path + @"\Downloads\";
				Directory.CreateDirectory(downloadPathFolder);

				// We set the future file path before we start the download.
				CurrentShownContent.FilePath = downloadPathFolder + CurrentShownContent.Name;

				// And we use ChatMessage.DownloadContent(Content content) with
				// our Content object as parameter. The download is async and
				// you can follow the file transfer with OnFileTransferProgressIndicationDelegate
				// or simply wait the FileTransferDone state on the ChatMessage like we are
				// doing here.
				ChatMessage.DownloadContent(CurrentShownContent);
			}
		}

		private async void OpenFolder_Click(object sender, RoutedEventArgs e)
		{
			// Linphone can sometimes return paths with Unix-style forward slashes ('/').
			// System.IO.Path.* methods are made to deal with such paths.
			var folderPath = Path.GetDirectoryName(CurrentShownContent.FilePath);
			var folder = await StorageFolder.GetFolderFromPathAsync(folderPath);
			_ = await Launcher.LaunchFolderAsync(folder);
		}
	}
}