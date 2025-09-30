# evaluate_model.py
import pandas as pd
from pathlib import Path
import joblib
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import matplotlib.pyplot as plt

def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"
    model_dir = root_dir / "models"

    # Load dataset (same as used in training)
    df = pd.read_csv(data_dir / "dataset_features.csv", parse_dates=['ts_utc'])
    target = "PM25"
    drop_cols = ["ts_local", "ts_utc", "date", "time"]
    features = df.drop(columns=drop_cols + [target])
    X = features.select_dtypes(include='number')
    y = df[target]

    # Train/test split (same logic as training)
    split_idx = int(len(X) * 0.8)
    X_train, X_test = X[:split_idx], X[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]

    # Load trained model
    model_path = model_dir / "baseline_model.pkl"
    model = joblib.load(model_path)
    y_pred = model.predict(X_test)

    # Metrics
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    mbe = np.mean(y_pred - y_test)

    print("Evaluation on test set:")
    print(f"RMSE: {rmse:.3f}")
    print(f"MAE: {mae:.3f}")
    print(f"R²: {r2:.3f}")
    print(f"MBE: {mbe:.3f}")

    # Scatter plot: Observed vs Predicted
    plt.figure(figsize=(6,6))
    plt.scatter(y_test, y_pred, alpha=0.5)
    plt.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'r--')
    plt.xlabel("Observed PM2.5")
    plt.ylabel("Predicted PM2.5")
    plt.title("Observed vs Predicted PM2.5")
    plt.grid(True)
    plt.tight_layout()
    plt.show()

    # Time series plot
    plt.figure(figsize=(12,4))
    plt.plot(y_test.values, label="Observed")
    plt.plot(y_pred, label="Predicted", alpha=0.7)
    plt.xlabel("Sample index")
    plt.ylabel("PM2.5")
    plt.title("Time series: Observed vs Predicted")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()

    # Residuals histogram
    residuals = y_pred - y_test
    plt.figure(figsize=(6,4))
    plt.hist(residuals, bins=30)
    plt.xlabel("Residual (Predicted - Observed)")
    plt.ylabel("Count")
    plt.title("Residual distribution")
    plt.grid(True)
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
