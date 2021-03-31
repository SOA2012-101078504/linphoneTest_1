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
package org.linphone.basicchat

import android.graphics.BitmapFactory
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.linphone.core.*
import java.io.File
import java.io.FileOutputStream

class BasicChatActivity: AppCompatActivity() {
    private lateinit var core: Core
    private var chatRoom: ChatRoom? = null

    private val coreListener = object: CoreListenerStub() {
        override fun onRegistrationStateChanged(
            core: Core,
            proxyConfig: ProxyConfig,
            state: RegistrationState?,
            message: String
        ) {
            findViewById<TextView>(R.id.registration_status).text = message

            if (state == RegistrationState.Failed) {
                core.clearAllAuthInfo()
                core.clearProxyConfig()
                findViewById<Button>(R.id.connect).isEnabled = true
            } else if (state == RegistrationState.Ok) {
                findViewById<LinearLayout>(R.id.register_layout).visibility = View.GONE
                findViewById<RelativeLayout>(R.id.chat_layout).visibility = View.VISIBLE
            }
        }

        override fun onMessageReceived(core: Core, chatRoom: ChatRoom, message: ChatMessage) {
            // We will be called in this when a message is received
            // If the chat room wasn't existing, it is automatically created by the library
            // If we already sent a chat message, the chatRoom variable will be the same as the one we already have
            if (this@BasicChatActivity.chatRoom == null) {
                if (chatRoom.hasCapability(ChatRoomCapabilities.Basic.toInt())) {
                    // Keep the chatRoom object to use it to send messages if it hasn't been created yet
                    this@BasicChatActivity.chatRoom = chatRoom
                    findViewById<EditText>(R.id.remote_address).setText(chatRoom.peerAddress.asStringUriOnly())
                    findViewById<EditText>(R.id.remote_address).isEnabled = false
                }
            }

            // We will notify the sender the message has been read by us
            chatRoom.markAsRead()
            addMessageToHistory(message)
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

        setContentView(R.layout.basic_chat_activity)

        val factory = Factory.instance()
        factory.setDebugMode(true, "Hello Linphone")
        core = factory.createCore(null, null, this)

        findViewById<Button>(R.id.connect).setOnClickListener {
            login()
            it.isEnabled = false
        }

        findViewById<Button>(R.id.send_message).setOnClickListener {
            sendMessage()
        }

        findViewById<ImageView>(R.id.send_image).setOnClickListener {
            sendImage()
        }
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

        val proxyConfig = core.createProxyConfig()
        val identity = Factory.instance().createAddress("sip:$username@$domain")
        proxyConfig.identityAddress = identity

        val address = Factory.instance().createAddress("sip:$domain")
        address?.transport = transportType
        proxyConfig.serverAddr = address?.asStringUriOnly()
        proxyConfig.enableRegister(true)

        core.addAuthInfo(authInfo)
        core.addProxyConfig(proxyConfig)

        core.defaultProxyConfig = proxyConfig
        core.addListener(coreListener)
        core.start()
    }

    private fun createBasicChatRoom() {
        // In this tutorial we will create a Basic chat room
        // It doesn't include advanced features such as end-to-end encryption or groups
        // But it is interoperable with any SIP service as it's relying on SIP SIMPLE messages
        // If you try to enable a feature not supported by the basic backend, isValid() will return false
        val params = core.createDefaultChatRoomParams()
        params.backend = ChatRoomBackend.Basic
        params.enableEncryption(false)
        params.enableGroup(false)

        if (params.isValid) {
            // We also need the SIP address of the person we will chat with
            val remoteSipUri = findViewById<EditText>(R.id.remote_address).text.toString()
            val remoteAddress = Factory.instance().createAddress(remoteSipUri)

            if (remoteAddress != null) {
                // And finally we will need our local SIP address
                val localAddress = core.defaultProxyConfig?.identityAddress
                val room = core.createChatRoom(params, localAddress, arrayOf(remoteAddress))
                if (room != null) {
                    chatRoom = room
                    findViewById<EditText>(R.id.remote_address).isEnabled = false
                }
            }
        }
    }

    private fun sendMessage() {
        if (chatRoom == null) {
            // We need a ChatRoom object to send chat messages in it, so let's create it if it hasn't been done yet
            createBasicChatRoom()
        }

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

    private fun sendImage() {
        if (chatRoom == null) {
            // We need a ChatRoom object to send chat messages in it, so let's create it if it hasn't been done yet
            createBasicChatRoom()
        }

        // We need to create a Content for our file transfer
        val content = Factory.instance().createContent()
        // Every content needs a content type & subtype
        content.type = "image"
        content.subtype = "png"

        // The simplest way to upload a file is to provide it's path
        // First copy the sample file from assets to the app directory if not done yet
        val filePath = "${filesDir.absoluteFile}/belledonne.png"
        copy("belledonne.png", filePath)
        content.filePath =  filePath

        // We need to create a ChatMessage object using the ChatRoom
        val chatMessage = chatRoom!!.createFileTransferMessage(content)

        // Then we can send it, progress will be notified using the onMsgStateChanged callback
        chatMessage.addListener(chatMessageListener)

        // Ensure a file sharing server URL is correctly set in the Core
        core.fileTransferServer = "https://www.linphone.org:444/lft.php"

        addMessageToHistory(chatMessage)

        // Send the message
        chatMessage.send()
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

    private fun copy(from: String, to: String) {
        // Used to copy a file from the assets to the app directory
        val outFile = File(to)
        if (outFile.exists()) {
            return
        }

        val outStream = FileOutputStream(outFile)
        val inFile = assets.open(from)
        val buffer = ByteArray(1024)
        var length: Int = inFile.read(buffer)

        while (length > 0) {
            outStream.write(buffer, 0, length)
            length = inFile.read(buffer)
        }

        inFile.close()
        outStream.flush()
        outStream.close()
    }
}