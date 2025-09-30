import pandas as pd
from pathlib import Path


def add_time_features(df: pd.DataFrame) -> pd.DataFrame:
    """Thêm đặc trưng về thời gian"""
    df['hour'] = df['ts_utc'].dt.hour
    df['month'] = df['ts_utc'].dt.month
    df['dayofweek'] = df['ts_utc'].dt.dayofweek
    return df


def add_lag_features(df: pd.DataFrame, cols, lags=[1, 3, 6]) -> pd.DataFrame:
    """Thêm feature trễ (lag)"""
    for col in cols:
        for lag in lags:
            df[f"{col}_lag{lag}"] = df[col].shift(lag)
    return df


def add_rolling_features(df: pd.DataFrame, cols, windows=[3, 6, 12]) -> pd.DataFrame:
    """Thêm feature trung bình trượt"""
    for col in cols:
        for w in windows:
            df[f"{col}_roll{w}"] = df[col].rolling(window=w).mean()
    return df


def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"

    # Load merged dataset
    df = pd.read_csv(data_dir / "merged_dataset.csv", parse_dates=['ts_utc'])

    # Add features
    df = add_time_features(df)

    df = add_lag_features(df, cols=["PM25", "aod_mean"], lags=[1, 3, 6])
    df = add_rolling_features(df, cols=["PM25", "aod_mean"], windows=[3, 6, 12])

    # Drop NA sinh ra do lag/rolling
    df = df.dropna().reset_index(drop=True)

    # Save
    out_file = data_dir / "dataset_features.csv"
    df.to_csv(out_file, index=False)
    print("Saved feature dataset:", out_file)


if __name__ == "__main__":
    main()
