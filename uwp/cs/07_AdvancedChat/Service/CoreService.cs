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

namespace _07_AdvancedChat.Service
{
	internal class CoreService
	{
		private Timer Timer;

		public static CoreService Instance { get; } = new CoreService();

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

					core = factory.CreateCore(Path.Combine(ApplicationData.Current.LocalFolder.Path, "configuration"), "", IntPtr.Zero);

					core.AudioPort = 7666;
					core.VideoPort = 9666;

					// You only need to give your LIME server URL
					core.LimeX3DhServerUrl = "https://lime.linphone.org/lime-server/lime-server.php";
					// and enable LIME on your core to use encryption.
					core.LimeX3DhEnabled = true;
					// Now see the CoreService.CreateGroupChatRoom to see how to create a secure chat room

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

		public ChatRoom CreateOrGetChatRoom(string sipAddress, bool isSecure)
		{
			Address remoteAddress = Core.InterpretUrl(sipAddress);
			Address localAdress = Core.DefaultProxyConfig.IdentityAddress;

			ChatRoomParams chatRoomParams = Core.CreateDefaultChatRoomParams();
			// To create a one-to-one encrypted chat room we still set GroupEnabled to false...
			chatRoomParams.GroupEnabled = false;
			chatRoomParams.RttEnabled = false;

			if (isSecure)
			{
				// ...But here are the things that differ from a basic chat room.
				// You must use a Flexisip backend,
				chatRoomParams.Backend = ChatRoomBackend.FlexisipChat;

				// enable encryption and choose your type of encryption backend,
				chatRoomParams.EncryptionBackend = ChatRoomEncryptionBackend.Lime;
				chatRoomParams.EncryptionEnabled = true;

				// and you must set a subject. But often for one-to-one chat rooms the client
				// doesn't display the subject (see ChatRoomToStringConverter), so you can
				// put a hard coded subject.
				chatRoomParams.Subject = "Dummy Subject";
			}
			else
			{
				chatRoomParams.Backend = ChatRoomBackend.Basic;
				chatRoomParams.EncryptionBackend = ChatRoomEncryptionBackend.None;
				chatRoomParams.EncryptionEnabled = false;
			}

			return Core.CreateChatRoom(chatRoomParams, localAdress, new[] { remoteAddress });
		}

		public ChatRoom CreateGroupChatRoom(IEnumerable<Address> participants, string subject, bool isSecure)
		{
			Address localAdress = Core.DefaultProxyConfig.IdentityAddress;

			ChatRoomParams chatRoomParams = Core.CreateDefaultChatRoomParams();
			chatRoomParams.Backend = ChatRoomBackend.FlexisipChat;
			chatRoomParams.GroupEnabled = true;
			chatRoomParams.RttEnabled = false;
			chatRoomParams.Subject = subject;

			if (isSecure)
			{
				// If you want to use encryption you should be in a chat room with a Flexisip
				// backend, this is why we offer the option only on the group chat room for now.
				// Then simply choose your encryption backend (only LIME is available by default)
				chatRoomParams.EncryptionBackend = ChatRoomEncryptionBackend.Lime;
				// and put EncryptionEnabled to true.
				chatRoomParams.EncryptionEnabled = true;

				// And just like that, you now have a group chat room with end-to-end encryption.
			}
			else
			{
				chatRoomParams.EncryptionBackend = ChatRoomEncryptionBackend.None;
				chatRoomParams.EncryptionEnabled = false;
			}

			return Core.CreateChatRoom(chatRoomParams, localAdress, participants);
		}

		public async Task<Content> CreateContentFromFile(StorageFile file)
		{
			StorageFile fileCopy = await file.CopyAsync(ApplicationData.Current.LocalFolder, file.Name, NameCollisionOption.ReplaceExisting);

			Content content = Core.CreateContent();
			content.FilePath = fileCopy.Path;

			string[] splittedMimeType = fileCopy.ContentType.Split("/");
			content.Type = splittedMimeType[0];
			content.Subtype = splittedMimeType[1];

			return content;
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