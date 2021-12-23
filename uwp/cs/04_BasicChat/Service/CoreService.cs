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
using Windows.Media.Capture;
using Windows.Storage;
using Windows.UI.Core;
using static Linphone.CoreListener;

namespace _04_BasicChat.Service
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
					core.VideoPort = 9666;

					core.RootCa = Path.Combine(Windows.ApplicationModel.Package.Current.InstalledLocation.Path, "share", "Linphone", "rootca.pem");
					core.UserCertificatesPath = ApplicationData.Current.LocalFolder.Path;

					VideoActivationPolicy videoActivationPolicy = factory.CreateVideoActivationPolicy();
					videoActivationPolicy.AutomaticallyAccept = true;
					videoActivationPolicy.AutomaticallyInitiate = false;
					core.VideoActivationPolicy = videoActivationPolicy;


					core.VideoCaptureEnabled = core.VideoSupported();
					core.UsePreviewWindow(true);
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

		public void AddOnCallStateChangedDelegate(OnCallStateChangedDelegate myDelegate)
		{
			Core.Listener.OnCallStateChanged += myDelegate;
		}

		public void RemoveOnCallStateChangedDelegate(OnCallStateChangedDelegate myDelegate)
		{
			Core.Listener.OnCallStateChanged -= myDelegate;
		}

		/// <summary>
		/// Used to add a delegate for the OnMessageReceived callback this callback is triggered every time
		/// a message is received in ANY ChatRoom.
		/// </summary>
		public void AddOnOnMessageReceivedDelegate(OnMessageReceivedDelegate myDelegate)
		{
			Core.Listener.OnMessageReceived += myDelegate;
		}

		public void RemoveOnOnMessageReceivedDelegate(OnMessageReceivedDelegate myDelegate)
		{
			Core.Listener.OnMessageReceived -= myDelegate;
		}

		/// <summary>
		/// Used to add a delegate for the OnMessageReceived callback this callback is triggered every time
		/// a message is sent in ANY ChatRoom.
		/// </summary>
		public void AddOnMessageSentDelegate(OnMessageSentDelegate myDelegate)
		{
			Core.Listener.OnMessageSent += myDelegate;
		}

		public void RemoveOnMessageSentDelegate(OnMessageSentDelegate myDelegate)
		{
			Core.Listener.OnMessageSent -= myDelegate;
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

		public async void Call(string uriToCall)
		{
			await OpenMicrophonePopup();

			Address address = Core.InterpretUrl(uriToCall);
			Core.InviteAddress(address);
		}

		public bool ToggleMic()
		{
			return Core.MicEnabled = !Core.MicEnabled;
		}

		public bool ToggleSpeaker()
		{
			return Core.CurrentCall.SpeakerMuted = !Core.CurrentCall.SpeakerMuted;
		}

		public async Task<bool> ToggleCameraAsync()
		{
			await OpenCameraPopup();

			Call call = Core.CurrentCall;
			CallParams param = core.CreateCallParams(call);
			bool newValue = !param.VideoEnabled;
			param.VideoEnabled = newValue;
			call.Update(param);

			return newValue;
		}

		/// <summary>
		/// Method to create a one to one basic ChatRoom from a string sip address.
		/// </summary>
		public ChatRoom CreateOrGetChatRoom(string sipAddress)
		{
			// Construct an Address object from the string parameter if possible.
			Address remoteAddress = Core.InterpretUrl(sipAddress);

			// We get our current local Address.
			Address localAdress = Core.DefaultProxyConfig.IdentityAddress;

			// You need to create a ChatRoomParams object to configure
			// your future ChatRoom, always use Core.CreateDefaultChatRoomParams().
			// By default the default parameters are the ones we set just after, but we
			// set them anyway to explain them.
			ChatRoomParams chatRoomParams = Core.CreateDefaultChatRoomParams();

			// Set the type of SIP server you want to use, if you are
			// using a basic SIP backend you can't enable encryption or
			// group chat.
			chatRoomParams.Backend = ChatRoomBackend.Basic;
			// Choose if you want to enable real time text.
			chatRoomParams.RttEnabled = false;

			// You can choose to enable encryption and choose the type of encryption
			// want. We explain in a further step how to use LIME (Linphone
			// Instant Message Encryption) with FlexisipChat backend.
			chatRoomParams.EncryptionEnabled = false;
			chatRoomParams.EncryptionBackend = ChatRoomEncryptionBackend.None;

			// Enable this if you want to create a group ChatRoom. We explain in
			// a further step how to handle group chat with FlexisipChat backend.
			chatRoomParams.GroupEnabled = false;

			// To create a ChatRoom always use  :
			// Core.CreateChatRoom(ChatRoomParams parameters, Address localAddr, IEnumerable<Address> participants);
			// If all the parameters match an existing ChatRoom of yours,
			// it is returned instead of creating a new one.
			return Core.CreateChatRoom(chatRoomParams, localAdress, new[] { remoteAddress });
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

		private async Task OpenCameraPopup()
		{
			MediaCapture mediaCapture = new MediaCapture();
			try
			{
				await mediaCapture.InitializeAsync(new MediaCaptureInitializationSettings
				{
					StreamingCaptureMode = StreamingCaptureMode.Video
				});
			}
			catch (Exception e) when (e.Message.StartsWith("No capture devices are available."))
			{
				// Ignored.
			}
			mediaCapture.Dispose();
		}
	}
}