const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.database();
const messaging = admin.messaging();

/**
 * MAIN TRIGGER: Listen to /processed/{deviceId} for predictions
 * This fires when Python ML function writes to processed data

 */
exports.notifyOnPrediction = functions
  .region("europe-west1")
  .database.ref("processed/{deviceId}")
  .onWrite(async (change, context) => {
    try {
      const { deviceId } = context.params;
      const newData = change.after.val();

      console.log("\n" + "=".repeat(70));
      console.log(`📊 PROCESSED DATA WRITTEN FOR DEVICE: ${deviceId}`);
      console.log("=".repeat(70));
      console.log(`Data type: ${typeof newData}`);
      console.log(`Data keys: ${Object.keys(newData || {}).join(", ")}`);
      
      if (!newData) {
        console.log("⚠️ No data in update");
        return null;
      }

      // Step 1: Get FCM token
      console.log(`\n🔍 Step 1: Looking for FCM token...`);
      console.log(`   Path: /devices/${deviceId}/fcmToken`);

      const tokenSnapshot = await db
        .ref(`devices/${deviceId}/fcmToken`)
        .get()
        .catch((err) => {
          console.error(`❌ Error getting FCM token: ${err.message}`);
          return null;
        });

      if (!tokenSnapshot || !tokenSnapshot.exists()) {
        console.log(`❌ FCM token NOT FOUND at /devices/${deviceId}/fcmToken`);
        return null;
      }

      const fcmToken = tokenSnapshot.val();
      console.log(`✅ FCM token found`);
      console.log(`   Token: ${String(fcmToken).substring(0, 30)}...`);

      // Step 2: Extract sensor data and prediction
      console.log(`\n🔍 Step 2: Extracting sensor data and prediction...`);

      let sensorReadings = null;
      let prediction = null;
      let recordId = null;

      // Check if this is nested structure with recordId
      if (typeof newData === "object" && !Array.isArray(newData)) {
        const entries = Object.entries(newData);
        console.log(`   Map entries: ${entries.length}`);

        for (const [key, value] of entries) {
          if (
            value &&
            typeof value === "object" &&
            (value.prediction !== undefined || value.sensor_readings !== undefined)
          ) {
            console.log(`   ✅ Found prediction/sensor data at key: ${key}`);
            recordId = key;
            prediction = value.prediction;
            sensorReadings = value.sensor_readings;
            break;
          }
        }
      }

      // If not nested, treat entire object as flat sensor data
      if (!sensorReadings) {
        console.log(`   Using flat structure (all values as sensor data)`);
        sensorReadings = newData;
      }

      console.log(`   Prediction: ${prediction}`);
      console.log(`   Sensor readings keys: ${Object.keys(sensorReadings || {}).join(", ")}`);

      // Step 3: Build alerts
      console.log(`\n🔍 Step 3: Checking thresholds...`);
      const alerts = checkThresholds(sensorReadings, prediction);
      console.log(`   Alerts generated: ${alerts.length}`);

      if (alerts.length === 0) {
        console.log(`   ✅ No alerts needed`);
        return null;
      }

      // Step 4: Send notifications
      console.log(`\n📤 Step 4: Sending ${alerts.length} notification(s)...`);

      const sendPromises = [];

      for (const alert of alerts) {
        console.log(`\n   Alert type: ${alert.type}`);
        console.log(`   Title: ${alert.title}`);
        console.log(`   Body: ${alert.body}`);

        const sendPromise = (async () => {
          try {
            // Send notification
            const response = await messaging.send({
              token: fcmToken,
              notification: {
                title: alert.title,
                body: alert.body,
              },
              data: {
                type: alert.type,
                deviceId: deviceId,
                timestamp: new Date().toISOString(),
              },
              android: {
                priority: "high",
              },
            });
            
            console.log(`   ✅ Notification sent`);
            console.log(`      Message ID: ${response}`);

            // Store in database for history (fire and forget)
            db.ref(`alerts/${deviceId}`).push({
              type: alert.type,
              title: alert.title,
              body: alert.body,
              prediction: prediction,
              sensorReadings: sensorReadings,
              timestamp: admin.database.ServerValue.TIMESTAMP,
            }).catch((err) => {
              console.warn(`   ⚠️ Failed to store alert: ${err.message}`);
            });

          } catch (sendError) {
            console.error(`   ❌ Error sending notification: ${sendError.message}`);
          }
        })();

        sendPromises.push(sendPromise);
      }

      // Wait for all sends to complete
      await Promise.all(sendPromises).catch((err) => {
        console.error(`⚠️ Some notifications failed: ${err.message}`);
      });

      console.log("\n" + "=".repeat(70) + "\n");
      return null;

    } catch (error) {
      console.error("❌ ERROR IN NOTIFY ON PREDICTION:", error);
      console.error("Stack:", error.stack);
      return null;
    }
  });

