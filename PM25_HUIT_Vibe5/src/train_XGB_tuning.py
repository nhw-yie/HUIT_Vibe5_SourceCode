import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.model_selection import TimeSeriesSplit, RandomizedSearchCV
from sklearn.metrics import make_scorer, mean_squared_error, r2_score
from xgboost import XGBRegressor
import joblib

def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"
    model_dir = root_dir / "models"
    model_dir.mkdir(exist_ok=True)

    # Load dataset
    df = pd.read_csv(data_dir / "dataset_features.csv", parse_dates=["ts_utc"])
    target = "PM25"

    drop_cols = ["ts_local", "ts_utc", "date", "time"]
    X = df.drop(columns=drop_cols + [target]).select_dtypes(include="number")
    y = df[target]

    print("Shape X:", X.shape, "Shape y:", y.shape)

    # RMSE scorer
    rmse_scorer = make_scorer(
        lambda y_true, y_pred: np.sqrt(mean_squared_error(y_true, y_pred)),
        greater_is_better=False
    )

    # Base model
    xgb = XGBRegressor(
        objective="reg:squarederror",
        random_state=42,
        tree_method="gpu_hist",   # dùng GPU
        n_jobs=-1
    )

    # Parameter space (sâu hơn)
    param_dist = {
        "n_estimators": [400, 600, 800, 1000, 1200],
        "learning_rate": [0.01, 0.05, 0.1, 0.2],
        "max_depth": [3, 4, 5, 6, 8],
        "min_child_weight": [1, 3, 5, 7],
        "subsample": [0.6, 0.8, 1.0],
        "colsample_bytree": [0.6, 0.8, 1.0],
        "gamma": [0, 0.1, 0.3, 0.5],
        "reg_alpha": [0, 0.01, 0.1],
        "reg_lambda": [1, 1.5, 2]
    }

    # TimeSeriesSplit
    tscv = TimeSeriesSplit(n_splits=5)

    # Randomized search (50 tổ hợp)
    random_search = RandomizedSearchCV(
        estimator=xgb,
        param_distributions=param_dist,
        n_iter=50,
        scoring=rmse_scorer,
        cv=tscv,
        verbose=2,
        random_state=42,
        n_jobs=-1
    )

    random_search.fit(X, y)

    print("\nBest parameters:", random_search.best_params_)
    print("Best RMSE (CV):", -random_search.best_score_)

    # Train final model với best params
    best_params = random_search.best_params_
    final_model = XGBRegressor(
        **best_params,
        objective="reg:squarederror",
        random_state=42,
        tree_method="gpu_hist",
        n_jobs=-1
    )
    final_model.fit(X, y)

    # Save model
    model_path = model_dir / "xgb_model_tuned.pkl"
    joblib.dump(final_model, model_path)
    print(f"\nSaved tuned XGB model to: {model_path}")

if __name__ == "__main__":
    main()
