import firebase_admin
from firebase_admin import storage, credentials, db
from firebase_functions import https_fn, db_fn
import os

# Initialize Firebase App once - do this BEFORE heavy imports
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    "databaseURL": "https://naihydro-default-rtdb.europe-west1.firebasedatabase.app/",
    "storageBucket": "naihydro.firebasestorage.app"
})

# Lazy imports - only import heavy libraries when needed
_numpy = None
_joblib = None
_tempfile = None

def get_numpy():
    global _numpy
    if _numpy is None:
        import numpy as np
        _numpy = np
    return _numpy

def get_joblib():
    global _joblib
    if _joblib is None:
        import joblib
        _joblib = joblib
    return _joblib

def get_tempfile():
    global _tempfile
    if _tempfile is None:
        import tempfile
        _tempfile = tempfile
    return _tempfile

bucket = storage.bucket()
MODEL_PATH = "models/rf_xgb_ensemble.joblib"
model = None 

def load_model():
    """Load and reconstruct ensemble model from Firebase Storage"""
    global model
    if model is None:
        try:
            joblib = get_joblib()
            tempfile = get_tempfile()
            
            temp_model_path = os.path.join(tempfile.gettempdir(), "rf_xgb_ensemble.joblib")
            
            # Check if model is already cached in temp
            if not os.path.exists(temp_model_path):
                print("📥 Downloading model from Firebase Storage...")
                blob = bucket.blob(MODEL_PATH)
                blob.download_to_filename(temp_model_path)
                print("✅ Model downloaded successfully")
            else:
                print("📦 Using cached model")
            
            model_dict = joblib.load(temp_model_path)

            if isinstance(model_dict, dict):
                model = model_dict
                print("✅ Model dictionary loaded successfully.")
            else:
                model = model_dict
                print("✅ Single model loaded successfully.")
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            raise

    return model

def engineer_features(base_data, training_stats):
    """
    Engineer features from base sensor readings using training statistics
    
    Args:
        base_data: dict with keys: pH, TDS, water_level, DHT_temp, DHT_humidity
        training_stats: dict from model containing mean, std, median, q1, q3 for each feature
    
    Returns:
        dict with all 27 features
    """
    np = get_numpy()
    
    features = {}
    
    # Base features
    pH = float(base_data.get('pH', 0))
    TDS = float(base_data.get('TDS', 0))
    water_level = float(base_data.get('water_level', 0))
    DHT_temp = float(base_data.get('DHT_temp', 0))
    DHT_humidity = float(base_data.get('DHT_humidity', 0))
    
    features['pH'] = pH
    features['TDS'] = TDS
    features['water_level'] = water_level
    features['DHT_temp'] = DHT_temp
    features['DHT_humidity'] = DHT_humidity
    
    # Calculate z-scores, percentiles, and median distances for each base feature
    base_features_map = {
        'pH': pH,
        'TDS': TDS,
        'water_level': water_level,
        'DHT_temp': DHT_temp,
        'DHT_humidity': DHT_humidity
    }
    
    for feat_name, feat_value in base_features_map.items():
        if feat_name in training_stats:
            stats = training_stats[feat_name]
            mean = float(stats['mean'])
            std = float(stats['std'])
            median = float(stats['median'])
            q1 = float(stats['q1'])
            q3 = float(stats['q3'])
            
            # Z-score: (value - mean) / std
            features[f'{feat_name}_zscore'] = (feat_value - mean) / std if std != 0 else 0
            
            # Percentile approximation: 50 + 50 * zscore (capped at 0-100)
            zscore = features[f'{feat_name}_zscore']
            percentile = 50 + 50 * zscore
            features[f'{feat_name}_percentile'] = np.clip(percentile, 0, 100)
            
            # Median distance: absolute difference from median
            features[f'{feat_name}_median_dist'] = abs(feat_value - median)
    
    # Interaction features
    features['pH_TDS_product'] = pH * TDS
    features['pH_TDS_ratio'] = pH / TDS if TDS != 0 else 0
    features['temp_humidity_product'] = DHT_temp * DHT_humidity
    features['temp_humidity_ratio'] = DHT_temp / DHT_humidity if DHT_humidity != 0 else 0
    
    # Polynomial features
    features['pH_squared'] = pH ** 2
    features['TDS_squared'] = TDS ** 2
    
    # Total z-score: sum of absolute z-scores
    features['total_zscore'] = (
        abs(features['pH_zscore']) +
        abs(features['TDS_zscore']) +
        abs(features['water_level_zscore']) +
        abs(features['DHT_temp_zscore']) +
        abs(features['DHT_humidity_zscore'])
    )
    
    return features

def make_prediction(features, m):
    """
    Helper function to make predictions
    IMPORTANT: PCA is NOT applied - models were trained on scaled features only
    """
    np = get_numpy()
    
    if isinstance(m, dict):
        # Validate feature count
        if "scaler" in m:
            expected_features = m["scaler"].n_features_in_
            actual_features = features.shape[1]
            
            if actual_features != expected_features:
                raise ValueError(
                    f"Feature mismatch: Expected {expected_features} features, "
                    f"but got {actual_features}."
                )
            
            # Scale the features
            features = m["scaler"].transform(features)
            print(f"   ✓ Scaled {features.shape[1]} features")
        
        # CRITICAL: Do NOT apply PCA
        # The models were trained on scaled features, not PCA components
        # (Verified by debug_pipeline.py - RF/XGB expect 27 features, not 5)
        
        # Make predictions with both models
        rf_pred = m["rf"].predict(features)
        xgb_pred = m["xgb"].predict(features)
        
        # Ensemble: average and round
        ensemble_pred = np.round((rf_pred + xgb_pred) / 2).astype(int)
        return int(ensemble_pred[0])
    else:
        # Single model
        return int(m.predict(features)[0])

