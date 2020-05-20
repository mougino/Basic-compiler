Basic Compiler
=======

Basic Compiler is an Android app to compile RFO BASIC! applications into an APK.
The Compiler is written in RFO BASIC! and self-compilable. It can be installed on all Android devices from Android 2.1 Eclair up to Android 10.

Basic Compiler source code is released under the GNU GPL v3 licence as per the attached file "gpl.txt". The licence can be found at https://www.gnu.org/licenses/gpl.txt

Basic Compiler requires sensitive permissions in order to work:

* Read phone status and identity
* View network connections
* Read or write the contents of your USB storage

You can find the explanation for the use of these permissions in the privacy policy at http://mougino.free.fr/com.rfo.compiler_privacy_policy.txt

## Installing
Compile the project into an APK, copy it to your Android device and click on it to install it. You need to allow for third party installation on your device: see https://www.androidauthority.com/how-to-install-apks-31494/

## Dependencies
RFO BASIC! itself is of course needed in order to write, run and test your program before compiling it into an APK. Basic Compiler embeds a copy of the latest RFO BASIC! APK: if it is not installed on your device, Basic Compiler will propose to install it for you.

## Building
Basic Compiler can be compiled with any Android compiler, from the Android Command-Line tools to Android Studio, but we strongly recommend using the very simple [Android Xp Tools](http://mougino.free.fr/rfo-basic) from the same author.
