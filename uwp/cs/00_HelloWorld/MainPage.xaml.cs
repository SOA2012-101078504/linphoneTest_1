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
using Windows.UI.Xaml.Controls;

namespace _00_HelloWorld
{
	/// <summary>
	/// A really simple page to do a "HelloWorld" with LinphoneSDK x UWP
	/// </summary>
	public sealed partial class MainPage : Page
	{
		private Core StoredCore { get; set; }

		private LoggingService LoggingService { get; set; }

		public string HelloText { get; set; } = "Hello world, Linphone core version is ";

		public MainPage()
		{
			this.InitializeComponent();

			// Core is the main object of the SDK. You can't do much without it

			// Some configuration can be done before the Core is created, for example enable debug logs.
			LoggingService = LoggingService.Instance;
			LoggingService.LogLevel = LogLevel.Debug;
			// And here you set the implementation of the delegate method called every time the Linphone SDK log something, see OnLog.
			LoggingService.Listener.OnLogMessageWritten = OnLog;

			// To create a Core, we need the instance of the Factory.
			Factory factory = Factory.Instance;

			// Some configuration can be done on the factory before the Core is created, for example enable setting resources Path. This
			// one is mandatory
			string assetsPath = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "share");
			factory.TopResourcesDir = assetsPath;
			factory.DataResourcesDir = assetsPath;
			factory.SoundResourcesDir = Path.Combine(assetsPath, "sounds", "linphone");
			factory.RingResourcesDir = Path.Combine(factory.SoundResourcesDir, "rings");
			factory.ImageResourcesDir = Path.Combine(assetsPath, "images");
			factory.MspluginsDir = ".";

			// Your Core can use up to 2 configuration files, but that isn't mandatory.
			// The third parameter is the application context, he isn't mandatory when working
			// with UWP, he is mandatory in an Android context for example.
			// You can now create your Core object :
			Core core = factory.CreateCore("", "", IntPtr.Zero);

			// Once you got your core you can start to do a lot of things.
			HelloText += Core.Version;

			// You should store the Core to keep a reference on it at all times while your app is alive.
			// A good solution for that is either subclass the Application object or create a Service.
			StoredCore = core;
		}

		/// <summary>
		/// Simple function to console log everything the Linphone SDK logs.
		/// You should modify this method to match your logging habits.
		/// </summary>
		private void OnLog(LoggingService logService, string domain, LogLevel lev, string message)
		{
			StringBuilder builder = new StringBuilder();
			_ = builder.Append("Linphone-[").Append(lev.ToString()).Append("](").Append(domain).Append(")").Append(message);
			Debug.WriteLine(builder.ToString());
		}
	}
}