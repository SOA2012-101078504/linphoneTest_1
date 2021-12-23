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
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using Windows.Storage;
using Windows.System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Input;

namespace _01_AccountLogin
{
	/// <summary>
	/// A really simple page for a first Login with LinphoneSDK x UWP
	/// </summary>
	public sealed partial class MainPage : Page
	{
		private Core StoredCore { get; set; }

		private LoggingService LoggingService { get; set; }

		private Timer Timer;

		public MainPage()
		{
			InitializeComponent();

			// Core is the main object of the SDK. You can't do much without it
			// If you're not familiar with Linphone Core creation, see the 00_HelloWorld project.
			LoggingService = LoggingService.Instance;
			LoggingService.LogLevel = LogLevel.Debug;
			LoggingService.Listener.OnLogMessageWritten = OnLog;

			Factory factory = Factory.Instance;

			string assetsPath = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "Assets");
			factory.TopResourcesDir = assetsPath;
			factory.DataResourcesDir = assetsPath;
			factory.SoundResourcesDir = Path.Combine(assetsPath, "sounds", "linphone");
			factory.RingResourcesDir = Path.Combine(factory.SoundResourcesDir, "rings");
			factory.ImageResourcesDir = Path.Combine(assetsPath, "images");
			factory.MspluginsDir = ".";

			Core core = factory.CreateCore("", "", IntPtr.Zero);

			StoredCore = core;

			// We need to indicate to the core where to find the root and user certificates, for future TLS exchange.
			StoredCore.RootCa = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "share", "Linphone", "rootca.pem");
			StoredCore.UserCertificatesPath = ApplicationData.Current.LocalFolder.Path;

			// In this tutorial we are going to log in and our registration state will change.
			// Here we show you how to register a delegate method called every time the
			// OnAccountRegistrationStateChanged callback is triggered.
			StoredCore.Listener.OnAccountRegistrationStateChanged += OnAccountRegistrationStateChanged;

			// Start the core after setup, and before everything else.
			StoredCore.Start();
			StoredCore.AutoIterateEnabled = true;

			// The method Iterate must be permanently called on our core.
			// The Iterate method runs all the waiting backgrounds tasks and poll networks notifications.
			// Here how to setup a function called every 20ms, 20ms after the Timer object instantiation.
			// See OnTimedEvent for more informations.
			Timer = new Timer(OnTimedEvent, null, 20, 20);

			// Setup GUI
			Identity.Text = "sip:";
			Password.PlaceholderText = "myPasswd";
			LogoutGuiChanges();

