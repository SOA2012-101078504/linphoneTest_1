﻿/*
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
using Windows.Storage;
using Windows.System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace _06_GroupChat.Controls
{
	public sealed partial class ContentDisplay : UserControl
	{
		private readonly ChatMessage ChatMessage;
		private readonly Content DisplayedContent;

		public ContentDisplay(Content content, ChatMessage chatMessage)
		{
			this.InitializeComponent();
			DisplayedContent = content;
			ChatMessage = chatMessage;
			UpdateLayoutFromContent();
		}

		private void UpdateLayoutFromContent()
		{
			// We kept the code from the old MessageDisplay class. Working
			// with a single object instead of a List of content makes it
			// cleaner.
			if (DisplayedContent.IsFile || DisplayedContent.IsFileTransfer)
			{
				TextStack.Visibility = Visibility.Collapsed;
				FileStack.Visibility = Visibility.Visible;

				FileName.Text = DisplayedContent.Name;
				FileSize.Text = DisplayedContent.FileSize + " bits";

				if (DisplayedContent.IsFile || (DisplayedContent.IsFileTransfer && ChatMessage.IsOutgoing))
				{
					OpenFolder.Visibility = Visibility.Visible;
					Download.Visibility = Visibility.Collapsed;
				}
				else
				{
					Download.Visibility = Visibility.Visible;
					OpenFolder.Visibility = Visibility.Collapsed;
				}
			}
			else if (DisplayedContent.IsText)
			{
				TextStack.Visibility = Visibility.Visible;
				FileStack.Visibility = Visibility.Collapsed;
				TextMessage.Text = DisplayedContent.Utf8Text;
			}
		}

		// The download and open file click method are the same as before
		private void Download_Click(object sender, RoutedEventArgs e)
		{
			Download.Visibility = Visibility.Collapsed;
			FileSize.Text = "Download in progress ...";

			string downloadPathFolder = ApplicationData.Current.LocalFolder.Path + @"\Downloads\";
			Directory.CreateDirectory(downloadPathFolder);
			DisplayedContent.FilePath = downloadPathFolder + DisplayedContent.Name;

			ChatMessage.DownloadContent(DisplayedContent);
		}

		private async void OpenFolder_Click(object sender, RoutedEventArgs e)
		{
			var folderPath = Path.GetDirectoryName(DisplayedContent.FilePath);
			var folder = await StorageFolder.GetFolderFromPathAsync(folderPath);
			_ = await Launcher.LaunchFolderAsync(folder);
		}
	}
}