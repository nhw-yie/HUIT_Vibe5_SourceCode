import pandas as pd
import glob
import os

# Thư mục chứa các file CSV
folder = r"D:\IUT_BangA\PM25_HUIT_Vibe5"   # đổi thành thư mục của bạn

# Tìm tất cả các file CSV
csv_files = sorted(glob.glob(os.path.join(folder, "era5_merged_*.csv")))

print("Found files:", csv_files)

# Đọc và gộp
df_list = [pd.read_csv(file) for file in csv_files]
df_merged = pd.concat(df_list, ignore_index=True)

# Chuyển cột time sang dạng datetime
df_merged["time"] = pd.to_datetime(df_merged["time"])

# Sắp xếp theo thời gian tăng dần
df_merged = df_merged.sort_values(by="time").reset_index(drop=True)

# Xuất ra file mới
output_path = os.path.join(folder, "era5_merged_all_sorted.csv")
df_merged.to_csv(output_path, index=False)

print("Merged & sorted file saved at:", output_path)