/**
 * Check sensor thresholds and return alerts
 * ENHANCED: More specific alerts for nutrients, temperature, pH, etc.
 */
function checkThresholds(sensorReadings, mlPrediction) {
  const alerts = [];

  // ML Model Alert - highest priority
  if (mlPrediction === 1) {
    alerts.push({
      type: "ml_alert",
      title: "🚨 Critical Alert",
      body: "ML model detected potential issues with your farm",
    });
    console.log(`      ⚠️ ML Prediction = 1 (alert)`);
    return alerts; // Return immediately if ML says alert
  }

  if (!sensorReadings || typeof sensorReadings !== "object") {
    console.log(`      No sensor readings to check`);
    return alerts;
  }

  // Parse sensor values safely
  const parseVal = (v) => {
    if (v === null || v === undefined) return -1;
    const num = parseFloat(v);
    return isNaN(num) ? -1 : num;
  };

  const waterLevel = parseVal(sensorReadings.water_level);
  const tds = parseVal(sensorReadings.TDS);
  const ph = parseVal(sensorReadings.pH);
  const temp = parseVal(sensorReadings.DHT_temp);
  const humidity = parseVal(sensorReadings.DHT_humidity);

  console.log(`      Water: ${waterLevel}cm, TDS: ${tds}ppm, pH: ${ph}, Temp: ${temp}°C, Humidity: ${humidity}%`);

  // ========== CRITICAL WATER LEVEL ==========
  if (waterLevel > 0 && waterLevel < 10) {
    alerts.push({
      type: "water_critical",
      title: "🚨 CRITICAL: Tank Almost Empty",
      body: `Water level: ${waterLevel.toFixed(1)}cm - Refill immediately!`,
    });
  } else if (waterLevel > 0 && waterLevel < 20) {
    alerts.push({
      type: "water_low",
      title: "⚠️ Water Level Low",
      body: `Water level: ${waterLevel.toFixed(1)}cm - Refill soon`,
    });
  }

  // ========== NUTRIENTS (TDS) ==========
  if (tds > 0 && tds < 400) {
    alerts.push({
      type: "tds_low",
      title: "🌱 NUTRIENT ALERT: TDS Too Low",
      body: `TDS: ${tds.toFixed(0)}ppm - Nutrients are low, add fertilizer`,
    });
  } else if (tds > 0 && tds > 1800) {
    alerts.push({
      type: "tds_high",
      title: "⚠️ NUTRIENT ALERT: TDS Too High",
      body: `TDS: ${tds.toFixed(0)}ppm - Solution too concentrated, dilute`,
    });
  }

  // ========== pH LEVEL ==========
  if (ph > 0 && ph < 5.5) {
    alerts.push({
      type: "ph_critical_low",
      title: "🔴 pH CRITICAL: Too Acidic",
      body: `pH: ${ph.toFixed(1)} - raise pH immediately`,
    });
  } else if (ph > 0 && ph > 8.5) {
    alerts.push({
      type: "ph_critical_high",
      title: "🔴 pH CRITICAL: Too Alkaline",
      body: `pH: ${ph.toFixed(1)} - lower pH immediately`,
    });
  } else if (ph > 0 && (ph < 6.0 || ph > 8.0)) {
    alerts.push({
      type: "ph_warning",
      title: "⚠️ pH Anomaly",
      body: `pH: ${ph.toFixed(1)} (Normal: 6.0-8.0)`,
    });
  }

  // ========== TEMPERATURE ==========
  if (temp > -100 && temp < 10) {
    alerts.push({
      type: "temp_critical_cold",
      title: "❄️ CRITICAL: Too Cold",
      body: `Temperature: ${temp.toFixed(1)}°C - Heat system immediately`,
    });
  } else if (temp > -100 && temp > 35) {
    alerts.push({
      type: "temp_critical_hot",
      title: "🔥 CRITICAL: Too Hot",
      body: `Temperature: ${temp.toFixed(1)}°C - Cool system immediately`,
    });
  } else if (temp > -100 && (temp < 18 || temp > 28)) {
    alerts.push({
      type: "temp_warning",
      title: "🌡️ Temperature Warning",
      body: `Temperature: ${temp.toFixed(1)}°C (Normal: 18-28°C)`,
    });
  }

  // ========== HUMIDITY ==========
  if (humidity > 0 && humidity < 30) {
    alerts.push({
      type: "humidity_low",
      title: "💧 Humidity Low",
      body: `Humidity: ${humidity.toFixed(0)}% - Increase moisture in grow area`,
    });
  } else if (humidity > 0 && humidity > 85) {
    alerts.push({
      type: "humidity_high",
      title: "💨 Humidity High",
      body: `Humidity: ${humidity.toFixed(0)}% - Improve air circulation`,
    });
  }

  return alerts;
}

