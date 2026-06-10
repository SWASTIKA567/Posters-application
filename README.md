# 🛍️ Poster Printing App

A Flutter-based poster e-commerce app — browse a catalog, upload custom designs, and place print-on-demand orders.

 **Work in progress** — core features functional, UI refinements ongoing.

---

## ✨ Features

- 🔐 **Authentication** — Login & signup with Firebase Auth (GetX MVC flow)
- 🗂️ **Poster Catalog** — Browse featured & recent posters with category filtering
- 📤 **Custom Upload** — Upload your own design for print fulfillment
- 🛒 **Cart & Orders** — Add to cart, manage orders via Firebase Firestore
- 👤 **Profile Screen** — View and manage account details
- 🎨 **3D Animated UI** — Custom cube painter with light 3D animations
- 🔔 **Push Notifications** — Firebase Cloud Messaging (FCM) integration

---

## 🛠️ Tech Stack

| Layer | Tech |
|-------|------|
| Framework | Flutter |
| State Management | GetX |
| Backend | Firebase (Auth, Firestore, Storage) |
| Notifications | FCM |
| Language | Dart |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── data/         # models, repositories
│   ├── modules/      # feature screens (home, auth, profile, orders)
│   ├── routes/       # GetX routing
│   └── widgets/      # reusable UI components
```

---

## 📸 Screenshots


| Login | Home | Catalog | Orders |
|-------|------|---------|--------|
| ![](screenshots/login.png) | ![](screenshots/home.png) | ![](screenshots/catalog.png) | ![](screenshots/orders.png) |

---


## 🔧 Setup — Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication**, **Firestore**, **Storage**, and **FCM**
3. Download `google-services.json` and place it in `android/app/`

---

## 📌 Status

- [x] Auth flow (login, signup, splash)
- [x] Home screen with bento grid UI
- [x] Poster catalog (featured & recent)
- [x] Upload flow with Firebase Storage
- [x] Cart & order management
- [x] Profile screen
- [ ] Payment gateway integration
- [ ] Admin panel
- [ ] iOS build

---

## 👩‍💻 Author

**Swastika Singh**
[![GitHub](https://img.shields.io/badge/GitHub-SWASTIKA567-181717?style=flat-square&logo=github)](https://github.com/SWASTIKA567)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-swastika-0A66C2?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/swastika-singh-43b52833a?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app)
