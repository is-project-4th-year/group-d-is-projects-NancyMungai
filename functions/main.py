import firebase_admin
from firebase_admin import storage
from firebase_functions import https_fn
import joblib
import numpy as np
import tempfile

# Initialize Firebase
firebase_admin.initialize_app(options={
    "storageBucket": "naihydro.firebasestorage.app",
    "databaseURL": "https://naihydro-default-rtdb.europe-west1.firebasedatabase.app/"
})

bucket = storage.bucket()
MODEL_PATH = "models/rf_xgb_ensemble.joblib"

# Download model once on cold start
temp_model = tempfile.NamedTemporaryFile(delete=False)
blob = bucket.blob(MODEL_PATH)
blob.download_to_filename(temp_model.name)
model = joblib.load(temp_model.name)

@https_fn.on_request()
def predict_latest_data(req: https_fn.Request) -> https_fn.Response:
    try:
        body = req.get_json()
        features = np.array(body["features"]).reshape(1, -1)
        prediction = model.predict(features).tolist()
        return https_fn.Response(str(prediction), status=200)
    except Exception as e:
        return https_fn.Response(f"Error: {str(e)}", status=500)
