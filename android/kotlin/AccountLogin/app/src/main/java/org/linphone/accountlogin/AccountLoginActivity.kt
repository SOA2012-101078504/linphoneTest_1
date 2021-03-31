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
package org.linphone.accountlogin

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.RadioGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.linphone.core.*

class AccountLoginActivity: AppCompatActivity() {
    private lateinit var core: Core

    // Create a Core listener to listen for the callback we need
    // In this case, we want to know about the account registration status
    private val coreListener = object: CoreListenerStub() {
        override fun onRegistrationStateChanged(
            core: Core,
            proxyConfig: ProxyConfig,
            state: RegistrationState?,
            message: String
        ) {
            // If account has been configured correctly, we will go through InProgress and Registered states
            // Otherwise, we will be Failed.
            findViewById<TextView>(R.id.registration_status).text = message

            if (state == RegistrationState.Failed) {
                findViewById<Button>(R.id.connect).isEnabled = true
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.account_login_activity)

        val factory = Factory.instance()
        factory.setDebugMode(true, "Hello Linphone")
        core = factory.createCore(null, null, this)

        findViewById<Button>(R.id.connect).setOnClickListener {
            login()
            it.isEnabled = false
        }

        val coreVersion = findViewById<TextView>(R.id.core_version)
        coreVersion.text = core.version
    }

    private fun login() {
        val username = findViewById<EditText>(R.id.username).text.toString()
        val password = findViewById<EditText>(R.id.password).text.toString()
        val domain = findViewById<EditText>(R.id.domain).text.toString()
        // Get the transport protocol to use.
        // TLS is strongly recommended
        // Only use UDP if you don't have the choice
        val transportType = when (findViewById<RadioGroup>(R.id.transport).checkedRadioButtonId) {
            R.id.udp -> TransportType.Udp
            R.id.tcp -> TransportType.Tcp
            else -> TransportType.Tls
        }

        // To create an account, we need a ProxyConfig object and an AuthInfo object
        // The first one is how to connect to the proxy server, the second one stores the credentials

        // The auth info can be created from the Factory as it's only a data class
        // userID is set to null as it's the same as the username in our case
        // ha1 is set to null as we are using the clear text password. Upon first register, the hash will be computed automatically.
        // The realm will be determined automatically from the first register, as well as the algorithm
        val authInfo = Factory.instance().createAuthInfo(username, null, password, null, null, domain, null)

        // Proxy config object depends on the Core so we can't create it using the Factory
        val proxyConfig = core.createProxyConfig()
        // Proxy config needs an identity address that we can construct from the username and domain
        val identity = Factory.instance().createAddress("sip:$username@$domain")
        proxyConfig.identityAddress = identity

        // We also need to configure where the proxy server is located
        val address = Factory.instance().createAddress("sip:$domain")
        // We use the Address object to easily set the transport protocol
        address?.transport = transportType
        proxyConfig.serverAddr = address?.asStringUriOnly()
        // And we ensure the account will start the registration process
        proxyConfig.enableRegister(true)

        // Now let's add our objects to the Core
        core.addAuthInfo(authInfo)
        core.addProxyConfig(proxyConfig)

        // Also set the newly added account as default
        core.defaultProxyConfig = proxyConfig

        // To be notified of the connection status of our account, we need to add the listener to the Core
        core.addListener(coreListener)

        // Finally we need the Core to be started for the registration to happen (it could have been started before)
        core.start()
    }
}