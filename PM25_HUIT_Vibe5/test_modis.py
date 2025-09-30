import ee
import pandas as pd

ee.Initialize(project='apt-rope-461419-e3')

def extract_modis_aod(lat, lon, start_date, end_date, buffer_km=10):
    station_point = ee.Geometry.Point([lon, lat])
    buffer_area = station_point.buffer(buffer_km * 1000)

    collection = ee.ImageCollection('MODIS/061/MCD19A2_GRANULES') \
        .filterDate(start_date, end_date) \
        .filterBounds(buffer_area) \
        .select(['Optical_Depth_047', 'Optical_Depth_055'])

    n_images = collection.size().getInfo()
    print(f"Found {n_images} images in collection.")
    if n_images == 0:
        return None

    def extract_aod_safe(image):
        aod_055 = image.select('Optical_Depth_055').multiply(0.001)
        pixel_count = aod_055.reduceRegion(
            reducer=ee.Reducer.count(),
            geometry=buffer_area,
            scale=1000,
            maxPixels=1e9
        ).get('Optical_Depth_055')

        feature = ee.Feature(None, {
            'date': image.date().format('YYYY-MM-dd'),
            'aod_055_point': ee.Algorithms.If(pixel_count, aod_055.reduceRegion(
                reducer=ee.Reducer.first(),
                geometry=station_point,
                scale=1000
            ).get('Optical_Depth_055'), None),
            'aod_055_mean': ee.Algorithms.If(pixel_count, aod_055.reduceRegion(
                reducer=ee.Reducer.mean(),
                geometry=buffer_area,
                scale=1000
            ).get('Optical_Depth_055'), None),
            'aod_055_median': ee.Algorithms.If(pixel_count, aod_055.reduceRegion(
                reducer=ee.Reducer.median(),
                geometry=buffer_area,
                scale=1000
            ).get('Optical_Depth_055'), None),
            'pixel_count': ee.Number(pixel_count).int()
        })
        return feature

    features = collection.map(extract_aod_safe)
    aod_fc = ee.FeatureCollection(features).filter(ee.Filter.notNull(['aod_055_mean']))

    return aod_fc


# Thông số
STATION_LAT = 10.74097081
STATION_LON = 106.6171323
START_DATE = '2021-02-23'
END_DATE   = '2022-06-23'

aod_fc = extract_modis_aod(STATION_LAT, STATION_LON, START_DATE, END_DATE)

if aod_fc and aod_fc.size().getInfo() > 0:
    # Lấy dữ liệu về local
    data = aod_fc.getInfo()   # <-- tải JSON từ EE về local
    rows = []
    for f in data['features']:
        props = f['properties']
        rows.append(props)

    df = pd.DataFrame(rows)
    df.to_csv("MODIS_AOD_local.csv", index=False, encoding="utf-8")
    df = pd.read_csv("MODIS_AOD_local.csv")
    df["system:index"] = None
    df[".geo"] = None
    cols = ["system:index","aod_055_mean","aod_055_median","aod_055_point","date","pixel_count",".geo"]
    df = df[cols]

    df.to_csv("MODIS_AOD_local_compatible.csv", index=False)
    print("Đã lưu MODIS_AOD_local.csv vào thư mục hiện tại.")
else:
    print("Không có dữ liệu hợp lệ để lưu.")


