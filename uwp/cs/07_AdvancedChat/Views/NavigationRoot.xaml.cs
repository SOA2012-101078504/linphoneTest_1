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

using _07_AdvancedChat.Service;
using Linphone;
using System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Navigation;

namespace _07_AdvancedChat.Views
{
	/// <summary>
	/// A really simple app for a first Login with LinphoneSDK x UWP
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
			this.CoreService.AddOnOnMessageReceivedDelegate(OnMessageReveive);
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			this.CoreService.RemoveOnOnMessageReceivedDelegate(OnMessageReveive);
			base.OnNavigatedFrom(e);
		}

		private void Page_Loaded(object sender, RoutedEventArgs e)
		{
			// Only do an inital navigate the first time the page loads
			// when we switch out of compactoverloadmode this will fire but we don't want to navigate because
			// there is already a page loaded
			if (!hasLoadedPreviously)
			{
				AppNavFrame.Navigate(typeof(CallsPage));
				UpdateUnreadMessageCount();
				hasLoadedPreviously = true;
				NavigationService.CurrentNavigationRoot = this;
			}
		}

		private void AppNavFrame_Navigated(object sender, NavigationEventArgs e)
		{
			switch (e.SourcePageType)
			{
				case Type c when e.SourcePageType == typeof(CallsPage):
					((NavigationViewItem)navview.MenuItems[0]).IsSelected = true;
					break;

				case Type c when e.SourcePageType == typeof(ChatsPage):
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
					Content = "There is no settings in this little app",
					CloseButtonText = "OK"
				};

				ContentDialogResult result = await noSettingsDialog.ShowAsync();
				return;
			}

			string invokedItemValue = args.InvokedItem as string;
			if (invokedItemValue != null && invokedItemValue.Contains("Calls"))
			{
				AppNavFrame.Navigate(typeof(CallsPage));
			}
			else
			{
				AppNavFrame.Navigate(typeof(ChatsPage));
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
				Content = "All your current calls and actions will be canceled, are you sure to continue ?",
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

		private void OnMessageReveive(Core core, ChatRoom chatRoom, ChatMessage message)
		{
			UpdateUnreadMessageCount();
		}

		public void UpdateUnreadMessageCount()
		{
			if (CoreService.Core.UnreadChatMessageCountFromActiveLocals > 0)
			{
				NewMessageCount.Text = "" + CoreService.Core.UnreadChatMessageCountFromActiveLocals;
				NewMessageCountBorder.Visibility = Visibility.Visible;
			}
			else
			{
				NewMessageCountBorder.Visibility = Visibility.Collapsed;
			}
		}
	}
}