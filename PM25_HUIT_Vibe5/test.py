import pandas as pd

# đọc file bạn đã export
df = pd.read_csv("pm25_diff_by_time.csv", parse_dates=["date"])

# chỉ lấy 6 trạm
stations = ["1","2","3","4","5","6"]

# thống kê mô tả
summary = df[stations].describe().T   # .T để xoay bảng
print(summary)

# xuất ra file
summary.to_csv("pm25_station_summary.csv")
