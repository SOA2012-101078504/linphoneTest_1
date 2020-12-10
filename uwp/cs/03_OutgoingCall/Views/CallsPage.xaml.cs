﻿/*
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

using _03_OutgoingCall.Service;
using Linphone;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _03_OutgoingCall.Views
{
	public sealed partial class CallsPage : Page
	{
		private CoreService CoreService { get; } = CoreService.Instance;

		private VideoService VideoService { get; } = VideoService.Instance;

		private Call IncommingCall;

		public CallsPage()
		{
			this.InitializeComponent();
		}

		/// <summary>
		/// We just stop the video rendering when we leave the page.
		/// Details about the video rendering implementation are in Service/VideoService.cs
		/// </summary>
		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			VideoService.StopVideoStream();
			CoreService.RemoveOnCallStateChangedDelegate(OnCallStateChanged);
			base.OnNavigatedFrom(e);
		}

		protected override void OnNavigatedTo(NavigationEventArgs e)
		{
			base.OnNavigatedTo(e);

			HelloText.Text += CoreService.Core.DefaultProxyConfig.FindAuthInfo().Username;
			CoreService.AddOnCallStateChangedDelegate(OnCallStateChanged);

			if (CoreService.Core.CurrentCall != null)
			{
				OnCallStateChanged(CoreService.Core, CoreService.Core.CurrentCall, CoreService.Core.CurrentCall.State, null);
			}
		}

		/// <summary>
		/// Method called when the "Call" button is clicked, see CoreService.Call
		/// to learn how to make a call.
		/// </summary>
		private void CallClick(object sender, RoutedEventArgs e)
		{
			CoreService.Call(UriToCall.Text);
		}

		private void HangOutClick(object sender, RoutedEventArgs e)
		{
			CoreService.Core.TerminateAllCalls();
		}

		private void SoundClick(object sender, RoutedEventArgs e)
		{
			if (CoreService.SpeakerMutedSwitch())
			{
				Sound.Content = "Switch on Sound";
			}
			else
			{
				Sound.Content = "Switch off Sound";
			}
		}

		/// <summary>
		/// Method to turn on/off the video call.
		/// Watch CoreService.CameraEnabledSwitchAsync for more info.
		/// </summary>
		private async void CameraClick(object sender, RoutedEventArgs e)
		{
			await CoreService.CameraEnabledSwitchAsync();

			// After CoreService.CameraEnabledSwitchAsync the Call state is "Updating".
			// We wait for the return of the "StreamsRunning" state to update the GUI
			// according to the final consensus between callers.
			Camera.Content = "Waiting for accept ...";
			Camera.IsEnabled = false;
		}

		private void MicClick(object sender, RoutedEventArgs e)
		{
			if (CoreService.MicEnabledSwitch())
			{
				Mic.Content = "Mute";
			}
			else
			{
				Mic.Content = "Unmute";
			}
		}

		private void OnCallStateChanged(Core core, Call call, CallState state, string message)
		{
			CallText.Text = "Your call state is : " + state.ToString();
			switch (state)
			{
				case CallState.IncomingReceived:
					IncommingCall = call;
					IncomingCallStackPanel.Visibility = Visibility.Visible;
					IncommingCallText.Text = " " + IncommingCall.RemoteAddress.AsString();

					break;

				case CallState.OutgoingInit:
				case CallState.OutgoingProgress:
				case CallState.OutgoingRinging:
					// Different states you go through when you start a call and before your peer answer.
					HangOut.IsEnabled = true;
					break;

				case CallState.StreamsRunning:
				case CallState.UpdatedByRemote:
					// The StreamsRunning state is the default one during a call.
					// The UpdatedByRemote is triggered when the call's parameters are updated
					// for example when video is asked/removed by remote.

					CallInProgressGuiUpdates();
					if (call.CurrentParams.VideoEnabled)
					{
						StartVideoAndUpdateGui();
					}
					else
					{
						StopVideoAndUpdateGui();
					}
					break;

				case CallState.Error:
				case CallState.End:
				case CallState.Released:
					IncommingCall = null;
					EndingCallGuiUpdates();
					VideoService.StopVideoStream();

					break;
			}
		}

		private void AnswerClick(object sender, RoutedEventArgs e)
		{
			if (IncommingCall != null)
			{
				IncommingCall.Accept();
				IncommingCall = null;
			}
		}

		private void DeclineClick(object sender, RoutedEventArgs e)
		{
			if (IncommingCall != null)
			{
				IncommingCall.Decline(Reason.Declined);
				IncommingCall = null;
			}
		}

		/// <summary>
		/// Method to hide the webcam grid and stop the of the rendering remote and preview webcam.
		/// Watch VideoService and more specifically VideoService.StopVideoStream.
		/// </summary>
		private void StopVideoAndUpdateGui()
		{
			Camera.Content = "Switch on Camera";
			Camera.IsEnabled = true;
			VideoGrid.Visibility = Visibility.Collapsed;
			VideoService.StopVideoStream();
		}

		/// <summary>
		/// Method to show the webcam grid and start rendering remote and preview webcam.
		/// Watch VideoService and more specifically VideoService.StartVideoStream to
		/// understand how to start the rendering on a SwapChainPanel.
		/// </summary>
		private void StartVideoAndUpdateGui()
		{
			VideoGrid.Visibility = Visibility.Visible;
			Camera.Content = "Switch off Camera";
			VideoService.StartVideoStream(VideoSwapChainPanel, PreviewSwapChainPanel);
			Camera.IsEnabled = true;
		}

		private void EndingCallGuiUpdates()
		{
			IncomingCallStackPanel.Visibility = Visibility.Collapsed;
			CallButton.IsEnabled = true;
			HangOut.IsEnabled = false;
			Sound.IsEnabled = false;
			Camera.IsEnabled = false;
			Mic.IsEnabled = false;
			VideoGrid.Visibility = Visibility.Collapsed;
			Camera.Content = "Switch on Camera";
			Mic.Content = "Mute";
			Sound.Content = "Switch off Sound";
		}

		private void CallInProgressGuiUpdates()
		{
			IncomingCallStackPanel.Visibility = Visibility.Collapsed;
			CallButton.IsEnabled = false;
			HangOut.IsEnabled = true;
			Sound.IsEnabled = true;
			Camera.IsEnabled = true;
			Mic.IsEnabled = true;
		}
	}
}