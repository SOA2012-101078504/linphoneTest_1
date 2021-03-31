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
package org.linphone.helloworld

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.linphone.core.Factory

class HelloWorldActivity: AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check the app/build.gradle to see how to import the LibLinphone SDK !!!

        setContentView(R.layout.hello_world_activity)
        val coreVersion = findViewById<TextView>(R.id.core_version)

        // Core is the main object of the SDK. You can't do much without it.
       // To create a Core, we need the instance of the Factory.
        val factory = Factory.instance()

        // Some configuration can be done before the Core is created, for example enable debug logs.
        factory.setDebugMode(true, "Hello Linphone")

        // Your Core can use up to 2 configuration files, but that isn't mandatory.
        // On Android the Core needs to have the application context to work.
        // If you don't, the following method call will crash.
        val core = factory.createCore(null, null, this)

        // Now we can start using the Core object
        coreVersion.text = core.version
    }
}