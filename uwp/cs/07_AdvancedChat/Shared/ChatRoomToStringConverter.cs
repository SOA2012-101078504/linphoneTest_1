using Linphone;
using System;
using System.Linq;
using Windows.UI.Xaml.Data;

namespace _07_AdvancedChat.Shared
{
	public class ChatRoomToStringConverter : IValueConverter
	{
		object IValueConverter.Convert(object value, Type targetType, object parameter, string language)
		{
			ChatRoom chatRoom = (ChatRoom)value;
			string nameInList = null;
			if (chatRoom.HasCapability((int)ChatRoomCapabilities.Basic))
			{
				nameInList = chatRoom.PeerAddress.Username;
			}
			else if (chatRoom.HasCapability((int)ChatRoomCapabilities.OneToOne))
			{
				nameInList = chatRoom.Participants.FirstOrDefault() == null ? "" : chatRoom.Participants.First().Address.Username;
			}
			else if (chatRoom.HasCapability((int)ChatRoomCapabilities.Conference))
			{
				nameInList = chatRoom.Subject;
			}

			// You can check the Encrypted ChatRoomCapabilities to know if a ChatRoom uses
			// encryption or not.
			if (chatRoom.HasCapability((int)ChatRoomCapabilities.Encrypted))
			{
				nameInList += " #SECURE#";
			}

			if (String.IsNullOrEmpty(nameInList))
			{
				nameInList = "Incoherent ChatRoom values";
			}

			return nameInList;
		}

		object IValueConverter.ConvertBack(object value, Type targetType, object parameter, string language)
		{
			throw new NotImplementedException();
		}
	}
}