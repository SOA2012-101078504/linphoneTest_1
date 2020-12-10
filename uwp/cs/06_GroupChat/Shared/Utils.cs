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

using System;
using System.Threading.Tasks;
using Windows.UI.Xaml.Controls;

namespace _06_GroupChat.Shared
{
	public class Utils
	{
		public static async Task<string> InputTextDialogAsync(string title)
		{
			TextBox inputTextBox = new TextBox
			{
				AcceptsReturn = false,
				Height = 32
			};
			ContentDialog dialog = new ContentDialog
			{
				Content = inputTextBox,
				Title = title,
				IsSecondaryButtonEnabled = true,
				PrimaryButtonText = "OK",
				SecondaryButtonText = "Cancel"
			};
			if (await dialog.ShowAsync() == ContentDialogResult.Primary)
				return inputTextBox.Text;
			else
				return "";
		}
	}
}