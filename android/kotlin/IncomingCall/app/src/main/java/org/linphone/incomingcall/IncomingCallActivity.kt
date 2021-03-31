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
package org.linphone.incomingcall

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.linphone.core.*

class IncomingCallActivity:  AppCompatActivity() {
    private lateinit var core: Core

    private val coreListener = object: CoreListenerStub() {
        override fun onRegistrationStateChanged(
            core: Core,
            proxyConfig: ProxyConfig,
            state: RegistrationState?,
            message: String
        ) {
            findViewById<TextView>(R.id.registration_status).text = message

            if (state == RegistrationState.Failed) {
                findViewById<Button>(R.id.connect).isEnabled = true
            } else if (state == RegistrationState.Ok) {
                findViewById<LinearLayout>(R.id.register_layout).visibility = View.GONE
                findViewById<RelativeLayout>(R.id.call_layout).visibility = View.VISIBLE
            }
        }

        override fun onAudioDeviceChanged(core: Core, audioDevice: AudioDevice) {
            // This callback will be triggered when a successful audio device has been changed
        }

        override fun onAudioDevicesListUpdated(core: Core) {
            // This callback will be triggered when the available devices list has changed,
            // for example after a bluetooth headset has been connected/disconnected.
        }

        override fun onCallStateChanged(
            core: Core,
            call: Call,
            state: Call.State?,
            message: String
        ) {
            findViewById<TextView>(R.id.call_status).text = message

            // When a call is received
            when (state) {
                Call.State.IncomingReceived -> {
                    findViewById<Button>(R.id.hang_up).isEnabled = true
                    findViewById<Button>(R.id.answer).isEnabled = true
                    findViewById<EditText>(R.id.remote_address).setText(call.remoteAddress.asStringUriOnly())
                }
                Call.State.Connected -> {
                    findViewById<Button>(R.id.mute_mic).isEnabled = true
                    findViewById<Button>(R.id.toggle_speaker).isEnabled = true
                }
                Call.State.Released -> {
                    findViewById<Button>(R.id.hang_up).isEnabled = false
                    findViewById<Button>(R.id.answer).isEnabled = false
                    findViewById<Button>(R.id.mute_mic).isEnabled = false
                    findViewById<Button>(R.id.toggle_speaker).isEnabled = false
                    findViewById<EditText>(R.id.remote_address).text.clear()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.incoming_call_activity)

        val factory = Factory.instance()
        factory.setDebugMode(true, "Hello Linphone")
        core = factory.createCore(null, null, this)

        findViewById<Button>(R.id.connect).setOnClickListener {
            login()
            it.isEnabled = false
        }

        findViewById<Button>(R.id.hang_up).isEnabled = false
        findViewById<Button>(R.id.answer).isEnabled = false
        findViewById<Button>(R.id.mute_mic).isEnabled = false
        findViewById<Button>(R.id.toggle_speaker).isEnabled = false
        findViewById<EditText>(R.id.remote_address).isEnabled = false

        findViewById<Button>(R.id.hang_up).setOnClickListener {
            // Terminates the call, whether it is ringing or running
            core.currentCall?.terminate()
        }

        findViewById<Button>(R.id.answer).setOnClickListener {
            // if we wanted, we could create a CallParams object
            // and answer using this object to make changes to the call configuration
            // (see OutgoingCall tutorial)
            core.currentCall?.accept()
        }

        findViewById<Button>(R.id.mute_mic).setOnClickListener {
            // The following toggles the microphone, disabling completely / enabling the sound capture
            // from the device microphone
            core.enableMic(!core.micEnabled())
        }

        findViewById<Button>(R.id.toggle_speaker).setOnClickListener {
            toggleSpeaker()
        }
    }

    private fun toggleSpeaker() {
        // Get the currently used audio device
        val currentAudioDevice = core.currentCall?.outputAudioDevice
        val speakerEnabled = currentAudioDevice?.type == AudioDevice.Type.Speaker

        // We can get a list of all available audio devices using
        // Note that on tablets for example, there may be no Earpiece device
        for (audioDevice in core.audioDevices) {
            if (speakerEnabled && audioDevice.type == AudioDevice.Type.Earpiece) {
                core.currentCall?.outputAudioDevice = audioDevice
                return
            } else if (!speakerEnabled && audioDevice.type == AudioDevice.Type.Speaker) {
                core.currentCall?.outputAudioDevice = audioDevice
                return
            }/* If we wanted to route the audio to a bluetooth headset
            else if (audioDevice.type == AudioDevice.Type.Bluetooth) {
                core.currentCall?.outputAudioDevice = audioDevice
            }*/
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

        // We will need the RECORD_AUDIO permission for video call
        if (packageManager.checkPermission(Manifest.permission.RECORD_AUDIO, packageName) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 0)
            return
        }
    }
}