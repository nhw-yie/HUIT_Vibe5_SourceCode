lib/
│── main.dart                   # Entry point
│── app.dart                    # App khởi tạo MaterialApp / GoRouter
│
├── config/                     # Cấu hình chung
│   ├── theme/                  # AppTheme (light/dark)
│   ├── localization/           # Đa ngôn ngữ
│   └── constants/              # Colors, Sizes, API endpoint base url
│
├── common/                     # Thành phần tái sử dụng
│   ├── widgets/                # Reusable widgets (AppButton, AppTextField…)
│   └── utils/                  # Helpers (format số, format ngày…)
│
├── services/                   # Chỉ gọi API, không chứa logic UI
│   ├── api_service.dart
│   ├── location_service.dart
│   └── map_service.dart
│
├── features/                   # Chia theo tính năng (Feature-based)
│   ├── home/                   # Trang chủ (AQI overview, chọn địa điểm)
│   │   ├── presentation/       # UI
│   │   │   ├── pages/          # HomePage
│   │   │   └── widgets/        # CardAQI, CitySelector
│   │   └── state/              # State management (Bloc/Cubit/Riverpod/Provider)
│   │
│   ├── map/                    # Bản đồ + route ít ô nhiễm
│   │   ├── presentation/       # UI
│   │   │   ├── pages/          # MapPage
│   │   │   └── widgets/        # PollutionMarker, RoutePolyline
│   │   └── state/              # MapBloc, MapState
│   │
│   ├── details/                # Chi tiết AQI
│   │   ├── presentation/       # UI
│   │   │   ├── pages/          # DetailsPage
│   │   │   └── widgets/        # AQIChart, PollutionInfoTile
│   │   └── state/              # DetailsBloc, DetailsState
│   │
│   └── settings/               # Cài đặt
│       ├── presentation/       # UI
│       │   ├── pages/          # SettingsPage
│       │   └── widgets/        # ThemeToggle, LanguageDropdown
│       └── state/              # SettingsBloc, SettingsState
│
└── routes/                     # Điều hướng
    └── app_router.dart
