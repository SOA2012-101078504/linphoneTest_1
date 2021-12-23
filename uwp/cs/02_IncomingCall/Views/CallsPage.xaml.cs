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

using _02_IncomingCall.Service;
using Linphone;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _02_IncomingCall.Views
{
	public sealed partial class CallsPage : Page
	{
		private CoreService CoreService { get; } = CoreService.Instance;

		private Call IncomingCall;

		public CallsPage()
		{
			this.InitializeComponent();
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			CoreService.RemoveOnCallStateChangedDelegate(OnCallStateChanged);
			base.OnNavigatedFrom(e);
		}

		protected override void OnNavigatedTo(NavigationEventArgs e)
		{
			base.OnNavigatedTo(e);

			// We can find current AuthInfo in the DefaultProxyConfig, we use this to say "Hello".
			HelloText.Text += CoreService.Core.DefaultProxyConfig.FindAuthInfo().Username;

			// On each stage of a call we want to update our GUI.
			// The same way we did for OnAccountRegistrationStateChanged we can register
			// a delegate called every time the state of a call changed.
			// See this.OnCallStateChanged for more details
			CoreService.AddOnCallStateChangedDelegate(OnCallStateChanged);

			if (CoreService.Core.CurrentCall != null)
			{
				OnCallStateChanged(CoreService.Core, CoreService.Core.CurrentCall, CoreService.Core.CurrentCall.State, null);
			}
		}

		/// <summary>
		/// Method called when the "Hang out" button is clicked.
		/// </summary>
		private void OnHangUpClicked(object sender, RoutedEventArgs e)
		{
			// Simply call TerminateAllCalls to hang out.
			// You could also do something like CoreService.Core.CurrentCall?.Terminate();
			CoreService.Core.TerminateAllCalls();
		}

		/// <summary>
		/// Method called when the "Switch on/off" button is clicked.
		/// See CoreService.ToggleSpeaker for more info.
		/// </summary>
		private void SoundClick(object sender, RoutedEventArgs e)
		{
			if (CoreService.ToggleSpeaker())
			{
				Sound.Content = "Switch on Sound";
			}
			else
			{
				Sound.Content = "Switch off Sound";
			}
		}

		/// <summary>
		/// Method to mute/unmute your microphone.
		/// See CoreService.ToggleMic for more info.
		/// </summary>
		private void MicClick(object sender, RoutedEventArgs e)
		{
			if (CoreService.ToggleMic())
			{
				Mic.Content = "Mute";
			}
			else
			{
				Mic.Content = "Unmute";
			}
		}

		/// <summary>
		/// We registered this method to be called every time the call state is updated.
		/// You can find all the different call states in the CallState class.
		/// Every time this method is called we update a TextBlock so you can follow the call state visually.
		/// </summary>
		private void OnCallStateChanged(Core core, Call call, CallState state, string message)
		{
			CallText.Text = "Your call state is : " + state.ToString();
			switch (state)
			{
				case CallState.IncomingReceived:
					// When you receive a call the CallState is incoming receive. By default you can only have one current call,
					// so if a call is a progress or one is already ringing the second remote call will be decline with the reason
					// "Busy". If you want to implement a multi call app you can increase Core.MaxCalls.
					// Here we store the incoming call reference so we can accept or decline the call on user input, see AnswerClick
					// and DeclineClick.
					IncomingCall = call;
					// And we update the GUI to notify the user of the incoming call.
					IncomingCallStackPanel.Visibility = Visibility.Visible;
					IncomingCallText.Text = " " + IncomingCall.RemoteAddress.AsString();

					break;

				case CallState.StreamsRunning:
					// The StreamsRunning state is the default one during a call.
					CallInProgressGuiUpdates();
					break;

				case CallState.Error:
				case CallState.End:
				case CallState.Released:
					// By default after 30 seconds of ringing without accept or decline a call is
					// automatically ended.
					IncomingCall = null;
					EndingCallGuiUpdates();

					break;
			}
		}

		/// <summary>
		/// Method called when the "Answer" button is clicked
		/// </summary>
		private async void AnswerClick(object sender, RoutedEventArgs e)
		{
			if (IncomingCall != null)
			{
				// We call this method to pop the microphone permission window.
				// If the permission was already granted for this app, no pop up
				// appears.
				await CoreService.OpenMicrophonePopup();

				// To accept a call only use the Accept() method on the call object.
				// If we wanted, we could create a CallParams object and answer using this object to make changes to the call configuration.
				IncomingCall.Accept();
				IncomingCall = null;
			}
		}

		/// <summary>
		/// Method called when the "Decline" button is clicked.
		/// </summary>
		private void DeclineClick(object sender, RoutedEventArgs e)
		{
			if (IncomingCall != null)
			{
				// You have to give a Reason to decline a call. This info is sent to the remote.
				// See Linphone.Reason to see the full list.
				IncomingCall.Decline(Reason.Declined);
				IncomingCall = null;
			}
		}

		/// <summary>
		/// Update GUI when there is no more current call
		/// </summary>
		private void EndingCallGuiUpdates()
		{
			IncomingCallStackPanel.Visibility = Visibility.Collapsed;
			HangUp.IsEnabled = false;
			Sound.IsEnabled = false;
			Mic.IsEnabled = false;
			Mic.Content = "Mute";
			Sound.Content = "Switch off Sound";
		}

		/// <summary>
		/// Update GUI when a call is running
		/// </summary>
		private void CallInProgressGuiUpdates()
		{
			IncomingCallStackPanel.Visibility = Visibility.Collapsed;
			HangUp.IsEnabled = true;
			Sound.IsEnabled = true;
			Mic.IsEnabled = true;
		}
	}
}