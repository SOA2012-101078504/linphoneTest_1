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

namespace _05_FileTransfer.Service
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

					if (core.VideoSupported())
					{
						core.VideoCaptureEnabled = true;
					}
					core.UsePreviewWindow(true);

					// You must set up your file transfer server if you want to transfer files.
					core.FileTransferServer = "https://www.linphone.org:444/lft.php";
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

		public void AddOnOnMessageReceivedDelegate(OnMessageReceivedDelegate myDelegate)
		{
			Core.Listener.OnMessageReceived += myDelegate;
		}

		public void RemoveOnOnMessageReceivedDelegate(OnMessageReceivedDelegate myDelegate)
		{
			Core.Listener.OnMessageReceived -= myDelegate;
		}

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

		public ChatRoom CreateOrGetChatRoom(string sipAddress)
		{
			Address remoteAddress = Core.InterpretUrl(sipAddress);
			Address localAdress = Core.DefaultProxyConfig.IdentityAddress;

			ChatRoomParams chatRoomParams = Core.CreateDefaultChatRoomParams();
			chatRoomParams.Backend = ChatRoomBackend.Basic;
			chatRoomParams.EncryptionBackend = ChatRoomEncryptionBackend.None;
			chatRoomParams.EncryptionEnabled = false;
			chatRoomParams.GroupEnabled = false;
			chatRoomParams.RttEnabled = false;

			return Core.CreateChatRoom(chatRoomParams, localAdress, new[] { remoteAddress });
		}

		public async Task<Content> CreateContentFromFile(StorageFile file)
		{
			// Copy the file where the LinphoneSDK has read access.
			StorageFile fileCopy = await file.CopyAsync(ApplicationData.Current.LocalFolder, file.Name, NameCollisionOption.ReplaceExisting);

			// Always use Linphone's method and not new() to create Linphone objects.
			Content content = Core.CreateContent();

			// File Path is the only mandatory field to set.
			content.FilePath = fileCopy.Path;

			// You can set the type and subtype of your file, it help
			// the server and receiver identifying the file (images can
			// be directly displayed for example).
			string[] splittedMimeType = fileCopy.ContentType.Split("/");
			content.Type = splittedMimeType[0];
			content.Subtype = splittedMimeType[1];

			// Set the file name for the receiver, by default the same name is taken.
			// This line is useful only for the explanation.
			content.Name = fileCopy.Name;

			return content;
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