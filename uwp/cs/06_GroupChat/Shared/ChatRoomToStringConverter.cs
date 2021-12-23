using Linphone;
using System;
using System.Linq;
using Windows.UI.Xaml.Data;

namespace _06_GroupChat.Shared
{
	public class ChatRoomToStringConverter : IValueConverter
	{
		object IValueConverter.Convert(object value, Type targetType, object parameter, string language)
		{
			// We use this converter to choose how to display the ChatRoom in the list.
			ChatRoom chatRoom = (ChatRoom)value;
			string nameInList = null;
			if (chatRoom.HasCapability((int)ChatRoomCapabilities.Basic))
			{
				// For a basic ChatRoom we chose to display the peer Username
				nameInList = chatRoom.PeerAddress.Username;
			}
			else if (chatRoom.HasCapability((int)ChatRoomCapabilities.OneToOne))
			{
				// If the ChatRoom is a OneToOne conference (we will speak more about those in further steps)
				nameInList = chatRoom.Participants.FirstOrDefault()?.Address.Username;
			}
			else if (chatRoom.HasCapability((int)ChatRoomCapabilities.Conference))
			{
				// The subject for a conference
				nameInList = chatRoom.Subject;
			}

			if (string.IsNullOrEmpty(nameInList))
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