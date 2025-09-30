# train_model_improved.py
import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import joblib
import matplotlib.pyplot as plt
from xgboost import XGBRegressor

# ---------------- Helper functions ----------------
def mbe(y_true, y_pred):
    """Mean Bias Error"""
    return np.mean(y_pred - y_true)

def add_features(df):
    """Add lag, rolling, time-based, wind features"""
    # Time features
    df['hour'] = df['ts_utc'].dt.hour
    df['month'] = df['ts_utc'].dt.month
    df['dayofweek'] = df['ts_utc'].dt.dayofweek

    # Lag features
    for lag in [1,3,6,12,24]:
        df[f'PM25_lag{lag}'] = df['PM25'].shift(lag)
        df[f'aod_mean_lag{lag}'] = df['aod_mean'].shift(lag)

    # Rolling mean features
    for window in [3,6,12,24]:
        df[f'PM25_roll{window}'] = df['PM25'].rolling(window).mean()
        df[f'aod_mean_roll{window}'] = df['aod_mean'].rolling(window).mean()

    # Wind direction sin/cos
    df['wd_sin'] = np.sin(np.radians(df['wd']))
    df['wd_cos'] = np.cos(np.radians(df['wd']))

    # Drop rows with NaN (from lag/rolling)
    df = df.dropna()
    return df

# ---------------- Main ----------------
def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"
    model_dir = root_dir / "models"
    model_dir.mkdir(exist_ok=True)

    # Load dataset
    df = pd.read_csv(data_dir / "dataset_features.csv", parse_dates=['ts_utc'])
    df = add_features(df)

    target = 'PM25'

    # Drop columns not needed
    drop_cols = ['ts_local', 'ts_utc', 'date', 'time']
    features = df.drop(columns=drop_cols + [target])

    # Keep only numeric features
    X = features.select_dtypes(include='number')
    y = df[target]

    print("Features used:", X.columns.tolist())
    print("Shape X:", X.shape, "Shape y:", y.shape)

    # Time-based train/test split
    split_idx = int(len(df)*0.8)
    X_train, X_test = X.iloc[:split_idx], X.iloc[split_idx:]
    y_train, y_test = y.iloc[:split_idx], y.iloc[split_idx:]

    # Train XGBoost
    xgb = XGBRegressor(
        n_estimators=500,
        max_depth=6,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        n_jobs=-1
    )
    xgb.fit(X_train, y_train)
    y_pred = xgb.predict(X_test)

    # Evaluation
    rmse_val = np.sqrt(mean_squared_error(y_test, y_pred))
    mae_val = mean_absolute_error(y_test, y_pred)
    r2_val = r2_score(y_test, y_pred)
    mbe_val = mbe(y_test.values, y_pred)

    print("\nEvaluation on test set:")
    print(f"RMSE: {rmse_val:.3f}")
    print(f"MAE: {mae_val:.3f}")
    print(f"R²: {r2_val:.3f}")
    print(f"MBE: {mbe_val:.3f}")

    # Plot Observed vs Predicted
    plt.figure(figsize=(8,6))
    plt.scatter(y_test, y_pred, alpha=0.5)
    plt.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'r--')
    plt.xlabel('Observed PM2.5')
    plt.ylabel('Predicted PM2.5')
    plt.title('Observed vs Predicted')
    plt.show()

    # Residuals plot
    plt.figure(figsize=(8,6))
    residuals = y_test - y_pred
    plt.scatter(y_pred, residuals, alpha=0.5)
    plt.axhline(0, color='r', linestyle='--')
    plt.xlabel('Predicted PM2.5')
    plt.ylabel('Residuals')
    plt.title('Residuals Plot')
    plt.show()

    # Save model
    joblib.dump(xgb, model_dir / "xgb_model.pkl")
    print("\nSaved model to:", model_dir / "xgb_model.pkl")

if __name__ == "__main__":
    main()
