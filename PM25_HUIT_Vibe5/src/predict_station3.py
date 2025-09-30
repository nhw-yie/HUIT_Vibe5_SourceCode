import pandas as pd
import joblib
from pathlib import Path
import numpy as np

def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"
    model_dir = root_dir / "models"
    out_dir = root_dir / "predictions"
    out_dir.mkdir(exist_ok=True)

    # Load dataset trạm 3
    df = pd.read_csv(data_dir / "dataset_features_3.csv", parse_dates=['ts_utc'])

    # Load model đã train (trạm 1 hoặc nhiều trạm)
    model_path = model_dir / "xgb_model_full.pkl"
    model = joblib.load(model_path)

    # Lấy feature mà model cần
    model_features = model.get_booster().feature_names
    missing_cols = [c for c in model_features if c not in df.columns]
    if missing_cols:
        print("Warning: missing columns, fill with 0:", missing_cols)
        for c in missing_cols:
            df[c] = 0.0

    # Chỉ giữ các cột numeric mà model cần
    X = df[model_features].select_dtypes(include='number')

    # Fill NaN để tránh lỗi XGB
    X = X.fillna(0.0)

    # Dự đoán
    df['PM25_pred'] = model.predict(X)

    # Lưu kết quả
    out_file = out_dir / "Station3_PM25_predictions.csv"
    cols_to_save = ['ts_utc', 'PM25_pred']
    if 'latitude' in df.columns and 'longitude' in df.columns:
        cols_to_save = ['ts_utc', 'latitude', 'longitude', 'PM25_pred']

    df[cols_to_save].to_csv(out_file, index=False)
    print("Saved predictions to:", out_file)

if __name__ == "__main__":
    main()
