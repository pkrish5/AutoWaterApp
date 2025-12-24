# Sims for Plants - Flutter App

A mobile app for monitoring and controlling your IoT plant watering system.

## Features

- **Authentication**: Cognito-based login/signup with email verification
- **Dashboard**: View all your plants in a beautiful grid layout
- **Plant Details**: See water levels, sensor readings, and device status
- **Watering Control**: Manual watering and automated schedules
- **Device Linking**: Connect ESP32 sensors to your plants
- **Schedule Management**: Configure watering days, times, and amounts

## Screens

1. **Login/Signup/Verification** - Cognito authentication flow
2. **Dashboard** - Grid view of all plants with water levels
3. **Add Plant** - Create new plant with optional device linking
4. **Plant Detail** - Water tank level, sensor data, quick actions
5. **Schedule** - Configure automatic watering schedule
6. **Link Device** - Connect ESP32 sensor to a plant

## API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| GET /users/{userId}/plants | List all plants |
| POST /users/{userId}/plants | Add new plant |
| GET /plants/{plantId} | Get plant details |
| DELETE /plants/{plantId} | Delete plant |
| GET /plants/{plantId}/water-level | Get water tank level |
| PUT /plants/{plantId}/water-level | Mark tank as refilled |
| GET /plants/{plantId}/schedule | Get watering schedule |
| PUT /plants/{plantId}/schedule | Update schedule |
| POST /plants/{plantId}/water | Trigger manual watering |

## Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Configuration

Update `lib/core/constants.dart` with your AWS settings:

```dart
class AppConstants {
  static const String baseUrl = "YOUR_API_GATEWAY_URL";
  static const String userPoolId = "YOUR_COGNITO_USER_POOL_ID";
  static const String clientId = "YOUR_COGNITO_CLIENT_ID";
}
```

## Project Structure

```
lib/
├── core/
│   ├── constants.dart    # API and Cognito config
│   └── theme.dart        # App colors and styling
├── models/
│   ├── plant.dart        # Plant data model
│   ├── water_level.dart  # Water tank model
│   └── watering_schedule.dart
├── services/
│   ├── auth_service.dart # Cognito authentication
│   └── api_service.dart  # All API calls
└── ui/
    ├── auth/
    │   ├── login_screen.dart
    │   ├── signup_screen.dart
    │   └── verification_screen.dart
    ├── dashboard/
    │   ├── dashboard_screen.dart
    │   ├── add_plant_screen.dart
    │   └── plant_card.dart
    ├── plant_detail/
    │   ├── plant_detail_screen.dart
    │   ├── schedule_screen.dart
    │   └── link_device_screen.dart
    └── widgets/
        ├── leaf_background.dart
        ├── liquid_gauge.dart
        ├── liquid_gauge_painter.dart
        └── loading_indicator.dart
```

## Device Linking

Plants can be created without a device, but to enable:
- Water level tracking
- Sensor readings (moisture, temperature, humidity, light)
- Manual watering
- Automatic watering schedules

You must link an ESP32 device. The device ID should match the Thing Name configured in AWS IoT Core.

## Dependencies

- provider: State management
- amazon_cognito_identity_dart_2: Cognito authentication
- http: API calls
- google_fonts: Typography
