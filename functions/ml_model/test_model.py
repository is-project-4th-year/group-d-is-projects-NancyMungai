"""
Test with actual Firebase data format
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

def test_with_real_firebase_data():
    """Test with the actual Firebase data structure"""
    print("=" * 70)
    print("TESTING WITH REAL FIREBASE DATA FORMAT")
    print("=" * 70)
    
    try:
        from main import load_model, make_prediction, engineer_features
        import numpy as np
        
        # Your actual Firebase data
        firebase_data = {
            "DHT_humidity": 500,
            "DHT_temp": 20,
            "TDS": 1000,
            "deviceId": "esp32-001",
            "pH": 11.8,
            "pump_state": 0,
            "relay_state": 1,
            "tds_raw": 1000,
            "timestamp": 5138,
            "water_level": 1
        }
        
        print(f"\n📥 Raw Firebase data:")
        for key, value in firebase_data.items():
            print(f"   {key}: {value}")
        
        # Extract only the required features
        base_feature_names = ['pH', 'TDS', 'water_level', 'DHT_temp', 'DHT_humidity']
        base_data = {}
        
        for feat in base_feature_names:
            if feat in firebase_data:
                base_data[feat] = float(firebase_data[feat])
            else:
                print(f"⚠️  Missing: {feat}")
                base_data[feat] = 0.0
        
        print(f"\n📊 Extracted base features:")
        for key, value in base_data.items():
            print(f"   {key}: {value}")
        
        # Load model
        print(f"\n🔧 Loading model...")
        model = load_model()
        
        # Engineer features
        print(f"\n🔧 Engineering features...")
        engineered = engineer_features(base_data, model.get('training_stats', {}))
        
        print(f"\n✨ Sample engineered features:")
        print(f"   pH_zscore: {engineered['pH_zscore']:.3f}")
        print(f"   TDS_percentile: {engineered['TDS_percentile']:.1f}")
        print(f"   water_level_median_dist: {engineered['water_level_median_dist']:.3f}")
        print(f"   total_zscore: {engineered['total_zscore']:.3f}")
        
        # Create feature array
        feature_cols = model['feature_cols']
        features = np.array([[engineered[col] for col in feature_cols]])
        
        print(f"\n📐 Feature array shape: {features.shape}")
        
        # Make prediction
        print(f"\n🔮 Making prediction...")
        prediction = make_prediction(features, model)
        
        print(f"\n" + "=" * 70)
        print(f"✅ PREDICTION SUCCESSFUL!")
        print(f"=" * 70)
        print(f"\n   Input pH: {base_data['pH']}")
        print(f"   Input TDS: {base_data['TDS']}")
        print(f"   Input water_level: {base_data['water_level']}")
        print(f"   Input DHT_temp: {base_data['DHT_temp']}")
        print(f"   Input DHT_humidity: {base_data['DHT_humidity']}")
        print(f"\n   → Prediction: {prediction}")
        print(f"   → Prediction type: {type(prediction).__name__}")
        
        # Interpret prediction
        if prediction == 0:
            status = "NORMAL ✅"
        elif prediction == 1:
            status = "ANOMALY ⚠️"
        else:
            status = f"UNKNOWN ({prediction})"
        
        print(f"\n   Water Quality Status: {status}")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_with_real_firebase_data()
    
    if success:
        print("\n🎉 Ready to deploy! Your function will work with real Firebase data.")
    else:
        print("\n⚠️  Fix the errors above before deploying.")
    
    sys.exit(0 if success else 1)