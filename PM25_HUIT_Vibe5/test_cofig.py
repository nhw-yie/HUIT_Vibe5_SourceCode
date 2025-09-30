import cdsapi

c = cdsapi.Client()

c.retrieve(
    "reanalysis-era5-single-levels",
    {
        "product_type": "reanalysis",
        "variable": "2m_temperature",
        "year": "2022",
        "month": "01",
        "day": "01",
        "time": "12:00",
        "format": "netcdf",
    },
    "era5_test.nc"
)
