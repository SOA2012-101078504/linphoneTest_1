/*
 * Copyright (c) 2010-2020 Belledonne Communications SARL.
 *
 * This file is part of linphone-android
 * (see https://www.linphone.org).
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
package org.linphone.groupchat

import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.linphone.core.*
import java.io.File

class GroupChatActivity: AppCompatActivity() {
    private lateinit var core: Core
    private var chatRoom: ChatRoom? = null
    private var remoteAddresses = arrayListOf<Address>()

    private val coreListener = object: CoreListenerStub() {
        override fun onAccountRegistrationStateChanged(core: Core, account: Account, state: RegistrationState?, message: String) {
            findViewById<TextView>(R.id.registration_status).text = message

            if (state == RegistrationState.Failed) {
                core.clearAllAuthInfo()
                core.clearAccounts()
                findViewById<Button>(R.id.connect).isEnabled = true
            } else if (state == RegistrationState.Ok) {
                findViewById<LinearLayout>(R.id.register_layout).visibility = View.GONE
                findViewById<RelativeLayout>(R.id.chat_layout).visibility = View.VISIBLE
            }
        }

        override fun onMessageReceived(core: Core, room: ChatRoom, message: ChatMessage) {
            if (room == chatRoom) {
                // We will notify the sender the message has been read by us
                room.markAsRead()
            }
        }
    }

    private val chatRoomListener = object: ChatRoomListenerStub() {
        override fun onStateChanged(chatRoom: ChatRoom, newState: ChatRoom.State?) {
            if (newState == ChatRoom.State.Created) {
                findViewById<Button>(R.id.send_message).isEnabled = true
                findViewById<Button>(R.id.change_subject).isEnabled = true
                findViewById<EditText>(R.id.subject).isEnabled = true
            }
        }

        // This callback will be dispatched when a new Event is generated
        // For example the subject is changed, participants were added and/or removed,
        // admin status of a participant changed, etc...
        // It will also be called for messages!
        override fun onNewEvent(chatRoom: ChatRoom, eventLog: EventLog) {
            addEventToHistory(eventLog)
        }
    }

    private val chatMessageListener = object: ChatMessageListenerStub() {
        override fun onMsgStateChanged(message: ChatMessage, state: ChatMessage.State?) {
            val messageView = message.userData as? View
            when (state) {
                ChatMessage.State.InProgress -> {
                    messageView?.setBackgroundColor(getColor(R.color.yellow))
                }
                ChatMessage.State.Delivered -> {
                    // The proxy server has acknowledged the message with a 200 OK
                    messageView?.setBackgroundColor(getColor(R.color.orange))
                }
                ChatMessage.State.DeliveredToUser -> {
                    // User as received it
                    messageView?.setBackgroundColor(getColor(R.color.blue))
                }
                ChatMessage.State.Displayed -> {
                    // User as read it (client called chatRoom.markAsRead()
                    messageView?.setBackgroundColor(getColor(R.color.green))
                }
                ChatMessage.State.NotDelivered -> {
                    // User might be invalid or not registered
                    messageView?.setBackgroundColor(getColor(R.color.red))
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.group_chat_activity)

        val factory = Factory.instance()
        factory.setDebugMode(true, "Hello Linphone")

        Factory.instance().setLogCollectionPath(filesDir.absolutePath)
        factory.enableLogCollection(LogCollectionState.Enabled)

        // Delete previous databases if any
        // If not done, will mess when connecting with the same account as before
        File("${filesDir.absoluteFile}/linphone.db").delete()
        File("${filesDir.absoluteFile}/x3dh.c25519.sqlite3").delete()
        File("${filesDir.absoluteFile}/zrtp-secrets.db").delete()

        core = factory.createCore(null, null, this)

        findViewById<Button>(R.id.connect).setOnClickListener {
            login()
            it.isEnabled = false
        }

        findViewById<Button>(R.id.add_participant).setOnClickListener {
            val address = findViewById<EditText>(R.id.participant_address).text.toString()
            val parsedAddress = core.interpretUrl(address)
            if (parsedAddress != null) {
                remoteAddresses.add(parsedAddress)
                findViewById<EditText>(R.id.participant_address).text.clear()
                findViewById<TextView>(R.id.participants).text =
                    findViewById<TextView>(R.id.participants).text.toString() + parsedAddress.asStringUriOnly() + "\n"
                findViewById<Button>(R.id.create_chat_room).isEnabled = true
                if (chatRoom != null) {
                    findViewById<Button>(R.id.create_chat_room).text = "Update"
                }
            }
        }

        findViewById<Button>(R.id.create_chat_room).setOnClickListener {
            if (chatRoom == null) {
                createFlexisipChatRoom()
            } else {
                updateParticipantsList()
            }
        }

        findViewById<Button>(R.id.change_subject).setOnClickListener {
            // This will update the subject for all participants in the chat room
            chatRoom?.subject =  findViewById<EditText>(R.id.subject).text.toString()
        }

        findViewById<Button>(R.id.send_message).setOnClickListener {
            sendMessage()
        }
        findViewById<Button>(R.id.send_message).isEnabled = false
    }

    private fun login() {
        val username = findViewById<EditText>(R.id.username).text.toString()
        val password = findViewById<EditText>(R.id.password).text.toString()
        val domain = findViewById<EditText>(R.id.domain).text.toString()
        val transportType = when (findViewById<RadioGroup>(R.id.transport).checkedRadioButtonId) {
            R.id.udp -> TransportType.Udp
            R.id.tcp -> TransportType.Tcp
            else -> TransportType.Tls
        }
        val authInfo = Factory.instance().createAuthInfo(username, null, password, null, null, domain, null)

        val params = core.createAccountParams()
        val identity = Factory.instance().createAddress("sip:$username@$domain")
        params.identityAddress = identity

        val address = Factory.instance().createAddress("sip:$domain")
        address?.transport = transportType
        params.serverAddress = address
        params.registerEnabled = true

        // We need a conference factory URI set on the Account to be able to create chat rooms with flexisip backend
        params.conferenceFactoryUri = "sip:conference-factory@sip.linphone.org"

        core.addAuthInfo(authInfo)
        val account = core.createAccount(params)
        core.addAccount(account)

        // We also need a LIME X3DH server URL configured for end to end encryption
        core.limeX3DhServerUrl = "https://lime.linphone.org/lime-server/lime-server.php"

        core.defaultAccount = account
        core.addListener(coreListener)
        core.start()
    }

    private fun createFlexisipChatRoom() {
        // In this tutorial we will create a Flexisip group chat room,
        // and we won't enable end-to-end encryption like in previous tutorial to keep it focused.
        // For it to work, the proxy server we connect to must be an instance of Flexisip
        // And we must have configured on the Account a conference-factory URI
        val params = core.createDefaultChatRoomParams()

        // We will create a group chat room without end-to-end encryption
        params.backend = ChatRoomBackend.FlexisipChat
        params.enableGroup(true)
        params.enableEncryption(false)

        // A flexisip chat room must have a subject
        params.subject = findViewById<EditText>(R.id.subject).text.toString()

        if (params.isValid) {
            // We also need the SIP addresses of the persons we will chat with (at least one)
            if (remoteAddresses.size > 0) {
                val addresses = arrayOfNulls<Address>(remoteAddresses.size)
                remoteAddresses.toArray(addresses)
                remoteAddresses.clear()

                // And finally we will need our local SIP address
                val localAddress = core.defaultAccount?.params?.identityAddress
                val room = core.createChatRoom(params, localAddress, addresses)
                if (room != null) {
                    // If chat room isn't created yet, wait for it to go in state Created
                    // as Flexisip chat room creation process is asynchronous
                    room.addListener(chatRoomListener)
                    chatRoom = room
                    findViewById<Button>(R.id.create_chat_room).isEnabled = false

                    // Chat room may already be created (for example if you logged in with an account for which the chat room already exists)
                    if (room.state == ChatRoom.State.Created) {
                        findViewById<Button>(R.id.send_message).isEnabled = true
                        findViewById<Button>(R.id.change_subject).isEnabled = true
                        findViewById<EditText>(R.id.subject).isEnabled = true
                    }
                }
            }
        }
    }

    private fun updateParticipantsList() {
        // Here we will add new participants to our existing chat room, like we do in the creation step
        if (remoteAddresses.size > 0) {
            val addresses = arrayOfNulls<Address>(remoteAddresses.size)
            remoteAddresses.toArray(addresses)
            remoteAddresses.clear()
            chatRoom?.addParticipants(addresses)
        }
        // To remove participants, compute an array of Addresses to remove and call chatRoom?.removeParticipants()
    }

    private fun sendMessage() {
        val message = findViewById<EditText>(R.id.message).text.toString()
        // We need to create a ChatMessage object using the ChatRoom
        val chatMessage = chatRoom!!.createMessageFromUtf8(message)

        // Then we can send it, progress will be notified using the onMsgStateChanged callback
        chatMessage.addListener(chatMessageListener)

        // Send the message
        chatMessage.send()

        // Clear the message input field
        findViewById<EditText>(R.id.message).text.clear()
    }

    private fun addMessageToHistory(chatMessage: ChatMessage) {
        // To display a chat message, iterate over it's contents list
        for (content in chatMessage.contents) {
            when {
                content.isText -> {
                    // Content is of type plain/text
                    addTextMessageToHistory(chatMessage, content)
                }
            }
        }
    }

    private fun addTextMessageToHistory(chatMessage: ChatMessage, content: Content) {
        val messageView = TextView(this)
        val layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        layoutParams.gravity = if (chatMessage.isOutgoing) Gravity.RIGHT else Gravity.LEFT
        messageView.layoutParams = layoutParams

        // Content is of type plain/text, we can get the text in the content
        messageView.text = content.utf8Text

        if (chatMessage.isOutgoing) {
            messageView.setBackgroundColor(getColor(R.color.white))
        } else {
            messageView.setBackgroundColor(getColor(R.color.purple_200))
        }

        chatMessage.userData = messageView

        findViewById<LinearLayout>(R.id.messages).addView(messageView)
        findViewById<ScrollView>(R.id.scroll).fullScroll(ScrollView.FOCUS_DOWN)
    }

    private fun addEventToHistory(eventLog: EventLog) {
        // Each chat message is also an event
        if (eventLog.type == EventLog.Type.ConferenceChatMessage) {
            val chatMessage = eventLog.chatMessage
            if (chatMessage != null) addMessageToHistory(chatMessage)
            return
        }

        val messageView = TextView(this)
        val layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        layoutParams.gravity = Gravity.CENTER

        // A group chat room event can have many types, check the enum for all possible values
        // Here we will focus on subject change & participant manipulation
        messageView.text = when (eventLog.type) {
            EventLog.Type.ConferenceSubjectChanged -> "Subject changed: ${eventLog.subject}"
            EventLog.Type.ConferenceParticipantAdded -> "Participant added: ${eventLog.participantAddress?.asStringUriOnly()}"
            EventLog.Type.ConferenceParticipantRemoved -> "Participant removed: ${eventLog.participantAddress?.asStringUriOnly()}"
            else -> "Event of type: ${eventLog.type}"
        }

        findViewById<LinearLayout>(R.id.messages).addView(messageView)
        findViewById<ScrollView>(R.id.scroll).fullScroll(ScrollView.FOCUS_DOWN)
    }
}