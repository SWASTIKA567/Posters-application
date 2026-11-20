# 🛍️ Kechi Mobile App — Flutter Client

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Architecture-GetX%20MVC-8A2BE2?style=for-the-badge" alt="GetX" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Platforms" />
  <img src="https://img.shields.io/badge/Payments-Razorpay%20SDK-0C2340?style=for-the-badge&logo=razorpay&logoColor=white" alt="Razorpay" />
</p>

<p align="center">
  <b>A responsive, high-performance mobile application engineered with Flutter and GetX.</b><br />
  Featuring custom image upload & formatting for print-on-demand orders, dynamic A3/A4/A5 pricing calculations, interactive category browsing, full-screen zoomable poster inspections, Razorpay checkout, live order tracking, and an integrated Admin Operations Suite.
</p>

---

## 📱 App Highlights

- ⚡ **Reactive State Management with GetX**: Ultra-low latency UI updates with modular controllers, centralized route bindings, and reactive dependencies.
- 🎨 **Custom Print-on-Demand Studio**: Direct camera & gallery photo picker with size selector (A5, A4, A3), dynamic quantity modifiers, and automatic bulk free-delivery rules.
- 💳 **Razorpay & COD Checkout**: Integrated native payment sheets supporting UPI (GPay, PhonePe, Paytm), Cards, and NetBanking alongside automated Cash-on-Delivery pre-fill.
- 🚚 **Order Tracking**: 7-stage interactive order timeline stepper with direct deep-links to 3PL courier tracking and one-tap Air Waybill clipboard copying.
- 🛠️ **Built-In Admin Management Suite**: Dedicated 2,000+ line management portal allowing authorized staff to publish catalog items, inspect damage claims, and download high-resolution print files.
- 🔔 **Push Notifications**: Firebase Cloud Messaging (FCM) integration with custom notification channels for real-time order dispatch notifications.

---

## 🏗️ Architecture & Project Structure

The project follows a clean, feature-driven **MVC Architecture** powered by GetX:

```
lib/
├── main.dart                      # App entry point, bindings & theme configuration
├── app/
│   ├── data/                      # Data layer
│   │   ├── models/                # Strongly-typed models (Poster, Order, User, Address)
│   │   ├── providers/             # HTTP clients & REST API service providers
│   │   └── repositories/          # Abstracted data access repositories
│   ├── modules/                   # Feature-driven UI modules (View + Controller + Binding)
│   │   ├── auth/                  # Login, Signup, OTP, and Google Sign-In
│   │   ├── home/                  # Catalog feed, carousel banner, category filters
│   │   ├── custom_print/          # Print-on-demand artwork upload & size selector
│   │   ├── cart/                  # Dynamic cart calculations, coupons, delivery charges
│   │   ├── checkout/              # Razorpay checkout & delivery address selector
│   │   ├── order_tracking/        # Visual milestone stepper & AWB details
│   │   ├── replacement/           # Post-delivery damage photo proof submission
│   │   ├── profile/               # Multi-address manager and user details
│   │   └── admin/                 # Catalog publishing, print queue & dispute manager
│   ├── routes/                    # AppRoutes and AppPages definitions
│   └── widgets/                   # Reusable UI components (custom buttons, cards, loaders)
```

---

## 🛠️ Tech Stack & Key Packages

| Package | Purpose |
| :--- | :--- |
| `get: ^4.6.5` | State management, route navigation, and dependency injection |
| `razorpay_flutter: ^1.3.7` | Native payment gateway integration |
| `image_picker: ^1.2.2` | Gallery & camera access for artwork uploads and damage proof |
| `firebase_core`, `firebase_messaging` | Push notifications and device token management |
| `google_sign_in: ^6.2.2` | Native Google OAuth 2.0 authentication |
| `shared_preferences: ^2.5.5` | Secure local storage for tokens and session state |
| `flutter_map`, `geolocator` | Address geolocation and regional serviceability helpers |

---

## 🚀 Running the Project

### Prerequisites
1. Ensure the [Flutter SDK](https://docs.flutter.dev/) is installed (`flutter doctor`).
2. Have an active Android emulator, iOS simulator, or physical device connected.
3. Ensure the [Poster Backend REST API](../poster_backend) is running.

### Installation
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run the application
flutter run
```

---

## 👩‍💻 Author

**Swastika Singh**  
- GitHub: [@SWASTIKA567](https://github.com/SWASTIKA567)  
- Backend Repository: [poster-backend](https://github.com/SWASTIKA567/poster-backend)
