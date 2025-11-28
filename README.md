# Naihydro: Smart Hydroponic Monitoring System
## A mobile Application for Environment Condition Monitoring in IoT-Enabled Hydroponic Farms for Lettuce Using Random Forest and XGBoost

A comprehensive IoT and machine learning solution for real-time monitoring and anomaly detection in hydroponic lettuce farming.

---

## Table of Contents
- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Prerequisites](#prerequisites)
- [Installation Guide](#installation-guide)
- [Hardware Setup](#hardware-setup)
- [Getting Started](#getting-started)
- [Using the Mobile App](#using-the-mobile-app)
- [Operating the Hardware](#operating-the-hardware)

---

## Overview

Naihydro integrates IoT sensors, cloud computing, and machine learning to provide farmers with real-time monitoring and intelligent decision-making support. The system automatically detects anomalies in pH, temperature, humidity, nutrient levels (TDS), and water level, sending immediate alerts and recommendations through a user-friendly mobile application.

**Key Components:**
- **ESP32 Microcontroller** - Collects sensor data and controls the water pump
- **Firebase Realtime Database** - Stores and synchronizes data in the cloud
- **Flutter Mobile App** - Provides real-time dashboards and controls
- **Machine Learning Backend** - Detects anomalies using Random Forest and XGBoost
- **Node.js Server** - Manages API endpoints and data flow

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APPLICATION                       │
│  (Firebase Auth, Dashboard, Alerts, Pump Control)          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  Firebase Realtime DB  │
        │  - /devices/{id}/      │
        │  - /processed/{id}/    │
        │  - /history/{id}/      │
        └────────────────────────┘
              ▲              ▲
              │              │
    ┌─────────┘              └─────────┐
    │                                   │
    ▼                                   ▼
┌─────────────────────┐      ┌──────────────────────┐
│   ESP32 Controller  │      │  Cloud Functions &   │
│  - Sensor Reading   │      │  ML Backend          │
│  - Pump Control     │◄────►│  - Anomaly Detection │
│  - WiFi Sync        │      │  - Data Processing   │
└─────────────────────┘      └──────────────────────┘
    ▲
    │ (Sensors & Actuators)
    │
┌───┴──────────────────────────────────┐
│  ◯ pH Sensor                         │
│  ◯ DHT22 (Temp & Humidity)           │
│  ◯ TDS Sensor (Nutrients)            │
│  ◯ HC-SR04 (Water Level)             │
│  ◯ Relay + Water Pump                │
└──────────────────────────────────────┘
```

---

## Prerequisites

### Hardware Requirements

| Component | Specification | Purpose |
|-----------|---------------|---------|
| **ESP32 Microcontroller** | WiFi 802.11 b/g/n, Bluetooth | Central processing unit for sensor data collection |
| **pH Sensor** | Analog (0–14 range) | Monitors nutrient solution balance |
| **DHT22 Sensor** | Digital temperature & humidity | Environmental condition monitoring |
| **TDS Sensor** | Analog (0–1000 ppm) | Measures nutrient concentration |
| **HC-SR04 Ultrasonic Sensor** | Ultrasonic distance | Non-contact water level detection |
| **Mini DC Submersible Pump** | 5V DC | Water circulation and nutrient distribution |
| **Relay Module** | 5V signal | Automated pump control |
| **Micro USB Cable** | Standard | ESP32 power and programming |
| **Breadboard & Jumper Wires** | Standard | Circuit assembly |

### Mobile Device Requirements

- **OS:** Android 11 or later
- **Processor:** Octa-core 2.0 GHz or higher
- **RAM:** Minimum 8 GB
- **Storage:** Minimum 32 GB
- **Network:** Stable WiFi connection (≥100 Mbps)

### Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| **Arduino IDE** | Latest | Program ESP32 microcontroller |
| **Flutter SDK** | Latest | Develop mobile application |
| **Dart** | Latest | Flutter programming language |
| **Python** | 3.10–3.12 | ML model training and backend processing |
| **Node.js** | Latest | Backend server and API management |
| **Git** | Latest | Version control |
| **Visual Studio Code / Android Studio** | Latest | Development environment |

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable the following services:
   - **Authentication** (Email/Password)
   - **Realtime Database**
   - **Cloud Messaging** (for push notifications)
   - **Cloud Functions** (for ML inference)

---

## Installation Guide

### 1. Clone the Repository

```bash
git clone https://github.com/is-project-4th-year/group-d-is-projects-NancyMungai.git
cd naihydro
```

### 2. Arduino IDE & ESP32 Setup

#### Install ESP32 Board Manager
1. Open **Arduino IDE**
2. Go to **File** → **Preferences**
3. In "Additional Boards Manager URLs," add:
   ```
   https://dl.espressif.com/dl/package_esp32_index.json
   ```
4. Go to **Tools** → **Board Manager**
5. Search for "ESP32" and install the latest version
6. Select board: **Tools** → **Board** → **ESP32 Dev Module**

#### Upload ESP32 Firmware
1. Connect ESP32 via Micro USB
2. Open `esp32_firmware/hydroponic_monitoring.ino` in Arduino IDE
3. Update WiFi credentials:
   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```
4. Update Firebase URL:
   ```cpp
   const char* firebaseDB = "https://YOUR_PROJECT.firebaseio.com";
   ```
5. Select port: **Tools** → **Port** → (Your ESP32 port)
6. Click **Upload**

**Verification:** Open **Tools** → **Serial Monitor** (9600 baud). You should see:
```
Connected WiFi
Connecting to Firebase...
Publishing sensor data...
```

### 3. Firebase Configuration

#### Create Realtime Database
1. In Firebase Console, go to **Realtime Database**
2. Create database in **Europe (europe-west1)** region
3. Set initial rules to **Test Mode** (for development):
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```

#### Download Configuration Files
1. Go to **Project Settings** → **Service Accounts** → **Generate New Private Key**
2. Save the JSON file to your backend directory
3. For Android app: Download `google-services.json` to `android/app/`

### 4. Backend Setup

#### Install Python Dependencies
```bash
cd backend
pip install -r requirements.txt
```

#### Configure Backend
Create a `.env` file in the backend directory:
```
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key_json_path
GOOGLE_APPLICATION_CREDENTIALS=path_to_service_account.json
```

#### Start Backend Server
```bash
python app.py
```

The server will run on `http://localhost:5000`

### 5. Flutter Mobile App Setup

#### Install Flutter Dependencies
```bash
cd lib
flutter pub get
```

#### Configure Firebase in Flutter
1. Ensure `android/app/google-services.json` exists
2. Update Firebase project ID in `lib/firebase_options.dart`

#### Run Mobile App
```bash
flutter run
```

Or run on a specific device:
```bash
flutter run -d <device_id>
```

---

## Hardware Setup

### Step 1: Wiring the Sensors to ESP32

| Sensor | ESP32 Pin | Function |
|--------|-----------|----------|
| **pH Sensor** | GPIO 34 (Analog A0) | Measures pH (0–14) |
| **DHT22 Data** | GPIO 15 | Temperature & humidity |
| **TDS Sensor** | GPIO 35 (Analog A3) | Nutrient concentration |
| **HC-SR04 Trigger** | GPIO 25 | Ultrasonic pulse |
| **HC-SR04 Echo** | GPIO 26 | Ultrasonic echo |
| **Relay Signal** | GPIO 27 | Pump control |
| **GND** | GND | Ground for all sensors |
| **3.3V** | 3.3V | Power for digital sensors (DHT22) |
| **5V** | 5V | Power for analog sensors & relay |

### Step 2: Assemble the Hydroponic Container

1. **Prepare Container**
   - Use a 1–5 liter nutrient solution plastic container
   - Drill holes for sensor placement and cables

2. **Install Sensors**
   - Place pH sensor and TDS sensor submerged in nutrient solution
   - Position HC-SR04 ultrasonic sensor above water (5–15 cm distance)
   - Mount DHT22 in growing area (not in water)

3. **Connect Water Pump**
   - Place submersible pump inside container
   - Connect pump output to water tubing/drip system
   - Connect pump electrical cable to relay module

4. **Power Connection**
   - Use stable 5V/2A power supply for ESP32
   - Alternatively, use micro USB with power bank

### Step 3: Sensor Calibration

#### pH Sensor Calibration
1. Prepare three calibration solutions: pH 4.0, pH 7.0, pH 10.0
2. In Serial Monitor, record raw analog values for each
3. Calculate slope: `(pH2 - pH1) / (value2 - value1)`
4. Update calibration in firmware (lines 45–50)

#### TDS Sensor Calibration
1. Prepare known TDS solutions (100 ppm, 500 ppm, 1000 ppm)
2. Record analog readings for each
3. Calibrate using the formula in firmware (lines 40–44)

#### Water Level Check
1. Place container at different fill levels
2. Record HC-SR04 distance measurements
3. Verify ultrasonic sensor accuracy (±1 cm tolerance)

### Step 4: Power On and Test

1. **Power ESP32**
   ```
   - Connect USB cable
   - ESP32 LED should light up
   - Check Serial Monitor for connection status
   ```

2. **Verify WiFi Connection**
   ```
   Serial output should show:
   "Connected WiFi"
   "Connected to Firebase"
   ```

3. **Check Firebase Data**
   - Go to Firebase Console
   - Navigate to **Realtime Database**
   - Check `/devices/esp32-001/latest` for sensor readings
   - Data should update every 10 seconds

4. **Test Relay & Pump**
   - From Serial Monitor, send: `PUMP_ON`
   - Relay should click and pump should activate
   - Send: `PUMP_OFF` to stop pump

---

## Getting Started

### First-Time App Setup

#### 1. Launch the App
- Install and open Naihydro on your Android device
- You will see the **Login Page**

#### 2. Create Account
- Tap **Sign Up**
- Enter your email and password
- Tap **Register**
- Verify your email (check spam folder)

#### 3. Add a Farm
- After login, tap **Add Farm** button
- Enter farm details:
  - **Farm Name:** e.g., "Home Lettuce Farm"
  - **Location:** Your farm location
  - **Crop Type:** Select "Lettuce"
- Tap **Save**

#### 4. Connect ESP32 Device
- Tap **Add Device**
- Enter Device ID: `esp32-001` (must match ESP32 firmware)
- Select your farm from dropdown
- Tap **Connect**
- Wait for device status to show "Online"

---

## Using the Mobile App

### Dashboard View
**Location:** Home screen after login

**Displays:**
- Real-time sensor readings:
  - 🌡️ **Temperature** (°C)
  - 💧 **Humidity** (%)
  - 🧪 **pH Level** (0–14)
  - 📊 **TDS** (ppm)
  - 📏 **Water Level** (cm)

- **Status Indicator:**
  - 🟢 Green = All parameters optimal
  - 🟡 Yellow = Approaching warning threshold
  - 🔴 Red = Anomaly detected

### Viewing Historical Data

1. Tap **Analytics** tab
2. Select time period (Last 24h, Last 7d, Last 30d)
3. Charts show:
   - Temperature trend
   - Humidity variation
   - pH stability
   - TDS concentration changes
   - Water level history

### Receiving Alerts

**When an anomaly is detected:**
1. Push notification appears on phone
2. Notification shows:
   - Parameter that triggered alert
   - Current value vs. normal range
   - Recommended action
3. Tap notification to view details
4. Alert history available in **Alerts** section

**Alert Examples:**
- "pH too high (8.2) - Add pH down nutrient"
- "TDS low (300 ppm) - Increase nutrient concentration"
- "Temperature low (12°C) - Check heater"
- "Water level critical - Refill tank"

### Controlling the Water Pump

#### Manual Control
1. Tap **Control Panel** tab
2. Locate **Pump Control** section
3. **Toggle to ON** - Pump starts immediately
4. **Toggle to OFF** - Pump stops

**Status Display:**
```
Pump Status: RUNNING ● (or STOPPED ●)
Current Runtime: 5 minutes
Last Command: 2 minutes ago
```

#### Auto-Control
- The system automatically activates pump when water level drops below threshold
- Pump automatically stops when water level reaches optimal

### Farm Settings

1. Tap **Settings** icon
2. Adjust alert thresholds:
   - pH Range (default: 6.0–7.5)
   - TDS Range (default: 500–1200 ppm)
   - Temperature Range (default: 16–25°C)
   - Water Level Alert (default: <5 cm)
3. Tap **Save Changes**

### Exporting Reports

1. Tap **Reports** tab
2. Select date range
3. Tap **Generate Report**
4. Tap **Download** or **Share**

Report includes:
- Summary statistics
- Historical graphs
- Anomaly log
- Recommendations

### Chat Assistance

1. Tap **Chat** icon (bottom right)
2. Ask questions like:
   - "What should my pH be?"
   - "Why is my TDS low?"
   - "How often should I water?"
3. Chatbot provides instant guidance

---

### Troubleshooting Guide

#### ESP32 Not Sending Data

**Check:**
1. LED on ESP32 is lit (power)
2. WiFi is connected (check Serial Monitor)
3. Firebase URL is correct in firmware
4. Sensor connections are secure

**Solution:**
```bash
# Reupload firmware
1. Open Arduino IDE
2. Tools → Board → ESP32 Dev Module
3. Tools → Port → Select your port
4. Upload button
```

#### Mobile App Shows "Offline"

**Check:**
1. WiFi router is running
2. Phone is on same WiFi network
3. ESP32 shows "Connected" in Serial Monitor
4. Firebase database connection active

**Solution:**
```
1. Restart ESP32 (power cycle)
2. Restart phone WiFi
3. Restart Firebase Console browser tab
4. Wait 2 minutes for reconnection
```

#### Inaccurate Sensor Readings

**pH Sensor:**
- Rinse probe with distilled water
- Recalibrate using buffer solutions
- Check probe is submerged

**TDS Sensor:**
- Clean electrode with distilled water
- Verify sensor is fully submerged
- Recalibrate against known solution

**DHT22:**
- Ensure not exposed to direct water spray
- Check if condensation present
- May need replacement if readings stuck

**HC-SR04:**
- Clean sensor lens
- Verify 5–15 cm water distance
- Check pins aren't bent

#### Pump Not Activating

**Check:**
1. App shows toggle is ON
2. Relay clicking sound present
3. Power to pump verified (5V)
4. Pump cable connections secure

**Solution:**
- Manually test: Connect pump directly to 5V power
- If pump runs: Issue is relay/connection
- If pump doesn't run: Pump may be faulty


## File Structure

```
naihydro/
├── esp32_firmware/
│   └── hydroponic_monitoring.ino      # Main ESP32 code
│
├── lib/src/
│   ├── features/
│   │   ├── auth/presentation/         # Login & registration screens
│   │   ├── data/                      # Data models & services
│   │   ├── farm_repository.dart       # Farm data management
│   │   ├── auth_service.dart          # Firebase authentication
│   │   ├── chat_service.dart          # Chatbot service
│   │   └── esp32_service.dart         # ESP32 communication
│   │
│   ├── pages/
│   │   ├── dashboard_page.dart        # Real-time sensor display
│   │   ├── alerts_page.dart           # Alert history
│   │   ├── control_panel.dart         # Pump control
│   │   ├── farm_details_page.dart     # Farm information
│   │   ├── farm_list_page.dart        # List of farms
│   │   ├── home_page.dart             # Main dashboard
│   │   ├── settings_page.dart         # User preferences
│   │   ├── chat_page.dart             # AI assistant
│   │   └── login_page.dart            # Authentication
│   │
│   ├── widgets/
│   │   ├── alert_item.dart            # Alert card widget
│   │   ├── bottom_nav.dart            # Navigation bar
│   │   ├── primary_button.dart        # Button styles
│   │   ├── status_card.dart           # Sensor display card
│   │   ├── chat_button.dart           # Chat launcher
│   │   └── (other UI components)
│   │
│   ├── common/
│   │   └── services/                  # Shared services
│   │
│   ├── app.dart                       # App entry point
│   ├── firebase_options.dart          # Firebase configuration
│   └── main.dart                      # Application start
│
├── backend/
│   ├── functions/
│   │   ├── anomaly_detection.py       # ML inference
│   │   ├── data_processing.py         # Clean & process data
│   │   └── firebase_operations.py     # Database operations
│   ├── requirements.txt               # Python dependencies
│   └── app.py                         # Backend server
│
├── android/
│   └── app/
│       └── google-services.json       # Firebase config (Android)
│
├── assets/
│   ├── images/                        # App icons & images
│   └── crops/                         # Crop reference images
│
├── pubspec.yaml                       # Flutter dependencies
└── README.md                          # This file
```

---

## System Requirements Summary

### Minimal Setup
- ESP32 microcontroller
- 2–3 sensors (pH, temperature, water level)
- Android phone with WiFi
- Firebase free tier account

### Full Production Setup
- ESP32 with all 5 sensors
- Stable power supply (5V/2A minimum)
- WiFi with ≥10 Mbps
- Backend server running
- Firebase Blaze plan (for heavy ML processing)

---

## Support & Documentation

**Documentation** Refer to the /documentation/ directory for detailed guides

**Video Demo link:** [IoT hydroponic Farm Demo](https://drive.google.com/file/d/1jXXJsbiIpIG8s7e_L_UreRGYxWzlisUB/view?usp=sharing)
## Acknowledgments
This project was developed as part of a Bachelor of Science degree in Informatics and Computer Science at Strathmore University. Special thanks to contributors who made this work possible.

**Project Version:** 1.0.0  
**Last Updated:** November 2025  
