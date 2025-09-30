import ee

# Khởi tạo GEE
ee.Initialize(project='apt-rope-461419-e3')

def extract_modis_aod(lat, lon, start_date, end_date, buffer_km=10):
    """
    Extract MODIS MAIAC AOD (MCD19A2) around a station.
    Sửa lỗi null hoàn toàn, an toàn với Python GEE.
    """
    station_point = ee.Geometry.Point([lon, lat])
    buffer_area = station_point.buffer(buffer_km * 1000)

    # MODIS MAIAC AOD collection
    collection = ee.ImageCollection('MODIS/061/MCD19A2_GRANULES') \
        .filterDate(start_date, end_date) \
        .filterBounds(buffer_area) \
        .select(['Optical_Depth_047', 'Optical_Depth_055'])

    n_images = collection.size().getInfo()
    print(f"Found {n_images} images in collection.")
    if n_images == 0:
        print("No images found! Check dates and location.")
        return None

    def extract_aod_safe(image):
        aod_055 = image.select('Optical_Depth_055').multiply(0.001)

        # Đếm pixel hợp lệ
        pixel_count = aod_055.reduceRegion(
            reducer=ee.Reducer.count(),
            geometry=buffer_area,
            scale=1000,
            maxPixels=1e9
        ).get('Optical_Depth_055')

        # Tạo feature ngay cả khi pixel_count = 0
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
            'pixel_count': ee.Number(pixel_count) if pixel_count else 0
        })
        return feature

    # Map và tạo FeatureCollection
    features = collection.map(extract_aod_safe)
    aod_fc = ee.FeatureCollection(features)

    # Lọc feature có aod_055_mean hợp lệ
    aod_fc = aod_fc.filter(ee.Filter.notNull(['aod_055_mean']))

    return aod_fc


# Thông số trạm thứ 2
STATION_LAT = 10.74097081
STATION_LON = 106.6171323
START_DATE = '2021-02-23'
END_DATE   = '2022-06-23'

# Lấy dữ liệu AOD hợp lệ
aod_fc = extract_modis_aod(STATION_LAT, STATION_LON, START_DATE, END_DATE)

# Kiểm tra và export CSV
if aod_fc.size().getInfo() > 0:
    task = ee.batch.Export.table.toDrive(
        collection=aod_fc,
        description='MODIS_2',
        folder='Earth_Engine_Exports',
        fileFormat='CSV'
    )
    task.start()
    print("Export task started. Kiểm tra Google Drive sau vài phút.")
else:
    print("Không có dữ liệu hợp lệ để export.")
