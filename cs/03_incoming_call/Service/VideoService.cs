using System;
using System.Runtime.InteropServices;
using System.Threading;
using Windows.UI.Core;
using Windows.UI.Xaml.Controls;
using EGLNativeWindowType = System.IntPtr;
using OpenGlFunctions = System.IntPtr;

namespace _03_incoming_call.Service
{
	class VideoService
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
		private bool AlearadyStartedOnce { get; set; }
		private bool AlearadyStartedOncePreview { get; set; }
		private Timer Timer { get; set; }

		public struct ContextInfo
		{
			public EGLNativeWindowType window;
			public OpenGlFunctions functions;
		}

		public void StartVideoStream(SwapChainPanel main, SwapChainPanel preview, CoreDispatcher dispatcher)
		{
			CreateRenderSurface(preview, true);
			CreateRenderSurface(main, false);

			Timer = new Timer(OnTimedEvent, dispatcher, 40, 40);
		}

		private async void OnTimedEvent(object state)
		{
			await ((CoreDispatcher)state).RunIdleAsync((args) =>
			{
				CoreService.Core.PreviewOglRender();
				if (CoreService.Core.CurrentCall != null)
					CoreService.Core.CurrentCall.OglRender();
			});
		}

		public void StopVideoStream()
		{
			AlearadyStartedOnce = true;
			if (Timer != null)
			{
				Timer.Dispose();
			}
		}

		public void CreateRenderSurface(SwapChainPanel panel, bool isPreview)
		{// Need to convert C# object into C++. Warning to memory leak
			IntPtr oldData;// Used to release memory after assignation
			ContextInfo c;

			if (panel != null)
			{
				c.window = Marshal.GetIUnknownForObject(panel);
			}
			else
			{
				c.window = IntPtr.Zero;
			}
			c.functions = IntPtr.Zero;

			IntPtr pnt = Marshal.AllocHGlobal(Marshal.SizeOf(c));
			Marshal.StructureToPtr(c, pnt, false);

			if (isPreview)
			{
				oldData = CoreService.Core.NativePreviewWindowId;
				CoreService.Core.NativePreviewWindowId = pnt;
				if (AlearadyStartedOncePreview)
				{
					CleanMemory(oldData);
				}
				AlearadyStartedOncePreview = true;
			}
			else
			{
				if (CoreService.Core.CurrentCall != null)
				{
					oldData = CoreService.Core.CurrentCall.NativeVideoWindowId;
					CoreService.Core.CurrentCall.NativeVideoWindowId = pnt;
					if (AlearadyStartedOnce)
					{
						CleanMemory(oldData);
					}
					AlearadyStartedOnce = true;
				}
			}
		}

		private void CleanMemory(IntPtr context)
		{
			if (context != IntPtr.Zero)
				Marshal.FreeHGlobal(context);
		}
	}
}
