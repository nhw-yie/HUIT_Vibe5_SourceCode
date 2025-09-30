import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import matplotlib.pyplot as plt

def main():
    root_dir = Path(__file__).resolve().parent
    data_dir = root_dir / "data_processed"
    pred_dir = root_dir / "predictions"

    # Load dữ liệu thực tế
    df_real = pd.read_csv(data_dir / "dataset_features_3.csv", parse_dates=["ts_utc"])
    # Load dự đoán
    df_pred = pd.read_csv(pred_dir / "Station3_PM25_predictions.csv", parse_dates=["ts_utc"])

    # Ghép theo ts_utc
    df = df_real.merge(df_pred, on="ts_utc", how="inner")

    # Thực tế và dự đoán
    y_true = df["PM25"].values
    y_pred = df["PM25_pred"].values

    # Tính các chỉ số
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    mae = mean_absolute_error(y_true, y_pred)
    r2 = r2_score(y_true, y_pred)

    print(f"Evaluation results on Station 3:")
    print(f"RMSE = {rmse:.3f}")
    print(f"MAE  = {mae:.3f}")
    print(f"R²   = {r2:.3f}")

    # Vẽ biểu đồ so sánh
    plt.figure(figsize=(10,5))
    plt.plot(df["ts_utc"], y_true, label="PM25 Actual", alpha=0.7)
    plt.plot(df["ts_utc"], y_pred, label="PM25 Predicted", alpha=0.7)
    plt.xlabel("Time")
    plt.ylabel("PM2.5 concentration")
    plt.title("Station 3 - Actual vs Predicted PM2.5")
    plt.legend()
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
