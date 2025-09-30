import requests
from datetime import datetime

# Tọa độ
lat, lon = 10.82, 106.62

# Ngày giờ UTC hiện tại (lùi 6h để chắc chắn GFS đã có dữ liệu)
now = datetime.utcnow()
date = now.strftime("%Y%m%d")
run = "00"  # có thể đổi thành "06", "12", "18"
forecast_hour = "000"

# URL NOAA NOMADS
url = (
    f"https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p25.pl?"
    f"file=gfs.t{run}z.pgrb2.0p25.f{forecast_hour}&"
    f"lev_2_m_above_ground=on&"
    f"var_TMP=on&"
    f"subregion=&leftlon={lon-0.25}&rightlon={lon+0.25}&"
    f"toplat={lat+0.25}&bottomlat={lat-0.25}&"
    f"dir=%2Fgfs.{date}%2F{run}%2Fatmos"
)

print("📥 Downloading:", url)
r = requests.get(url)

with open("gfs_tmp2m.grib2", "wb") as f:
    f.write(r.content)

print("✅ GFS data saved as gfs_tmp2m.grib2")
