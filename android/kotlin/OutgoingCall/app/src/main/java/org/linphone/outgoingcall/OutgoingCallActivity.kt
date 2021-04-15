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
package org.linphone.outgoingcall

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.linphone.core.*
import org.linphone.core.tools.Log

class OutgoingCallActivity: AppCompatActivity() {
    private lateinit var core: Core

    private val coreListener = object: CoreListenerStub() {
        override fun onAccountRegistrationStateChanged(core: Core, account: Account, state: RegistrationState?, message: String) {
            findViewById<TextView>(R.id.registration_status).text = message

            if (state == RegistrationState.Failed) {
                findViewById<Button>(R.id.connect).isEnabled = true
            } else if (state == RegistrationState.Ok) {
                findViewById<LinearLayout>(R.id.register_layout).visibility = View.GONE
                findViewById<RelativeLayout>(R.id.call_layout).visibility = View.VISIBLE
            }
        }

        override fun onCallStateChanged(
            core: Core,
            call: Call,
            state: Call.State?,
            message: String
        ) {
            // This function will be called each time a call state changes,
            // which includes new incoming/outgoing calls
            findViewById<TextView>(R.id.call_status).text = message

            when (state) {
                Call.State.OutgoingInit -> {
                    // First state an outgoing call will go through
                }
                Call.State.OutgoingProgress -> {
                    // Right after outgoing init
                }
                Call.State.OutgoingRinging -> {
                    // This state will be reached upon reception of the 180 RINGING
                }
                Call.State.Connected -> {
                    // When the 200 OK has been received
                }
                Call.State.StreamsRunning -> {
                    // This state indicates the call is active.
                    // You may reach this state multiple times, for example after a pause/resume
                    // or after the ICE negotiation completes
                    // Wait for the call to be connected before allowing a call update
                    findViewById<Button>(R.id.pause).isEnabled = true
                    findViewById<Button>(R.id.pause).text = "Pause"
                    findViewById<Button>(R.id.toggle_video).isEnabled = true

                    // Only enable toggle camera button if there is more than 1 camera and the video is enabled
                    // We check if core.videoDevicesList.size > 2 because of the fake camera with static image created by our SDK (see below)
                    findViewById<Button>(R.id.toggle_camera).isEnabled = core.videoDevicesList.size > 2 && call.currentParams.videoEnabled()
                }
                Call.State.Paused -> {
                    // When you put a call in pause, it will became Paused
                    findViewById<Button>(R.id.pause).text = "Resume"
                    findViewById<Button>(R.id.toggle_video).isEnabled = false
                }
                Call.State.PausedByRemote -> {
                    // When the remote end of the call pauses it, it will be PausedByRemote
                }
                Call.State.Updating -> {
                    // When we request a call update, for example when toggling video
                }
                Call.State.UpdatedByRemote -> {
                    // When the remote requests a call update
                }
                Call.State.Released -> {
                    // Call state will be released shortly after the End state
                    findViewById<EditText>(R.id.remote_address).isEnabled = true
                    findViewById<Button>(R.id.call).isEnabled = true
                    findViewById<Button>(R.id.pause).isEnabled = false
                    findViewById<Button>(R.id.pause).text = "Pause"
                    findViewById<Button>(R.id.toggle_video).isEnabled = false
                    findViewById<Button>(R.id.hang_up).isEnabled = false
                    findViewById<Button>(R.id.toggle_camera).isEnabled = false
                }
                Call.State.Error -> {

                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.outgoing_call_activity)

        val factory = Factory.instance()
        factory.setDebugMode(true, "Hello Linphone")
        core = factory.createCore(null, null, this)

        findViewById<Button>(R.id.connect).setOnClickListener {
            login()
            it.isEnabled = false
        }

        // For video to work, we need two TextureViews:
        // one for the remote video and one for the local preview
        core.nativeVideoWindowId = findViewById(R.id.remote_video_surface)
        // The local preview is a org.linphone.mediastream.video.capture.CaptureTextureView
        // which inherits from TextureView and contains code to keep the ratio of the capture video
        core.nativePreviewWindowId = findViewById(R.id.local_preview_video_surface)

        // Here we enable the video capture & display at Core level
        // It doesn't mean calls will be made with video automatically,
        // But it allows to use it later
        core.enableVideoCapture(true)
        core.enableVideoDisplay(true)

        // When enabling the video, the remote will either automatically answer the update request
        // or it will ask it's user depending on it's policy.
        // Here we have configured the policy to always automatically accept video requests
        core.videoActivationPolicy.automaticallyAccept = true
        // If you don't want to automatically accept,
        // you'll have to use a code similar to the one in toggleVideo to answer a received request

        // If the following property is enabled, it will automatically configure created call params with video enabled
        //core.videoActivationPolicy.automaticallyInitiate = true

        findViewById<Button>(R.id.call).setOnClickListener {
            outgoingCall()
            findViewById<EditText>(R.id.remote_address).isEnabled = false
            it.isEnabled = false
            findViewById<Button>(R.id.hang_up).isEnabled = true
        }

        findViewById<Button>(R.id.hang_up).setOnClickListener {
            hangUp()
        }

        findViewById<Button>(R.id.pause).setOnClickListener {
            pauseOrResume()
        }

        findViewById<Button>(R.id.toggle_video).setOnClickListener {
            toggleVideo()
        }

        findViewById<Button>(R.id.toggle_camera).setOnClickListener {
            toggleCamera()
        }

        findViewById<Button>(R.id.pause).isEnabled = false
        findViewById<Button>(R.id.toggle_video).isEnabled = false
        findViewById<Button>(R.id.toggle_camera).isEnabled = false
        findViewById<Button>(R.id.hang_up).isEnabled = false
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
        val account = core.createAccount(params)

        core.addAuthInfo(authInfo)
        core.addAccount(account)

        core.defaultAccount = account
        core.addListener(coreListener)
        core.start()

        // We will need the RECORD_AUDIO permission for video call
        if (packageManager.checkPermission(Manifest.permission.RECORD_AUDIO, packageName) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 0)
            return
        }
    }

    private fun outgoingCall() {
        // As for everything we need to get the SIP URI of the remote and convert it to an Address
        val remoteSipUri = findViewById<EditText>(R.id.remote_address).text.toString()
        val remoteAddress = Factory.instance().createAddress(remoteSipUri)
        remoteAddress ?: return // If address parsing fails, we can't continue with outgoing call process

        // We also need a CallParams object
        // Create call params expects a Call object for incoming calls, but for outgoing we must use null safely
        val params = core.createCallParams(null)
        params ?: return // Same for params

        // We can now configure it
        // Here we ask for no encryption but we could ask for ZRTP/SRTP/DTLS
        params.mediaEncryption = MediaEncryption.None
        // If we wanted to start the call with video directly
        //params.enableVideo(true)

        // Finally we start the call
        core.inviteAddressWithParams(remoteAddress, params)
        // Call process can be followed in onCallStateChanged callback from core listener
    }

    private fun hangUp() {
        if (core.callsNb == 0) return

        // If the call state isn't paused, we can get it using core.currentCall
        val call = if (core.currentCall != null) core.currentCall else core.calls[0]
        call ?: return

        // Terminating a call is quite simple
        call.terminate()
    }

    private fun toggleVideo() {
        if (core.callsNb == 0) return
        val call = if (core.currentCall != null) core.currentCall else core.calls[0]
        call ?: return

        // We will need the CAMERA permission for video call
        if (packageManager.checkPermission(Manifest.permission.CAMERA, packageName) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.CAMERA), 0)
            return
        }

