import cdsapi
from datetime import datetime, timedelta

# Vị trí test
LAT, LON = 10.86994333, 106.7960143

area = [11.25, 106.375, 10.5, 107.125]  # [North, West, South, East]

date_request = '2025-09-25'  # thử ngày cũ hơn
time_request = ['12:00']  # timestep cố định


c = cdsapi.Client(url='https://ads.atmosphere.copernicus.eu/api', key='da377f6c-c7b8-4134-a3e2-c2b93172bd51')

try:
    c.retrieve(
        'cams-global-atmospheric-composition-forecasts',
        {
            'variable': ['aerosol_optical_depth_550nm'],
            'date': date_request,
            'time': ['12:00'],  # chọn 1 timestep để test
            'area': area,
            'format': 'netcdf',
        },
        'cams_aod.nc'
    )
    print("✅ Download thành công!")
except Exception as e:
    print("❌ Cannot download CAMS:", e)
