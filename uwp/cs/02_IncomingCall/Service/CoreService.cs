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
using System.Threading;
using System.Threading.Tasks;
using Windows.Media.Audio;
using Windows.Storage;
using Windows.UI.Core;
using static Linphone.CoreListener;

namespace _02_IncomingCall.Service
{
	internal class CoreService
	{
		private Timer Timer;

		private static readonly CoreService instance = new CoreService();

		public static CoreService Instance
		{
			get
			{
				return instance;
			}
		}

		private Core core;

		public Core Core
		{
			get
			{
				if (core == null)
				{
					Factory factory = Factory.Instance;

					string assetsPath = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "share");
					factory.TopResourcesDir = assetsPath;
					factory.DataResourcesDir = assetsPath;
					factory.SoundResourcesDir = Path.Combine(assetsPath, "sounds", "linphone");
					factory.RingResourcesDir = Path.Combine(factory.SoundResourcesDir, "rings");
					factory.ImageResourcesDir = Path.Combine(assetsPath, "images");
					factory.MspluginsDir = ".";

					core = factory.CreateCore("", "", IntPtr.Zero);

					core.AudioPort = 7666;

					core.RootCa = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "share", "Linphone", "rootca.pem");
					core.UserCertificatesPath = ApplicationData.Current.LocalFolder.Path;
				}
				return core;
			}
		}

		public void CoreStart(CoreDispatcher dispatcher)
		{
			Core.Start();

			Timer = new Timer(OnTimedEvent, dispatcher, 20, 20);
		}

		private async void OnTimedEvent(object state)
		{
			await ((CoreDispatcher)state).RunIdleAsync((args) =>
			{
				Core.Iterate();
			});
		}

		public void AddOnAccountRegistrationStateChangedDelegate(OnAccountRegistrationStateChangedDelegate myDelegate)
		{
			Core.Listener.OnAccountRegistrationStateChanged += myDelegate;
		}

		public void RemoveOnAccountRegistrationStateChangedDelegate(OnAccountRegistrationStateChangedDelegate myDelegate)
		{
			Core.Listener.OnAccountRegistrationStateChanged -= myDelegate;
		}

		/// <summary>
		/// Used to add a delegate for the OnCallStateChanged callback, using += allow you to register
		/// multiples delegates.
		/// </summary>
		public void AddOnCallStateChangedDelegate(OnCallStateChangedDelegate myDelegate)
		{
			Core.Listener.OnCallStateChanged += myDelegate;
		}

		public void RemoveOnCallStateChangedDelegate(OnCallStateChangedDelegate myDelegate)
		{
			Core.Listener.OnCallStateChanged -= myDelegate;
		}

		public void LogIn(string identity, string password)
		{
			Address address = Factory.Instance.CreateAddress(identity);
			AuthInfo authInfo = Factory.Instance.CreateAuthInfo(address.Username, "", password, "", "", address.Domain);
			Core.AddAuthInfo(authInfo);

			AccountParams accountParams = Core.CreateAccountParams();
			accountParams.IdentityAddress = address;
			string serverAddr = "sip:" + address.Domain + ";transport=tls";
			accountParams.ServerAddr = serverAddr;

			accountParams.RegisterEnabled = true;

			Account account = Core.CreateAccount(accountParams);
			Core.AddAccount(account);
			Core.DefaultAccount = account;
		}

		public void LogOut()
		{
			Account account = Core.DefaultAccount;
			if (account != null)
			{
				AccountParams accountParams = account.Params.Clone();
				accountParams.RegisterEnabled = false;
				account.Params = accountParams;
			}
		}

		public void ClearCoreAfterLogOut()
		{
			Core.ClearAllAuthInfo();
			Core.ClearAccounts();
		}

		/// <summary>
		/// Mute/Unmute your microphone.
		/// Setting MicEnabled=false on the Core mutes your microphone globally.
		/// </summary>
		public bool ToggleMic()
		{
			// The following toggles the microphone, disabling completely / enabling the sound capture from the device microphone
			return Core.MicEnabled = !Core.MicEnabled;
		}

		/// <summary>
		/// Enable/Disable the speaker sound.
		/// Setting SpeakerMuted=true on a Call object disables the sound output of this call.
		/// </summary>
		public bool ToggleSpeaker()
		{
			return Core.CurrentCall.SpeakerMuted = !Core.CurrentCall.SpeakerMuted;
		}

		public async Task OpenMicrophonePopup()
		{
			AudioGraphSettings settings = new AudioGraphSettings(Windows.Media.Render.AudioRenderCategory.Media);
			CreateAudioGraphResult result = await AudioGraph.CreateAsync(settings);
			AudioGraph audioGraph = result.Graph;

			CreateAudioDeviceInputNodeResult resultNode = await audioGraph.CreateDeviceInputNodeAsync(Windows.Media.Capture.MediaCategory.Media);
			AudioDeviceInputNode deviceInputNode = resultNode.DeviceInputNode;

			deviceInputNode.Dispose();
			audioGraph.Dispose();
		}
	}
}