			// Now use the GUI to log in, and see LogInClick to see how to handle login.
		}

		/// <summary>
		/// Here we scheduled a callback to the Iterate method on the UI thread. While the
		/// Linphone API calls are not thread safe, we ensure all our callbacks are done on the UI thread.
		/// Doing this, we allow callbacks to manipulate UI without dispatcher.
		/// </summary>
		private async void OnTimedEvent(object state)
		{
			await Dispatcher.RunAsync(Windows.UI.Core.CoreDispatcherPriority.Normal, () =>
			{
				StoredCore.Iterate();
			});
		}

		/// <summary>
		/// Called when you click on the "Login" button.
		/// </summary>
		private void LogInClick(object sender, RoutedEventArgs e)
		{
			if (LogIn.IsEnabled)
			{
				LogIn.IsEnabled = false;

				// To configure a SIP account, we need an Account object and an AuthInfo object
				// The first one is how to connect to the proxy server, the second one stores the credentials

				// Here we are creating an AuthInfo object from the identity Address and password provided by the user.
				Address address = Factory.Instance.CreateAddress(Identity.Text);
				// The AuthInfo can be created from the Factory as it's only a data class
				// userID is set to null as it's the same as the username in our case
				// ha1 is set to null as we are using the clear text password. Upon first register, the hash will be computed automatically.
				// The realm will be determined automatically from the first register, as well as the algorithm
				AuthInfo authInfo = Factory.Instance.CreateAuthInfo(address.Username, "", Password.Password, "", "", address.Domain);
				// And we add it to the Core
				StoredCore.AddAuthInfo(authInfo);

				// Then we create an AccountParams object.
				// It contains the account informations needed by the core
				AccountParams accountParams = StoredCore.CreateAccountParams();
				// A SIP account is identified by an identity address that we can construct from the username and domain
				accountParams.IdentityAddress = address;
				// We also need to configure where the proxy server is located
				Address serverAddr = Factory.Instance.CreateAddress("sip:" + address.Domain);
				// We use the Address object to easily set the transport protocol
				if (TlsRadio.IsChecked == true) {
					serverAddr.Transport = TransportType.Tls;
				}
				else if (TcpRadio.IsChecked == true)
				{
					serverAddr.Transport = TransportType.Tcp;
				}
				else
				{
					serverAddr.Transport = TransportType.Udp;
				}
				accountParams.ServerAddress = serverAddr;
				// If RegisterEnabled is set to true, when this account will be added to the core it will
				// automatically try to connect.
				accountParams.RegisterEnabled = true;

				// We can now create an Account object from the AccountParams ...
				Account account = StoredCore.CreateAccount(accountParams);
				// ... and add it to the core, launching the connection process.
				StoredCore.AddAccount(account);
				// Also set the newly added account as default
				StoredCore.DefaultAccount = account;
			}
		}

		/// <summary>
		/// Called when a key is pressed and released on the login page.
		/// If you pressed "Enter", simulate a login click.
		/// </summary>
		private void GridKeyUp(object sender, KeyRoutedEventArgs e)
		{
			if (VirtualKey.Enter.Equals(e.Key))
			{
				LogInClick(null, null);
			}
		}

		/// <summary>
		/// Called when you click on the "Logout" button.
		/// </summary>
		private void LogOutClick(object sender, RoutedEventArgs e)
		{
			if (LogOut.IsEnabled)
			{
				LogOut.IsEnabled = false;

				// Setting RegisterEnabled to false on a connected Account object will
				// launch the logout action.
				Account account = StoredCore.DefaultAccount;
				if (account != null)
				{
					// BUT BE CAREFUL : the Params attribute of an account is read-only
					// You MUST Clone it :
					AccountParams accountParams = account.Params.Clone();
					// Then you can modify the clone :
					accountParams.RegisterEnabled = false;
					// And finally setting the new Params value triggers the changes, here the logout.
					account.Params = accountParams;
				}
			}
		}

		/// <summary>
		/// This method is called every time the RegistrationState is updated by background core's actions.
		/// In this example we use this to update the GUI.
		/// </summary>
		private void OnAccountRegistrationStateChanged(Core core, Account account, RegistrationState state, string message)
		{
			RegistrationText.Text = "Your registration state is : " + state.ToString();
			switch (state)
			{
				// If the Account was logged out, we clear the Core.
				case RegistrationState.Cleared:
				case RegistrationState.None:
					StoredCore.ClearAllAuthInfo();
					StoredCore.ClearAccounts();
					LogoutGuiChanges();
					break;

				case RegistrationState.Ok:
					LoginGuiChanges();
					break;

				case RegistrationState.Progress:
					LoginInProgressGuiChanges();
					break;

				case RegistrationState.Failed:
					LoginFailedChanges();
					break;

				default:
					break;
			}
		}

		private void LogoutGuiChanges()
		{
			LogIn.IsEnabled = true;
			LogOut.IsEnabled = false;
			LoginText.Text = "You are logged out";
		}

		private void LoginFailedChanges()
		{
			LogIn.IsEnabled = true;
			LogOut.IsEnabled = false;
			LoginText.Text = "Login failed, try again";
		}

		private void LoginGuiChanges()
		{
			LogIn.IsEnabled = false;
			LogOut.IsEnabled = true;
			LoginText.Text = "You are logged in, with identity " + StoredCore.Identity + ".";
		}

		private void LoginInProgressGuiChanges()
		{
			LogIn.IsEnabled = false;
			LogOut.IsEnabled = false;
			LoginText.Text = "Login in progress, with identity " + StoredCore.Identity + ".";
		}

		private void OnLog(LoggingService logService, string domain, LogLevel lev, string message)
		{
			StringBuilder builder = new StringBuilder();
			_ = builder.Append("Linphone-[").Append(lev.ToString()).Append("](").Append(domain).Append(")").Append(message);
			Debug.WriteLine(builder.ToString());
		}
	}
}