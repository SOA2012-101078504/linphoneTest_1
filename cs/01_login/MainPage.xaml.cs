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

using Linphone;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using Windows.Storage;
using Windows.System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Input;

namespace _01_login
{
	/// <summary>
	/// A really simple page for a first Login with LinphoneSDK x UWP
	/// </summary>
	public sealed partial class MainPage : Page
	{
		private Core StoredCore { get; set; }

		LoggingService LoggingService { get; set; }

		private Timer Timer;


		public MainPage()
		{
			this.InitializeComponent();

			// Core is the main object of the SDK. You can't do much without it
			// If you're not familiar with Linphone Core creation, see the 00_hello_world project.
			LoggingService = LoggingService.Instance;
			LoggingService.LogLevel = LogLevel.Debug;
			LoggingService.Listener.OnLogMessageWritten = OnLog;

			Factory factory = Factory.Instance;

			string assetsPath = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "Assets");
			factory.TopResourcesDir = assetsPath;
			factory.DataResourcesDir = assetsPath;
			factory.SoundResourcesDir = assetsPath;
			factory.RingResourcesDir = assetsPath;
			factory.ImageResourcesDir = assetsPath;
			factory.MspluginsDir = ".";

			Core core = factory.CreateCore("", "", IntPtr.Zero);

			StoredCore = core;
	
			// We need to indicate to the core where are stored the root ans user certificates, for future TLS exchange.
			StoredCore.RootCa = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "Assets", "rootca.pem");
			StoredCore.UserCertificatesPath = ApplicationData.Current.LocalFolder.Path;

			// In this tutorials we are going to log in and our registration state will change.
			// Here we show you how to register a delegate method called every time the 
			// on OnRegistrationStateChanged callback is triggered.
			StoredCore.Listener.OnRegistrationStateChanged += OnRegistrationStateChanged;

			// Start the core after setup, and before everything else.
			StoredCore.Start();

			// The method Iterate must be permanently called on our core.
			// The Iterate method runs all the waiting backgrounds tasks and poll networks notifications.
			// Here how to setup a function called every 50ms, 50ms after the Timer object instantiation.
			// See OnTimedEvent for more informations.
			Timer = new Timer(OnTimedEvent, null, 20, 20);

			// Setup GUI
			Identity.Text = "sip:anthony.gauchy@sip.linphone.org";
			Password.PlaceholderText = "myPasswd";
			LogoutGuiChanges();

			// Now use the GUI to log in, and see LogInClick to see how to handle login.
		}

		/// <summary>
		/// Here we scheduled a callback to the Iterate method on the UI thread. While the
		/// Linphone API calls are note thread safe, we ensure all our callbacks are done on the UI thread.
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

				// Here we are creating an AuthInfo object from the identity Address and password provided by the user.
				Address address = Factory.Instance.CreateAddress(Identity.Text);
				AuthInfo authInfo = Factory.Instance.CreateAuthInfo(address.Username, "", Password.Password, "", "", address.Domain);
				// And we add it to the Core
				StoredCore.AddAuthInfo(authInfo);

				// Then we create a ProxyConfig object.
				// It contains the connection information for the core
				ProxyConfig proxyConfig = StoredCore.CreateProxyConfig();
				proxyConfig.IdentityAddress = address;
				string serverAddr = "sip:" + address.Domain + ";transport=tls";
				proxyConfig.ServerAddr = serverAddr;
				// If RegisterEnabled is set to true, when this configuration will be added to the core it will
				// automatically try to connect.
				proxyConfig.RegisterEnabled = true;
				
				// And now we add it to the core, launching the connection process.
				StoredCore.AddProxyConfig(proxyConfig);
				StoredCore.DefaultProxyConfig = proxyConfig;
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
		/// Called when you click on the "Logout" button.
		/// </summary>
		private void LogOutClick(object sender, RoutedEventArgs e)
		{
			if (LogOut.IsEnabled)
			{
				LogOut.IsEnabled = false;

				// Setting RegisterEnabled to false on a connected ProxyConfig object will
				// launch the logout action.
				ProxyConfig proxyConfig = StoredCore.DefaultProxyConfig;
				if (proxyConfig != null)
				{
					// You should call Edit() on a ProxyConfig before editing it.
					proxyConfig.Edit();
					proxyConfig.RegisterEnabled = false;
					// And Done() after.
					proxyConfig.Done();
				}
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
				// If the ProxyConfig was logged out, we clear the Core.
				case RegistrationState.Cleared:
				case RegistrationState.None:
					StoredCore.ClearAllAuthInfo();
					StoredCore.ClearProxyConfig();
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

		/// <summary>
		/// Simple function to console log everything the Linphone SDK logs.
		/// You should modify this method to match your logging habits.
		/// </summary>
		private void OnLog(LoggingService logService, string domain, LogLevel lev, string message)
		{
			string now = DateTime.Now.ToString("hh:mm:ss");
			string log = now + " [";
			switch (lev)
			{
				case LogLevel.Debug:
					log += "DEBUG";
					break;
				case LogLevel.Error:
					log += "ERROR";
					break;
				case LogLevel.Message:
					log += "MESSAGE";
					break;
				case LogLevel.Warning:
					log += "WARNING";
					break;
				case LogLevel.Fatal:
					log += "FATAL";
					break;
				default:
					break;
			}
			log += "] (" + domain + ") " + message;
			Debug.WriteLine(log);
		}
	}
}
