import xarray as xr
import pandas as pd

# ==== Hàm chuẩn hóa tên cột ====
def normalize_columns(df):
    if "valid_time" in df.columns:
        df = df.rename(columns={"valid_time": "time"})
    if "lat" in df.columns:
        df = df.rename(columns={"lat": "latitude"})
    if "lon" in df.columns:
        df = df.rename(columns={"lon": "longitude"})
    return df

# ==== Load các file NetCDF ====
df_instant = xr.open_dataset("data_stream-oper_stepType-instant.nc").to_dataframe().reset_index()
df_avg     = xr.open_dataset("data_stream-oper_stepType-avg.nc").to_dataframe().reset_index()
df_accum   = xr.open_dataset("data_stream-oper_stepType-accum.nc").to_dataframe().reset_index()

# ==== Chuẩn hóa cột ====
df_instant = normalize_columns(df_instant)
df_avg     = normalize_columns(df_avg)
df_accum   = normalize_columns(df_accum)

print("Instant columns:", df_instant.columns.tolist())
print("Avg columns:", df_avg.columns.tolist())
print("Accum columns:", df_accum.columns.tolist())

# ==== Merge lần lượt ====
df_temp  = pd.merge(df_instant, df_avg,   on=["time","latitude","longitude"], how="outer")
df_final = pd.merge(df_temp,    df_accum, on=["time","latitude","longitude"], how="outer")

# ==== Xuất CSV để kiểm tra ====
df_final.to_csv("era5_merged.csv", index=False)

print("✅ Hoàn tất! File output: era5_merged.csv")
