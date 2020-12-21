using _03_incoming_call.Service;
using Linphone;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;

namespace _03_incoming_call.Views
{
	public sealed partial class CallsPage : Page
	{
		private CoreService CoreService { get; } = CoreService.Instance;

		private VideoService VideoService { get; } = VideoService.Instance;

		public CallsPage()
		{
			this.InitializeComponent();

			HelloText.Text += CoreService.Core.DefaultProxyConfig.FindAuthInfo().Username;

			CoreService.AddOnCallStateChangedDelegate(OnCallStateChanged);
		}

		protected override void OnNavigatedFrom(NavigationEventArgs e)
		{
			VideoService.StopVideoStream();
		}

		private void CallClick(object sender, RoutedEventArgs e)
		{
			CoreService.Call(UriToCall.Text);
		}

		private void LogOutClick(object sender, RoutedEventArgs e)
		{
			if (LogOut.IsEnabled)
			{
				IsEnabled = false;
				CoreService.Core.TerminateAllCalls();
				CoreService.LogOut();

				this.Frame.Navigate(typeof(LoginPage));
			}
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

		private async void CameraClick(object sender, RoutedEventArgs e)
		{
			await CoreService.CameraEnabledSwitchAsync();
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

		private void AnswerClick(object sender, RoutedEventArgs e)
		{
			CoreService.AcceptIncomingCall();
		}

		private void DeclineClick(object sender, RoutedEventArgs e)
		{
			CoreService.DeclineIncomingCall();
		}

		private void OnCallStateChanged(Core core, Call call, CallState state, string message)
		{
			CallText.Text = "You're call state is : " + state.ToString();
			switch (state)
			{
				case CallState.IncomingReceived:
					IncomingCallStackPanel.Visibility = Visibility.Visible;
					IncommingCallText.Text = " " + call.RemoteAddress.AsString();
					break;
				case CallState.OutgoingInit:
				case CallState.OutgoingProgress:
				case CallState.OutgoingRinging:

					HangOut.IsEnabled = true;
					break;

				case CallState.StreamsRunning:
				case CallState.UpdatedByRemote:

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

					EndingCallGuiUpdates();
					VideoService.StopVideoStream();
					break;
			}
		}

		private void StopVideoAndUpdateGui()
		{
			Camera.Content = "Switch on Camera";
			Camera.IsEnabled = true;
			WebcamsStackPanel.Visibility = Visibility.Collapsed;
			VideoService.StopVideoStream();
		}

		private void StartVideoAndUpdateGui()
		{
			VideoService.StartVideoStream(VideoSwapChainPanel, PreviewSwapChainPanel, Dispatcher);
			WebcamsStackPanel.Visibility = Visibility.Visible;
			Camera.Content = "Switch off Camera";
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
			WebcamsStackPanel.Visibility = Visibility.Collapsed;
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