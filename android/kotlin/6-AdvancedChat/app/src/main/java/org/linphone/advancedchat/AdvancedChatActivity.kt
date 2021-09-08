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
package org.linphone.advancedchat

import android.graphics.BitmapFactory
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.linphone.core.*
import java.io.File

class AdvancedChatActivity: AppCompatActivity() {
    private lateinit var core: Core
    private var chatRoom: ChatRoom? = null

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

        override fun onMessageReceived(core: Core, chatRoom: ChatRoom, message: ChatMessage) {
            if (this@AdvancedChatActivity.chatRoom == null) {
                // Check it is an one-to-one encrypted chat room
                if (chatRoom.hasCapability(ChatRoomCapabilities.OneToOne.toInt()) &&
                    chatRoom.hasCapability(ChatRoomCapabilities.Encrypted.toInt())) {
                    // Keep the chatRoom object to use it to send messages if it hasn't been created yet
                    this@AdvancedChatActivity.chatRoom = chatRoom
                    chatRoom.addListener(chatRoomListener)
                    enableEphemeral()

                    findViewById<EditText>(R.id.remote_address).setText(chatRoom.participants.firstOrNull()?.address?.asStringUriOnly())
                    findViewById<EditText>(R.id.remote_address).isEnabled = false
                    findViewById<Button>(R.id.send_message).isEnabled = true
                }
            }

            // We will notify the sender the message has been read by us
            chatRoom.markAsRead()
            addMessageToHistory(message)
        }
    }

    private val chatRoomListener = object: ChatRoomListenerStub() {
        override fun onStateChanged(chatRoom: ChatRoom, newState: ChatRoom.State?) {
            if (newState == ChatRoom.State.Created) {
                findViewById<Button>(R.id.send_message).isEnabled = true
                enableEphemeral()
            }
        }

        override fun onEphemeralEvent(chatRoom: ChatRoom, eventLog: EventLog) {
            // This event is generated when the chat room ephemeral settings are being changed
        }

        override fun onEphemeralMessageDeleted(chatRoom: ChatRoom, eventLog: EventLog) {
            // This is called when a message has expired and we should remove it from the view
            val message = eventLog.chatMessage
            val messageView = message?.userData as? View
            findViewById<LinearLayout>(R.id.messages).removeView(messageView)
        }

        override fun onEphemeralMessageTimerStarted(chatRoom: ChatRoom, eventLog: EventLog) {
            // This is called when a message has been read by all recipient, so the timer has started
            val message = eventLog.chatMessage
            val messageView = message?.userData as? View
            messageView?.setBackgroundColor(getColor(R.color.purple_500))
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
                ChatMessage.State.FileTransferDone -> {
                    // We finished uploading/downloading the file
                    if (!message.isOutgoing) {
                        findViewById<LinearLayout>(R.id.messages).removeView(messageView)
                        addMessageToHistory(message)
                    }
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.advanced_chat_activity)

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

        findViewById<Button>(R.id.create_chat_room).setOnClickListener {
            it.isEnabled = false
            createFlexisipChatRoom()
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
        // In this tutorial we will create a Flexisip one-to-one chat room with end-to-end encryption
        // For it to work, the proxy server we connect to must be an instance of Flexisip
        // And we must have configured on the Account a conference-factory URI
        val params = core.createDefaultChatRoomParams()

        // We won't create a group chat, only a 1-1 with advanced features such as end-to-end encryption
        params.backend = ChatRoomBackend.FlexisipChat
        params.enableGroup(false)

        // We will rely on LIME encryption backend (we must have configured the core.limex3dhServerUrl first)
        params.enableEncryption(true)
        params.encryptionBackend = ChatRoomEncryptionBackend.Lime

        // A flexisip chat room must have a subject
        // But as we are doing a 1-1 chat room here we won't display it, so we can set whatever we want
        params.subject = "dummy subject"

        if (params.isValid) {
            // We also need the SIP address of the person we will chat with
            val remoteSipUri = findViewById<EditText>(R.id.remote_address).text.toString()
            val remoteAddress = Factory.instance().createAddress(remoteSipUri)

            if (remoteAddress != null) {
                // And finally we will need our local SIP address
                val localAddress = core.defaultAccount?.params?.identityAddress
                val room = core.createChatRoom(params, localAddress, arrayOf(remoteAddress))
                if (room != null) {
                    // If chat room isn't created yet, wait for it to go in state Created
                    // as Flexisip chat room creation process is asynchronous
                    room.addListener(chatRoomListener)
                    chatRoom = room
                    findViewById<EditText>(R.id.remote_address).isEnabled = false

                    // Chat room may already be created (for example if you logged in with an account for which the chat room already exists)
                    if (room.state == ChatRoom.State.Created) {
                        findViewById<Button>(R.id.send_message).isEnabled = true
                        enableEphemeral()
                    }
                }
            }
        }
    }

    private fun enableEphemeral() {
        // Once chat room has been created, we can enable ephemeral feature
        // We enable ephemeral messages at the chat room level
        // Please note this only affects messages we send, not the ones we receive
        chatRoom?.enableEphemeral(true)
        // Here we ask for a lifetime of 60 seconds, starting the moment the message has been read
        chatRoom?.ephemeralLifetime = 60
    }

    private fun sendMessage() {
        val message = findViewById<EditText>(R.id.message).text.toString()
        // We need to create a ChatMessage object using the ChatRoom
        val chatMessage = chatRoom!!.createMessageFromUtf8(message)

        // Then we can send it, progress will be notified using the onMsgStateChanged callback
        chatMessage.addListener(chatMessageListener)

        addMessageToHistory(chatMessage)

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
                content.isFile -> {
                    // Content represents a file we received and downloaded or a file we sent
                    // Here we assume it's an image
                    if (content.name?.endsWith(".jpeg") == true ||
                        content.name?.endsWith(".jpg") == true ||
                        content.name?.endsWith(".png") == true) {
                        addImageMessageToHistory(chatMessage, content)
                    }
                }
                content.isFileTransfer -> {
                    // Content represents a received file we didn't download yet
                    addDownloadButtonToHistory(chatMessage, content)
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

    private fun addDownloadButtonToHistory(chatMessage: ChatMessage, content: Content) {
        val buttonView = Button(this)
        val layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        layoutParams.gravity = if (chatMessage.isOutgoing) Gravity.RIGHT else Gravity.LEFT
        buttonView.layoutParams = layoutParams
        buttonView.text = "Download"

        chatMessage.userData = buttonView
        buttonView.setOnClickListener {
            buttonView.isEnabled = false
            // Set the path to where we want the file to be stored
            // Here we will use the app private storage
            content.filePath = "${filesDir.absolutePath}/$content.name}"

            // Start the download
            chatMessage.downloadContent(content)

            // Download progress will be notified through onMsgStateChanged callback,
            // so we need to add a listener if not done yet
            if (!chatMessage.isOutgoing) {
                chatMessage.addListener(chatMessageListener)
            }
        }

        findViewById<LinearLayout>(R.id.messages).addView(buttonView)
        findViewById<ScrollView>(R.id.scroll).fullScroll(ScrollView.FOCUS_DOWN)
    }

    private fun addImageMessageToHistory(chatMessage: ChatMessage, content: Content) {
        val imageView = ImageView(this)
        val layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        layoutParams.gravity = if (chatMessage.isOutgoing) Gravity.RIGHT else Gravity.LEFT
        imageView.layoutParams = layoutParams

        // As we downloaded the file to the content.filePath, we can now use it to display the image
        imageView.setImageBitmap(BitmapFactory.decodeFile(content.filePath))

        chatMessage.userData = imageView

        findViewById<LinearLayout>(R.id.messages).addView(imageView)
        findViewById<ScrollView>(R.id.scroll).fullScroll(ScrollView.FOCUS_DOWN)
    }
}