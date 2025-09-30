import pandas as pd
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
import numpy as np
import joblib


def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"
    model_dir = root_dir / "models"
    model_dir.mkdir(exist_ok=True)

    # Load feature dataset
    df = pd.read_csv(data_dir / "dataset_features.csv", parse_dates=['ts_utc'])

    # Target
    target = "PM25"

    # Drop các cột datetime / text không cần thiết
    drop_cols = ["ts_local", "ts_utc", "date", "time"]
    features = df.drop(columns=drop_cols + [target])

    # Chỉ giữ cột numeric
    X = features.select_dtypes(include='number')
    y = df[target]

    # Xử lý NaN bằng median
    imputer = SimpleImputer(strategy="median")
    X = pd.DataFrame(imputer.fit_transform(X), columns=X.columns)

    print(" Features used for training:", X.columns.tolist())
    print("Shape X:", X.shape, "Shape y:", y.shape)

    # Train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, shuffle=False
    )

    # Random Forest
    rf = RandomForestRegressor(
        n_estimators=100, random_state=42, n_jobs=-1
    )
    rf.fit(X_train, y_train)
    y_pred_rf = rf.predict(X_test)

    rmse_rf = np.sqrt(mean_squared_error(y_test, y_pred_rf))
    r2_rf = r2_score(y_test, y_pred_rf)

    print("\n Random Forest:")
    print("RMSE:", rmse_rf)
    print("R²:", r2_rf)

    # Save model
    joblib.dump(rf, model_dir / "rf_model.pkl")
    print("\n Saved model to:", model_dir / "rf_model.pkl")


if __name__ == "__main__":
    main()
