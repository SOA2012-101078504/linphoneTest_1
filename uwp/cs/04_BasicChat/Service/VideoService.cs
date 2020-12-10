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

using Windows.UI.Xaml.Controls;

namespace _04_BasicChat.Service
{
	internal class VideoService
	{
		private static readonly VideoService instance = new VideoService();

		public static VideoService Instance
		{
			get
			{
				return instance;
			}
		}

		private CoreService CoreService { get; } = CoreService.Instance;

		public void StartVideoStream(SwapChainPanel main, SwapChainPanel preview)
		{
			CoreService.Core.NativePreviewWindowId = preview;
			CoreService.Core.NativeVideoWindowId = main;
		}

		public void StopVideoStream()
		{
			CoreService.Core.NativePreviewWindowId = null;
			CoreService.Core.NativeVideoWindowId = null;
		}
	}
}