/**
 * Test notification - */
exports.testNotification = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
      }

      const { deviceId, title, body } = data;

      if (!deviceId) {
        throw new functions.https.HttpsError("invalid-argument", "deviceId is required");
      }

      console.log(`\n📤 TEST NOTIFICATION REQUESTED FOR DEVICE: ${deviceId}`);

      const tokenSnapshot = await db.ref(`devices/${deviceId}/fcmToken`).get();

      if (!tokenSnapshot.exists()) {
        throw new functions.https.HttpsError("not-found", `No FCM token found for device: ${deviceId}`);
      }

      const fcmToken = tokenSnapshot.val();

      await messaging.send({
        token: fcmToken,
        notification: {
          title: title || "🧪 Test Notification",
          body: body || "This is a test notification from Firebase",
        },
        data: {
          type: "test",
          deviceId: deviceId,
          timestamp: new Date().toISOString(),
        },
        android: {
          priority: "high",
        },
      });

      console.log(`✅ Test notification sent to device: ${deviceId}\n`);

      return {
        success: true,
        message: "Test notification sent",
        deviceId: deviceId,
      };
    } catch (error) {
      console.error("❌ Error in testNotification:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  });

/**
 * Get alerts for device - SAME REGION
 */
exports.getAlerts = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
      }

      const { deviceId, limit = 20 } = data;

      if (!deviceId) {
        throw new functions.https.HttpsError("invalid-argument", "deviceId is required");
      }

      const snapshot = await db.ref(`alerts/${deviceId}`).limitToLast(limit).get();

      const alerts = [];
      snapshot.forEach((childSnapshot) => {
        alerts.push({
          id: childSnapshot.key,
          ...childSnapshot.val(),
        });
      });

      return {
        success: true,
        alerts: alerts.reverse(),
        count: alerts.length,
      };
    } catch (error) {
      console.error("❌ Error in getAlerts:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  });

/**
 * Clear old alerts - SAME REGION
 */
exports.clearOldAlerts = functions
  .region("europe-west1")
  .pubsub.schedule("every 24 hours")
  .onRun(async (context) => {
    try {
      const thirtyDaysAgo = Date.now() - 30 * 24 * 60 * 60 * 1000;
      const snapshot = await db.ref("alerts").get();

      if (!snapshot.exists()) {
        console.log("No alerts to clean up");
        return null;
      }

      let deletedCount = 0;
      const updates = {};

      snapshot.forEach((deviceSnapshot) => {
        deviceSnapshot.forEach((alertSnapshot) => {
          const timestamp = alertSnapshot.val().timestamp;
          if (timestamp < thirtyDaysAgo) {
            updates[`alerts/${deviceSnapshot.key}/${alertSnapshot.key}`] = null;
            deletedCount++;
          }
        });
      });

      await db.ref().update(updates);
      console.log(`✅ Cleaned up ${deletedCount} old alerts`);
      return null;
    } catch (error) {
      console.error("❌ Error cleaning up alerts:", error);
      return null;
    }
  });