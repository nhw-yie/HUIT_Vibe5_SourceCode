import pandas as pd
import numpy as np
from pathlib import Path
import joblib
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import mean_squared_error, r2_score
from xgboost import XGBRegressor


def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"
    model_dir = root_dir / "models"
    model_dir.mkdir(exist_ok=True)

    # Load dataset
    df = pd.read_csv(data_dir / "dataset_features.csv", parse_dates=['ts_utc'])
    target = "PM25"

    # Các cột bỏ đi
    drop_cols = ["ts_local", "ts_utc", "date", "time", target]

    # Các cột lag/rolling bỏ hết
    lag_roll_cols = [c for c in df.columns if "lag" in c or "roll" in c]

    # Loại bỏ pollutants (chỉ giữ lại ERA5, AOD, …)
    pollutants = ["TSP", "O3", "CO", "NO2", "SO2"]

    # Chọn features
    X = df.drop(columns=drop_cols + pollutants + lag_roll_cols, errors="ignore").select_dtypes(include='number')
    y = df[target]

    print("Features used (no lag/rolling):", X.columns.tolist())
    print("Shape X:", X.shape, "Shape y:", y.shape)

    # Time series split
    tscv = TimeSeriesSplit(n_splits=5)
    rmses, r2s = [], []

    for fold, (train_idx, test_idx) in enumerate(tscv.split(X), 1):
        X_train, X_test = X.iloc[train_idx], X.iloc[test_idx]
        y_train, y_test = y.iloc[train_idx], y.iloc[test_idx]

        model = XGBRegressor(
            n_estimators=200,
            learning_rate=0.1,
            max_depth=4,
            random_state=42,
            n_jobs=-1
        )

        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)

        rmse = np.sqrt(mean_squared_error(y_test, y_pred))
        r2 = r2_score(y_test, y_pred)

        print(f"Fold {fold}: RMSE = {rmse:.3f}, R² = {r2:.3f}")

        rmses.append(rmse)
        r2s.append(r2)

    print("\nEvaluation across folds (without lag/rolling):")
    print("Mean RMSE:", np.mean(rmses))
    print("Mean R²:", np.mean(r2s))

    # Train final model trên toàn bộ data
    final_model = XGBRegressor(
        n_estimators=200,
        learning_rate=0.1,
        max_depth=4,
        random_state=42,
        n_jobs=-1
    )
    final_model.fit(X, y)

    joblib.dump(final_model, model_dir / "xgb_model_no_lag_roll.pkl")
    print("\nSaved final model to:", model_dir / "xgb_model_no_lag_roll.pkl")


if __name__ == "__main__":
    main()
