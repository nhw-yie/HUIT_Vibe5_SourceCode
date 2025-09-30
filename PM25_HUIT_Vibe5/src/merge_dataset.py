import pandas as pd
from pathlib import Path


def main():
    root_dir = Path(__file__).resolve().parent.parent
    data_dir = root_dir / "data_processed"
    out_file = data_dir / "merged_dataset.csv"

    # Load processed data
    station = pd.read_csv(data_dir / "station_clean.csv", parse_dates=['ts_utc'])
    era5 = pd.read_csv(data_dir / "era5_clean.csv", parse_dates=['time'])
    modis = pd.read_csv(data_dir / "modis_clean.csv", parse_dates=['date'])

    # ---- Merge ERA5 vào station (hourly) ----
    merged = pd.merge_asof(
        station.sort_values("ts_utc"),
        era5.sort_values("time"),
        left_on="ts_utc",
        right_on="time",
        direction="backward",
        tolerance=pd.Timedelta("1h")
    )

    # ---- Merge MODIS (daily) ----
    merged['date'] = merged['ts_utc'].dt.date.astype('datetime64[ns]')
    merged = pd.merge(
        merged,
        modis[['date', 'aod_mean', 'pixel_count']],
        on="date",
        how="left"
    )

    # ---- Xuất file ----
    merged.to_csv(out_file, index=False)
    print("Saved merged dataset:", out_file)


if __name__ == "__main__":
    main()
