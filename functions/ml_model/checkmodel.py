"""
Debug script to understand the model pipeline and fix it
"""
import joblib
import tempfile
import os
import numpy as np

temp_model_path = os.path.join(tempfile.gettempdir(), "rf_xgb_ensemble.joblib")
model = joblib.load(temp_model_path)

print("=" * 70)
print("MODEL PIPELINE DIAGNOSIS")
print("=" * 70)

print("\n📦 Model Components:")
for key, value in model.items():
    if hasattr(value, 'n_features_in_'):
        print(f"   {key}: expects {value.n_features_in_} input features")
        if hasattr(value, 'n_components_'):
            print(f"      → outputs {value.n_components_} components")

print("\n" + "=" * 70)
print("TESTING PIPELINE")
print("=" * 70)

# Create test data with 27 features
test_27 = np.random.rand(1, 27)
print(f"\n✅ Created test data: {test_27.shape}")

try:
    # Step 1: Scaler
    if 'scaler' in model:
        scaled = model['scaler'].transform(test_27)
        print(f"✅ After Scaler: {scaled.shape}")
    else:
        scaled = test_27
        print(f"⚠️  No scaler found, using raw features")
    
    # Step 2: PCA
    if 'pca' in model:
        pca_out = model['pca'].transform(scaled)
        print(f"✅ After PCA: {pca_out.shape}")
    else:
        pca_out = scaled
        print(f"⚠️  No PCA found")
    
    # Step 3: Try Random Forest with PCA output
    try:
        print(f"\n🧪 Testing RF with PCA output ({pca_out.shape})...")
        rf_pred_pca = model['rf'].predict(pca_out)
        print(f"✅ RF works with PCA output: {rf_pred_pca}")
    except Exception as e:
        print(f"❌ RF failed with PCA output: {e}")
    
    # Step 4: Try Random Forest with scaled features
    try:
        print(f"\n🧪 Testing RF with scaled features ({scaled.shape})...")
        rf_pred_scaled = model['rf'].predict(scaled)
        print(f"✅ RF works with scaled features: {rf_pred_scaled}")
    except Exception as e:
        print(f"❌ RF failed with scaled features: {e}")
    
    # Step 5: Try XGBoost
    try:
        print(f"\n🧪 Testing XGBoost with PCA output ({pca_out.shape})...")
        xgb_pred_pca = model['xgb'].predict(pca_out)
        print(f"✅ XGBoost works with PCA output: {xgb_pred_pca}")
    except Exception as e:
        print(f"❌ XGBoost failed with PCA output: {e}")
    
    try:
        print(f"\n🧪 Testing XGBoost with scaled features ({scaled.shape})...")
        xgb_pred_scaled = model['xgb'].predict(scaled)
        print(f"✅ XGBoost works with scaled features: {xgb_pred_scaled}")
    except Exception as e:
        print(f"❌ XGBoost failed with scaled features: {e}")

except Exception as e:
    print(f"\n❌ Pipeline test failed: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 70)
print("RECOMMENDATION")
print("=" * 70)
print("\nBased on the test results above, we'll know whether to:")
print("- Use PCA output for predictions, OR")
print("- Use scaled features directly (skip PCA)")