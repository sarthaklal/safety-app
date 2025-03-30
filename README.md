🚨 SafePath – Your Personal Safety Companion

🧩 Problem Statement

In a world where safety is unpredictable—especially in urban areas or while traveling alone—individuals often find themselves in risky situations without immediate help.
SafePath aims to bridge this gap by providing a smart, AI-driven safety companion accessible right from your Android phone.

👨‍💻 Team Members

Sarthak Lal
Asmi Sharma
Prabhav Singh
Vidhi
🛠️ Demo Video

https://www.youtube.com/watch?v=YnRwrNY_rgI

💡 Solution

SafePath is a feature-rich Android app designed to enhance personal safety using AI, real-time data, and smart hardware components.

Key Features:
🔊 Voice-activated SOS
🆘 One-tap emergency alert to trusted contacts
👥 Notifying nearby users for assistance
🌐 Crowd-sourced unsafe zone reports
🧠 AI-powered danger zone detection
🗺️ Smart route planner avoiding risky areas
🌍 Multilingual support
📱 Smart wearable integration (e.g., shake trigger for SOS)
🔌 IoT Hardware SOS trigger via ESP-based devices
🔌 IoT Components Used

To extend accessibility and improve rapid response during emergencies, SafePath integrates with the following IoT hardware:

📶 ESP8266 / ESP32
Microcontrollers used to send instant SOS signals to the app when triggered.
🔘 Wireless Buttons
Easy-to-press physical buttons used to trigger an SOS alert without needing to unlock the phone.
🔌 Wires & Breadboards
Used for connecting the circuit components and prototyping.
⚙️ Force Sensors
Detect abnormal pressure changes (e.g., strong grip or stomp) and trigger alerts when configured thresholds are crossed.
These IoT elements make SafePath usable even for people with physical or visual impairments and provide backup when phones are inaccessible.

📚 Open-Source Libraries Used

🧭 Location & Maps
geolocator — Fetches device's current location with high accuracy
google_maps_flutter — Integrates Google Maps into the Flutter app
🔔 Notifications
flutter_local_notifications — For scheduling and showing local notifications
firebase_messaging — Handles push notifications via Firebase Cloud Messaging (FCM)
🎙️ Voice & Speech
speech_to_text — Converts user voice to text for voice-triggered SOS
🔒 Permissions & Background Tasks
permission_handler — Manages runtime permissions for location, mic, etc.
background_fetch (if used) — For periodic background updates
📡 Networking
http — Makes API calls to get weather, crime data, or SOS updates
☁️ Backend & Cloud Integration
firebase_core — Core Firebase functions
firebase_auth (if used) — For user authentication
cloud_firestore — Real-time database for chat, reports, alerts, etc.
📦 State Management & UI
provider or bloc (if used) — For managing app state
flutter_svg — To show SVG icons in the app
🌐 APIs Used

🧠 Gemini API (Google AI)
Used for AI-based analysis like detecting unsafe areas, analyzing user reports, and giving smart suggestions.
📍 Google Geocoding API
Converts latitude and longitude into human-readable addresses and vice versa, used for location tagging and route data.
🗺️ Google Maps API
Powers the map view, real-time routing, and visualization of safe/unsafe zones.
🛠️ Installation & Setup Instructions

Clone the repository
git clone https://github.com/sarthaklal/SafePath.git  
cd SafePath  
Open in Android Studio
File → Open → Navigate to the project folder
Install dependencies
Android Studio will auto-sync and install most dependencies via Gradle
Run the app
Connect an Android device or use an emulator
Press the Run ▶️ button
