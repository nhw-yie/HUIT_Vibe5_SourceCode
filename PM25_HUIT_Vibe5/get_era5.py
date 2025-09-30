import cdsapi
from datetime import datetime

# ==========================
# ⚙️ INPUT
lat = 10.82   # vĩ độ
lon = 106.62  # kinh độ
# ==========================

# Lấy thời gian hiện tại (UTC)
now = datetime.utcnow()
year = str(now.year)
month = f"{now.month:02d}"   # 2 chữ số
day = f"{now.day:02d}"
hour = f"{now.hour:02d}:00"

print("📅 Thời gian yêu cầu:", year, month, day, hour)
print("📍 Vị trí:", lat, lon)

dataset = "reanalysis-era5-single-levels"
request = {
    "product_type": ["reanalysis"],
    "variable": [
        "10m_u_component_of_wind",
        "10m_v_component_of_wind",
        "2m_dewpoint_temperature",
        "2m_temperature",
        "total_precipitation",
        "mean_total_precipitation_rate",
        "surface_solar_radiation_downwards",
        "boundary_layer_height"
    ],
    "year": [year],
    "month": [month],
    "day": [day],
    "time": [hour],  # chỉ lấy đúng giờ hiện tại
    "data_format": "netcdf",
    "download_format": "unarchived",
    "area": [lat + 0.01, lon - 0.01, lat - 0.01, lon + 0.01]  
    # bbox nhỏ quanh điểm (0.01 độ ≈ 1km)
}

client = cdsapi.Client()
client.retrieve(dataset, request, "era5_now.nc")
