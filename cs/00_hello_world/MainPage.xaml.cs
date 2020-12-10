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
using System.IO;
using Windows.UI.Xaml.Controls;


namespace _00_hello_world
{
	/// <summary>
	/// A really simple page to do a "HelloWorld" with LinphoneSDK x UWP
	/// </summary>
	public sealed partial class MainPage : Page
	{

		private Core storedCore;

		public string HelloText { get; set; } = "Hello world, Linphone core version is ";

		public MainPage()
		{
			this.InitializeComponent();

			// Core is the main object of the SDK. You can't do much without it
			// Some configuration can be done before the Core is created, for example enable debug logs.
			Linphone.LoggingService.Instance.LogLevel = Linphone.LogLevel.Debug;

			// To create a Core, we need the instance of the Factory.
			Factory factory = Factory.Instance;

			// Some configuration can be done on the factory before the Core is created, for example enable setting resources Path. This
			// one can be mandatory
			factory.TopResourcesDir = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "Assets");

			// Your Core can use up to 2 configuration files, but that isn't mandatory.
			// The third parameter is the application context, he isn't madatory when working
			// with UWP, he is mandatory in an Android context for example.
			// You can now create your Core object :
			Core core = factory.CreateCore("", "", IntPtr.Zero);

			// Once you got your core you can start to do a lot of things.
			HelloText += Core.Version;

			// You should store the Core to keep a reference on it at all times while your app is alive.
			// A good solution for that is either subclass the Application object or create a Service.
			storedCore = core;
		}
	}
}
