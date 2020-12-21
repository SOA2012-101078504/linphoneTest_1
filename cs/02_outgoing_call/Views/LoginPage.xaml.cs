/*
 * Copyright (c) 2010-2020 Belledonne Communications SARL.
 *
 * This file is part of mediastreamer2.
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

using _02_outgoing_call.Service;
using Linphone;
using Windows.System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Navigation;


namespace _02_outgoing_call.Views
{
	/// <summary>
	/// A really simple app for a first Login with LinphoneSDK x UWP
	/// </summary>
	public sealed partial class LoginPage : Page
	{
		private CoreService CoreService { get; } = CoreService.Instance;

		public LoginPage()
		{
			this.InitializeComponent();

			CoreService.AddOnRegistrationStateChangedDelegate(OnRegistrationStateChanged);
		}



		/// <summary>
		/// Called when you click on the "Login" button.
		/// </summary>
		private void LogInClick(object sender, RoutedEventArgs e)
		{
			if (LogIn.IsEnabled)
			{
				LogIn.IsEnabled = false;

				CoreService.LogIn(Identity.Text, Password.Password);
			}
		}

		/// <summary>
		/// Called when a key is pressed and released on the login page.
		/// If you pressed "Enter", simulate a login click.
		/// </summary>
		void GridKeyUp(object sender, KeyRoutedEventArgs e)
		{
			if (VirtualKey.Enter.Equals(e.Key))
			{
				LogInClick(null, null);
			}
		}

		/// <summary>
		/// This method is called every time the RegistrationState is updated by background core's actions.
		/// In this example we use this to update the GUI.
		/// </summary>
		private void OnRegistrationStateChanged(Core core, ProxyConfig proxyConfig, RegistrationState state, string message)
		{
			RegistrationText.Text = "You're registration state is : " + state.ToString();
			switch (state)
			{
				case RegistrationState.Cleared:
				case RegistrationState.None:
					CoreService.ClearCoreAfterLogOut();
					LogIn.IsEnabled = true;
					break;
				case RegistrationState.Ok:
					LogIn.IsEnabled = false;
					this.Frame.Navigate(typeof(OutgoingCallsPage));
					break;
				case RegistrationState.Progress:
					LogIn.IsEnabled = false;
					break;
				case RegistrationState.Failed:
					LogIn.IsEnabled = true;
					break;
				default:
					break;
			}
		}
	}
}
