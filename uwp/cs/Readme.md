# Linphone X UWP tutorial

Welcome to the C# tutorial, we are going to learn how to use the Linphone SDK in a UWP (Universal Windows Platform) environment.

We recommend you use Visual Studio 2019 to follow this tutorial.

## Prerequisite: Installing the LinphoneSDK NuGet package

Before you start and if you haven't done so already, you should download and install the LinphoneSDK NuGet package.

1. Choose a local folder (e.g. `Downloads`) and set it as a NuGet source.
   This will be where you put the downloaded .nupkg files.
   In Visual Studio: Tools > NuGet Package Manager > Package Manager Settings > Package Sources > ➕ > Source: ...
2. Download `LinphoneSDK.5.1.0.nupkg` from https://www.linphone.org/snapshots/windows/sdk/ to the folder you chose above.
3. Open the TutorialsCS solution in Visual Studio (TutorialsCS.sln).
4. Right-click on the TutorialsCS solution and 'Restore NuGet Packages'.

## Getting Started

Inside the TutorialsCS solution, you will find several projects, each of which is a step from a hello world to a nearly full-featured communication app using the Linphone SDK. 
Each step builds upon the previous ones but is standalone and can be run on its own. At each step, only new Linphone-related code is explained.

You will find additional Readme files in each project for further details.

- [00_HelloWorld](00_HelloWorld/) : A simple "Hello World" to display the Linphone version number.
- [01_AccountLogin](01_AccountLogin/) : Learn how to login to your SIP account.
- [02_IncomingCall](02_IncomingCall/) : Receive calls.
- [03_OutgoingCall](03_OutgoingCall/) : Make your first calls.
- [04_BasicChat](04_BasicChat/) : Learn how to manage and send message in basic chat rooms.
- [05_FileTransfer](05_FileTransfer/) : Send files in your previously created chat rooms.
- [06_GroupChat](06_GroupChat/) : Create and manage group chat rooms.
- [07_AdvancedChat](07_AdvancedChat/) : Secure chat rooms, ephemeral messages.

To complement this tutorial and to get the complete list of available APIs, take a look at [the Liblinphone documentation](https://linphone.org/releases/docs/liblinphone/5.0/cs/).