        // To update the call, we need to create a new call params, from the call object this time
        val params = core.createCallParams(call)
        // Here we toggle the video state (disable it if enabled, enable it if disabled)
        // Note that we are using currentParams and not params or remoteParams
        // params is the object you configured when the call was started
        // remote params is the same but for the remote
        // current params is the real params of the call, resulting of the mix of local & remote params
        params?.enableVideo(!call.currentParams.videoEnabled())
        // Finally we request the call update
        call.update(params)

        // Note that when toggling off the video, TextureViews will keep showing the latest frame displayed
    }

    private fun toggleCamera() {
        // Currently used camera
        val currentDevice = core.videoDevice

        // Let's iterate over all camera available and choose another one
        for (camera in core.videoDevicesList) {
            // All devices will have a "Static picture" fake camera, and we don't want to use it
            if (camera != currentDevice && camera != "StaticImage: Static picture") {
                core.videoDevice = camera
                break
            }
        }
    }

    private fun pauseOrResume() {
        if (core.callsNb == 0) return
        val call = if (core.currentCall != null) core.currentCall else core.calls[0]
        call ?: return

        if (call.state != Call.State.Paused && call.state != Call.State.Pausing) {
            // If our call isn't paused, let's pause it
            call.pause()
        } else if (call.state != Call.State.Resuming) {
            // Otherwise let's resume it
            call.resume()
        }
    }
}