# ============================
# HTTP TRIGGER (Manual)
# ============================
@https_fn.on_request(region="europe-west1", memory=1024, timeout_sec=60)
def predict_latest_data(req: https_fn.Request) -> https_fn.Response:
    """
    Handles HTTP requests for manual predictions.
    
    Expects JSON body with either:
    1. Base features: {"pH": x, "TDS": y, "water_level": z, "DHT_temp": a, "DHT_humidity": b}
    2. All 27 features: {"pH": x, "TDS": y, ..., "total_zscore": z}
    """
    try:
        np = get_numpy()
        
        # Handle CORS for browser requests
        if req.method == 'OPTIONS':
            headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Max-Age': '3600'
            }
            return https_fn.Response('', status=204, headers=headers)
        
        body = req.get_json()
        
        if not body:
            return https_fn.Response(
                '{"error": "Missing request body"}',
                status=400,
                mimetype="application/json",
                headers={'Access-Control-Allow-Origin': '*'}
            )
        
        # Load model
        m = load_model()
        
        # Check if we have base features or all features
        base_feature_names = ['pH', 'TDS', 'water_level', 'DHT_temp', 'DHT_humidity']
        has_base_features = all(feat in body for feat in base_feature_names)
        has_all_features = 'feature_cols' in m and all(feat in body for feat in m['feature_cols'])
        
        if has_all_features:
            # User provided all 27 features
            print("📊 Using provided engineered features")
            feature_cols = m['feature_cols']
            features = np.array([[float(body[col]) for col in feature_cols]])
        elif has_base_features:
            # Engineer features from base readings
            print("🔧 Engineering features from base readings")
            engineered = engineer_features(body, m.get('training_stats', {}))
            feature_cols = m['feature_cols']
            features = np.array([[engineered[col] for col in feature_cols]])
        else:
            return https_fn.Response(
                '{"error": "Missing required features. Provide either base features (pH, TDS, water_level, DHT_temp, DHT_humidity) or all 27 features"}',
                status=400,
                mimetype="application/json",
                headers={'Access-Control-Allow-Origin': '*'}
            )
        
        prediction = make_prediction(features, m)
        
        return https_fn.Response(
            f'{{"prediction": {prediction}}}',
            status=200,
            mimetype="application/json",
            headers={'Access-Control-Allow-Origin': '*'}
        )
    
    except Exception as e:
        print(f"❌ Error in predict_latest_data: {e}")
        import traceback
        traceback.print_exc()
        return https_fn.Response(
            f'{{"error": "{str(e)}"}}',
            status=500,
            mimetype="application/json",
            headers={'Access-Control-Allow-Origin': '*'}
        )


# ================================================
# DATABASE TRIGGER (Arduino Sensor Upload)
# ================================================
@db_fn.on_value_written(
    reference="/devices/{deviceId}/latest", 
    region="europe-west1", 
    memory=1024,
    timeout_sec=60
)
def predict_on_new_data(event: db_fn.Change):
    """
    Triggered when new data is uploaded by Arduino to /devices/{deviceId}/latest
    Automatically runs prediction and saves results in /processed/{deviceId}
    
    Extracts only the required sensor readings from Firebase data:
    - pH, TDS, water_level, DHT_temp, DHT_humidity
    
    Ignores other fields like: deviceId, pump_state, relay_state, tds_raw, timestamp
    """
    try:
        np = get_numpy()
        
        data = event.data.after
        if not data:
            print("⚠️ No data received from Arduino.")
            return
        
        print(f"📥 Received data from Arduino: {list(data.keys())}")
        
        # Extract ONLY the required base features (ignore extras like pump_state, relay_state, etc.)
        base_feature_names = ['pH', 'TDS', 'water_level', 'DHT_temp', 'DHT_humidity']
        base_data = {}
        missing = []
        
        for feat in base_feature_names:
            if feat in data:
                # Convert to float and handle any type issues
                try:
                    base_data[feat] = float(data[feat])
                except (ValueError, TypeError) as e:
                    print(f"⚠️  Could not convert {feat}={data[feat]} to float: {e}")
                    base_data[feat] = 0.0
            else:
                missing.append(feat)
                base_data[feat] = 0.0  # Use default value
        
        if missing:
            print(f"⚠️  Missing features (using defaults): {missing}")
        
        print(f"📊 Extracted base features: {base_data}")
        
        # Load model
        m = load_model()
        
        # Engineer all 27 features from base readings
        engineered = engineer_features(base_data, m.get('training_stats', {}))
        
        # Extract features in correct order
        feature_cols = m['feature_cols']
        features = np.array([[engineered[col] for col in feature_cols]])
        
        print(f"Engineered {len(feature_cols)} features for prediction")
        
        # Make prediction
        prediction = make_prediction(features, m)
        
        # Save prediction result back to Firebase
        device_id = event.params["deviceId"]
        result = {
            "sensor_readings": base_data,  # Only the 5 features used
            "prediction": int(prediction),
            "raw_data": data, 
           "timestamp": {".sv": "timestamp"}

        }
        
        db.reference(f"/processed/{device_id}").push(result)
        print(f" Prediction saved for device {device_id}: {prediction}")
        
    except Exception as e:
        print(f"Error in database trigger: {e}")
        import traceback
        traceback.print_exc()
        # Don't re-raise to avoid function retry loops