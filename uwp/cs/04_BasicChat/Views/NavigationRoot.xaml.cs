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
using System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Navigation;

namespace _04_BasicChat.Views
{
	/// <summary>
	/// Introduced in step 02 IncomingCall
	/// </summary>
	public sealed partial class NavigationRoot : Page
	{
		private CoreService CoreService { get; } = CoreService.Instance;
		private NavigationService NavigationService { get; } = NavigationService.Instance;
		private bool hasLoadedPreviously;

		public NavigationRoot()
		{
			this.InitializeComponent();
		}

		protected override void OnNavigatedTo(NavigationEventArgs e)
		{
			base.OnNavigatedTo(e);
			this.CoreService.AddOnOnMessageReceivedDelegate(OnMessageReceived);
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			this.CoreService.RemoveOnOnMessageReceivedDelegate(OnMessageReceived);
			base.OnNavigatedFrom(e);
		}

		private void Page_Loaded(object sender, RoutedEventArgs e)
		{
			if (!hasLoadedPreviously)
			{
				AppNavFrame.Navigate(typeof(CallsPage));
				UpdateUnreadMessageCount();
				hasLoadedPreviously = true;
				NavigationService.CurrentNavigationRoot = this; // NEW!
			}
		}

		private void AppNavFrame_Navigated(object sender, NavigationEventArgs e)
		{
			switch (e.SourcePageType)
			{
				case Type _ when e.SourcePageType == typeof(CallsPage):
					((NavigationViewItem)navview.MenuItems[0]).IsSelected = true;
					break;

				// NEW!
				case Type _ when e.SourcePageType == typeof(ChatsPage):
					((NavigationViewItem)navview.MenuItems[1]).IsSelected = true;
					break;
			}
		}

		private async void Navview_ItemInvoked(NavigationView sender, NavigationViewItemInvokedEventArgs args)
		{
			if (args.IsSettingsInvoked)
			{
				ContentDialog noSettingsDialog = new ContentDialog
				{
					Title = "No settings",
					Content = "There are no settings in this little app",
					CloseButtonText = "OK"
				};
				_ = await noSettingsDialog.ShowAsync();
				return;
			}

			if (args.InvokedItem is string invokedItemValue && invokedItemValue.Contains("Calls"))
			{
				_ = AppNavFrame.Navigate(typeof(CallsPage));
			}
			else // NEW!
			{
				_ = AppNavFrame.Navigate(typeof(ChatsPage));
			}
		}

		private void SignOut_Tapped(object sender, TappedRoutedEventArgs e)
		{
			DisplaySignOutDialog();
		}

		private async void DisplaySignOutDialog()
		{
			ContentDialog signOutDialog = new ContentDialog
			{
				Title = "Sign out ?",
				Content = "All your current calls and actions will be canceled.",
				PrimaryButtonText = "Sign out",
				CloseButtonText = "Cancel"
			};

			ContentDialogResult result = await signOutDialog.ShowAsync();

			if (result == ContentDialogResult.Primary)
			{
				CoreService.Core.TerminateAllCalls();
				CoreService.LogOut();

				this.Frame.Navigate(typeof(LoginPage));
			}
		}

		// NEW!
		private void OnMessageReceived(Core core, ChatRoom chatRoom, ChatMessage message)
		{
			UpdateUnreadMessageCount();
		}

		// NEW!
		public void UpdateUnreadMessageCount()
		{
			// The property UnreadChatMessageCountFromActiveLocals gives the total
			// number of unread messages in all the chat rooms of all the connected accounts
			// on the device. In the tutorial we only allow one account at a time, so
			// you get the global unread message count for your account.
			if (CoreService.Core.UnreadChatMessageCountFromActiveLocals > 0)
			{
				NewMessageCount.Text = CoreService.Core.UnreadChatMessageCountFromActiveLocals.ToString();
				NewMessageCountBorder.Visibility = Visibility.Visible;
			}
			else
			{
				NewMessageCountBorder.Visibility = Visibility.Collapsed;
			}
		}
	}
}