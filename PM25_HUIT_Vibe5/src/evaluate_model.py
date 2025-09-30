# src/evaluate_model.py
import pandas as pd
from pathlib import Path
import joblib
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import matplotlib.pyplot as plt

def main():
    # --- Paths ---
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"
    model_dir = root_dir / "models"

    # --- Load dataset ---
    df = pd.read_csv(data_dir / "dataset_features.csv", parse_dates=['ts_utc'])

    target = "PM25"

    # --- Prepare features ---
    drop_cols = ["ts_local", "ts_utc", "date", "time"]
    features = df.drop(columns=drop_cols + [target])
    X = features.select_dtypes(include='number')
    y = df[target]

    # --- Split train/test (same as train_model.py) ---
    split_index = int(len(X) * 0.8)
    X_test = X.iloc[split_index:]
    y_test = y.iloc[split_index:]

    # --- Load trained model ---
    model = joblib.load(model_dir / "baseline_model.pkl")
    y_pred = model.predict(X_test)

    # --- Metrics ---
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    mbe = np.mean(y_pred - y_test)  # Mean Bias Error

    print("Evaluation on test set:")
    print(f"RMSE: {rmse:.3f}")
    print(f"MAE: {mae:.3f}")
    print(f"R²: {r2:.3f}")
    print(f"MBE: {mbe:.3f}")

    # --- Plot predicted vs observed ---
    plt.figure(figsize=(6,6))
    plt.scatter(y_test, y_pred, alpha=0.5)
    plt.plot([y_test.min(), y_test.max()],
             [y_test.min(), y_test.max()],
             'r--', lw=2)
    plt.xlabel("Observed PM2.5")
    plt.ylabel("Predicted PM2.5")
    plt.title("Predicted vs Observed PM2.5")
    plt.grid(True)
    plt.tight_layout()
    plt.show()

    # --- Optional: residuals over time ---
    if 'ts_utc' in df.columns:
        ts_test = df['ts_utc'].iloc[split_index:]
        residuals = y_test - y_pred
        plt.figure(figsize=(10,4))
        plt.plot(ts_test, residuals, label="Residuals")
        plt.axhline(0, color='r', linestyle='--')
        plt.xlabel("Time")
        plt.ylabel("Residual PM2.5")
        plt.title("Residuals over time")
        plt.grid(True)
        plt.tight_layout()
        plt.show()

if __name__ == "__main__":
    main()
