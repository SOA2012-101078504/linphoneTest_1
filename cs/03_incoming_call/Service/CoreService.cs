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
using System.Threading;
using System.Threading.Tasks;
using Windows.Media.Audio;
using Windows.Media.Capture;
using Windows.Storage;
using Windows.UI.Core;
using static Linphone.CoreListener;

namespace _03_incoming_call.Service
{
	class CoreService
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

					string assetsPath = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "Assets");
					factory.TopResourcesDir = assetsPath;
					factory.DataResourcesDir = assetsPath;
					factory.SoundResourcesDir = assetsPath;
					factory.RingResourcesDir = assetsPath;
					factory.ImageResourcesDir = assetsPath;
					factory.MspluginsDir = ".";

					core = factory.CreateCore("", "", IntPtr.Zero);

					core.AudioPort = 7666;
					core.VideoPort = 9666;

					core.RootCa = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "Assets", "rootca.pem");
					core.UserCertificatesPath = ApplicationData.Current.LocalFolder.Path;

					VideoActivationPolicy videoActivationPolicy = factory.CreateVideoActivationPolicy();
					videoActivationPolicy.AutomaticallyAccept = true;
					videoActivationPolicy.AutomaticallyInitiate = false;
					core.VideoActivationPolicy = videoActivationPolicy;

					if (Core.VideoSupported())
					{
						Core.VideoDisplayFilter = "MSOGL";
						Core.VideoCaptureEnabled = true;
					}
					Core.UsePreviewWindow(true);
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

		public void AddOnRegistrationStateChangedDelegate(OnRegistrationStateChangedDelegate myDelegate)
		{
			Core.Listener.OnRegistrationStateChanged += myDelegate;
		}

		public void AddOnCallStateChangedDelegate(OnCallStateChangedDelegate myDelegate)
		{
			Core.Listener.OnCallStateChanged += myDelegate;
		}

		public void LogIn(string identity, string password)
		{
			Address address = Factory.Instance.CreateAddress(identity);
			AuthInfo authInfo = Factory.Instance.CreateAuthInfo(address.Username, "", password, "", "", address.Domain);
			Core.AddAuthInfo(authInfo);


			ProxyConfig proxyConfig = core.CreateProxyConfig();
			proxyConfig.IdentityAddress = address;
			string serverAddr = "sip:" + address.Domain + ";transport=tls";
			proxyConfig.ServerAddr = serverAddr;

			proxyConfig.RegisterEnabled = true;

			Core.AddProxyConfig(proxyConfig);
			Core.DefaultProxyConfig = proxyConfig;
		}

		public void LogOut()
		{

			ProxyConfig proxyConfig = Core.DefaultProxyConfig;
			if (proxyConfig != null)
			{
				proxyConfig.Edit();
				proxyConfig.RegisterEnabled = false;
				proxyConfig.Done();
			}
		}


		public void ClearCoreAfterLogOut()
		{
			Core.ClearAllAuthInfo();
			Core.ClearProxyConfig();
		}

		public async void Call(string uriToCall)
		{
			await OpenMicrophonePopup();

			Address address = Core.InterpretUrl(uriToCall);
			Core.InviteAddress(address);
		}
		public bool MicEnabledSwitch()
		{
			return Core.MicEnabled = !Core.MicEnabled;
		}

		public bool SpeakerMutedSwitch()
		{
			return Core.CurrentCall.SpeakerMuted = !Core.CurrentCall.SpeakerMuted;
		}

		public async Task<bool> CameraEnabledSwitchAsync()
		{
			await OpenCameraPopup();

			Call call = Core.CurrentCall;
			CallParams param = core.CreateCallParams(call);
			bool newValue = !param.VideoEnabled;
			param.VideoEnabled = newValue;
			call.Update(param);

			return newValue;
		}

		public void DeclineIncomingCall()
		{
			if (Core.CurrentCall != null && Core.CurrentCall.State == CallState.IncomingReceived)
			{
				Core.CurrentCall.Decline(Reason.Declined);
			}
		}

		public void AcceptIncomingCall()
		{
			if (Core.CurrentCall != null && Core.CurrentCall.State == CallState.IncomingReceived)
			{
				Core.CurrentCall.Accept();
			}
		}

		private async Task OpenMicrophonePopup()
		{
			AudioGraphSettings settings = new AudioGraphSettings(Windows.Media.Render.AudioRenderCategory.Media);
			CreateAudioGraphResult result = await AudioGraph.CreateAsync(settings);
			AudioGraph audioGraph = result.Graph;

			CreateAudioDeviceInputNodeResult resultNode = await audioGraph.CreateDeviceInputNodeAsync(Windows.Media.Capture.MediaCategory.Media);
			AudioDeviceInputNode deviceInputNode = resultNode.DeviceInputNode;

			deviceInputNode.Dispose();
			audioGraph.Dispose();
		}

		private async Task OpenCameraPopup()
		{
			MediaCapture mediaCapture = new Windows.Media.Capture.MediaCapture();
			await mediaCapture.InitializeAsync(new MediaCaptureInitializationSettings
			{
				StreamingCaptureMode = StreamingCaptureMode.Video
			});
			mediaCapture.Dispose();
		}
	}
}

