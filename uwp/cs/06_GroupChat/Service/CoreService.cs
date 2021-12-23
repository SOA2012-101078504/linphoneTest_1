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
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Windows.Media.Audio;
using Windows.Media.Capture;
using Windows.Storage;
using Windows.UI.Core;
using static Linphone.CoreListener;

namespace _06_GroupChat.Service
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

					// In a Flexisip ChatRoom you are identified by your authentication info and your device (you can have multiple devices
					// connected to your account, some may accept group chat and others not). To identify your different devices, Linphone
					// uses a UUID generated when you start your app for the first time on the device. This UUID is stored in a configuration
					// file, this is why we specify a path for this configuration file now. If you don't, every time you start your app
					// it will be identified as a new device.
					// A side-effect to this you will soon notice is that your authentication information is also stored in this file
					// and is loaded at core startup. So if you don't use the sign out button and simply close the app, it will log you
					// back in the next time it starts.
					core = factory.CreateCore(Path.Combine(ApplicationData.Current.LocalFolder.Path, "configuration"), "", IntPtr.Zero);

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

		public void AddOnChatRoomSubjectChangedDelegate(OnChatRoomSubjectChangedDelegate myDelegate)
		{
			Core.Listener.OnChatRoomSubjectChanged += myDelegate;
		}

		public void RemoveOnChatRoomSubjectChangedDelegate(OnChatRoomSubjectChangedDelegate myDelegate)
		{
			Core.Listener.OnChatRoomSubjectChanged -= myDelegate;
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

			// If you want to create some group chats (conferences) you need to
			// specify a conference factory URI. Here is the Linphone.org conference
			// factory URI.
			accountParams.ConferenceFactoryUri = "sip:conference-factory@sip.linphone.org";

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

		public ChatRoom CreateGroupChatRoom(IEnumerable<Address> participants, string subject)
		{
			Address localAdress = Core.DefaultProxyConfig.IdentityAddress;

			ChatRoomParams chatRoomParams = Core.CreateDefaultChatRoomParams();

			// In comparison to basic chat rooms (see CreateOrGetChatRoom) you have two parameters
			// to change. You must use a Flexisip backend and enable group.
			chatRoomParams.Backend = ChatRoomBackend.FlexisipChat;
			chatRoomParams.GroupEnabled = true;

			// Set the subject of your chat room with what the user entered.
			chatRoomParams.Subject = subject;

			chatRoomParams.EncryptionBackend = ChatRoomEncryptionBackend.None;
			chatRoomParams.EncryptionEnabled = false;
			chatRoomParams.RttEnabled = false;

			// Now you can create your group chat room. the participants list must be not empty.
			// The conference factory will attempt to create a ChatRoom from the configuration you pass it.
			// See ChatPage.OnNavigatedTo to see how to know when your ChatRoom is ready.
			return Core.CreateChatRoom(chatRoomParams, localAdress, participants);
		}

		public async Task<Content> CreateContentFromFile(StorageFile file)
		{
			StorageFile fileCopy = await file.CopyAsync(ApplicationData.Current.LocalFolder, file.Name, NameCollisionOption.ReplaceExisting);

			Content content = Core.CreateContent();
			content.FilePath = fileCopy.Path;

			string[] splitMimeType = fileCopy.ContentType.Split("/");
			content.Type = splitMimeType[0];
			content.Subtype = splitMimeType[1];

			return content;
		}

		public async Task OpenMicrophonePopup()
		{
			AudioGraphSettings settings = new AudioGraphSettings(Windows.Media.Render.AudioRenderCategory.Media);
			CreateAudioGraphResult result = await AudioGraph.CreateAsync(settings);
			AudioGraph audioGraph = result.Graph;

			CreateAudioDeviceInputNodeResult resultNode = await audioGraph.CreateDeviceInputNodeAsync(MediaCategory.Media);
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