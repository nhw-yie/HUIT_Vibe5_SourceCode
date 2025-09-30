import pandas as pd
import numpy as np
from pathlib import Path


# --------- Utils ---------
def rh_from_t_td(T_C, Td_C):
    """Tính relative humidity (%) từ T, Td (°C)."""
    a, b = 17.625, 243.04
    es_T = 6.112 * np.exp(a * T_C / (b + T_C))
    e_Td = 6.112 * np.exp(a * Td_C / (b + Td_C))
    return 100.0 * (e_Td / es_T)


# --------- Load & chuẩn hóa ---------
def load_station(path):
    df = pd.read_csv(path, parse_dates=['date'], dayfirst=True)

    df['ts_local'] = pd.to_datetime(df['date'], dayfirst=True)
    df['ts_local'] = df['ts_local'].dt.tz_localize('Asia/Ho_Chi_Minh')
    df['ts_utc'] = df['ts_local'].dt.tz_convert('UTC')

    df = df.rename(columns={
        'PM2.5': 'PM25',
        'Temperature': 'T_obs',
        'Humidity': 'RH_obs'
    })
    return df


def load_era5(path):
    df = pd.read_csv(path, parse_dates=['time'])
    df['time'] = pd.to_datetime(df['time']).dt.tz_localize('UTC')
    return df


def load_modis(path):
    df = pd.read_csv(path, parse_dates=['date'])
    df['date'] = pd.to_datetime(df['date']).dt.date
    df['aod_mean'] = pd.to_numeric(df['aod_055_mean'], errors='coerce')
    df['pixel_count'] = pd.to_numeric(df['pixel_count'], errors='coerce')
    df.loc[df['pixel_count'] < 5, 'aod_mean'] = np.nan
    return df


# --------- ERA5 tiền xử lý ---------
def preprocess_era5(df):
    df['t2m_C'] = df['t2m'] - 273.15
    df['d2m_C'] = df['d2m'] - 273.15
    df['RH'] = rh_from_t_td(df['t2m_C'], df['d2m_C'])
    df['ws'] = np.sqrt(df['u10']**2 + df['v10']**2)
    df['wd'] = (np.degrees(np.arctan2(-df['u10'], -df['v10'])) + 360) % 360
    df['blh'] = pd.to_numeric(df['blh'], errors='coerce')
    if df['ssrd'].max() > 1e4:  # nếu là tích lũy
        df['ssrd_hourly'] = df['ssrd'].diff().clip(lower=0)
    else:
        df['ssrd_hourly'] = df['ssrd']
    return df


# --------- Tạo lag, rolling ---------
def add_lags_rollings(df):
    for lag in [1, 3, 6, 12, 24]:
        df[f'PM25_lag{lag}'] = df['PM25'].shift(lag)
        df[f'aod_mean_lag{lag}'] = df['aod_mean'].shift(lag)

    for window in [3, 6, 12, 24]:
        df[f'PM25_roll{window}'] = df['PM25'].rolling(window).mean()
        df[f'aod_mean_roll{window}'] = df['aod_mean'].rolling(window).mean()

    return df


# --------- Tạo feature thời gian ---------
def add_time_features(df):
    df['hour'] = df['ts_utc'].dt.hour
    df['month'] = df['ts_utc'].dt.month
    df['dayofweek'] = df['ts_utc'].dt.dayofweek

    df['hour_sin'] = np.sin(2 * np.pi * df['hour'] / 24)
    df['hour_cos'] = np.cos(2 * np.pi * df['hour'] / 24)
    df['month_sin'] = np.sin(2 * np.pi * df['month'] / 12)
    df['month_cos'] = np.cos(2 * np.pi * df['month'] / 12)
    df['dayofweek_sin'] = np.sin(2 * np.pi * df['dayofweek'] / 7)
    df['dayofweek_cos'] = np.cos(2 * np.pi * df['dayofweek'] / 7)

    return df


# --------- Main pipeline ---------
def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_raw"
    out_dir = root_dir / "data_processed"
    out_dir.mkdir(exist_ok=True)

    # Load
    station = load_station(data_dir / "station.csv")
    era5 = load_era5(data_dir / "era5.csv")
    modis = load_modis(data_dir / "modis.csv")

    # Preprocess ERA5
    era5 = preprocess_era5(era5)

    # Merge datasets
    df = station.merge(era5, left_on='ts_utc', right_on='time', how='left')
    df = df.merge(modis, left_on=df['ts_utc'].dt.date, right_on='date', how='left')

    # Lags, rolling, time features
    df = add_lags_rollings(df)
    df = add_time_features(df)

    # Save final features
    df.to_csv(out_dir / "dataset_features.csv", index=False)
    print("Saved final feature dataset to:", out_dir / "dataset_features.csv")


if __name__ == "__main__":
    main()
