# TAPTOM Mobile

**Language: English** | [Thai (ไทย)](./README-th.md)

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart&logoColor=white)
![Provider](https://img.shields.io/badge/State-Provider-6C63FF)
![Riverpod](https://img.shields.io/badge/State-Riverpod-00B0FF)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![License](https://img.shields.io/badge/License-Private-red)

A centralized agricultural management mobile application built with Flutter, designed for farmers and government officials to manage farm data, comply with **GAP (Good Agricultural Practices)** standards, and enable full product **traceability** through QR Code scanning.

---

## About The App

TAPTOM Mobile is an agricultural data management platform that connects farmers with government officials through a unified mobile experience. The app addresses real-world challenges in Thai agriculture: fragmented farm records, lack of standardized quality control, and the inability to trace produce back to its source.

Farmers can register their plots with precise GIS boundaries drawn directly on an interactive map, record detailed GAP compliance data across 7 standardized categories, and generate traceable lot numbers for their harvests. Officials can review submissions, approve plots, inspect GAP records, and manage their assigned farming communities -- all from a single application with role-based access control (Farmer, Admin, Super Admin).

---

## Key Features

### Authentication & Security
- Phone number + birthday credential-based sign-in (no password)
- 6-digit PIN verification with rate-limiting and lockout protection
- JWT access/refresh token lifecycle with automatic silent refresh on 401
- Encrypted token storage via `FlutterSecureStorage` (EncryptedSharedPreferences on Android)

### Plot & Map Management
- Interactive map using **MapLibre GL** with polygon drawing tools
- GeoJSON-based plot boundary registration with area calculation (Rai)
- Multi-image upload for plot documentation
- Location hierarchy: Region > Province > District > Sub-district

### GAP Compliance (7 Categories)
- **1.1** General Information (water source, soil type)
- **1.2** Agricultural Inputs (fertilizers, chemicals with safety data)
- **1.3** Field Management Activities
- **1.4** Harvest Records
- **1.5** Post-Harvest Handling
- **1.6** Worker Safety & Training
- **1.7** Traceability lot creation and tracking
- Real-time compliance progress tracking with visual indicators
- Offline draft support via SQLite for areas with poor connectivity

### QR Code Traceability (Public)
- Scan QR codes to view full product traceability reports
- No authentication required -- accessible to consumers and buyers
- Displays complete chain: plot origin, GAP records, harvest data, post-harvest handling

### AI Chat Assistant
- Voice input via `speech_to_text`
- HTTP-based AI service integration for agricultural guidance

### Role-Based Dashboards
- **Farmer**: Plot overview, GAP progress, harvest statistics, chart visualizations
- **Admin**: User/plot approval workflows, GAP inspection, messaging system, map overview of all assigned plots
- **Super Admin**: Admin management, system audit logs, platform-wide analytics and trends

### Additional Features
- In-app notification system
- Admin-to-farmer messaging and support ticket system
- PDF generation for GAP certificates and compliance reports
- Dark mode and Thai locale support
- PDPA (Personal Data Protection Act) consent tracking

---

## Architecture

```
lib/
├── main.dart                    # Entry point, DI setup, token preload
├── app.dart                     # GoRouter config, MultiProvider tree
├── locator.dart                 # GetIt service locator (DI)
├── core/
│   ├── config/                  # Environment variables (flutter_dotenv)
│   ├── constants/               # App-wide constants
│   ├── l10n/                    # Localization resources
│   ├── network/
│   │   ├── api_client.dart      # Dio HTTP client with interceptors
│   │   ├── api_endpoints.dart   # Centralized endpoint registry
│   │   └── interceptors/       # Auth injection, token refresh, error handling
│   ├── security/
│   │   └── secure_storage.dart  # Token & PIN storage (encrypted)
│   ├── services/                # 20 service classes (auth, plot, GAP, PDF, etc.)
│   ├── themes/                  # Material 3 light/dark theme definitions
│   ├── utils/                   # Helpers (GeoJSON parsing, formatters)
│   └── widgets/                 # Shared core widgets
├── data/
│   └── models/                  # 12 data models (User, Plot, GAP, etc.)
├── features/
│   ├── auth/                    # Login, Sign-up, PIN entry/set screens
│   ├── home/                    # Splash, Dashboard (Farmer + Admin)
│   ├── map/                     # MapLibre plot drawing, detail view
│   ├── gap/                     # 7 GAP form screens + summary
│   ├── traceability/            # QR scanner + report (public access)
│   ├── chat/                    # AI chat assistant with voice input
│   ├── certificate/             # PDF certificate generation
│   ├── admin/                   # Admin panel (17 screens)
│   ├── super_admin/             # Super admin management (5 screens)
│   ├── profile/                 # Personal info management
│   ├── settings/                # Theme, locale preferences
│   ├── notifications/           # Push notification center
│   ├── approval/                # Plot approval workflow
│   ├── contact/                 # Contact information
│   └── shared/                  # Support tickets (cross-role)
└── widgets/                     # Global reusable widgets
```

**Key architectural decisions:**
- **Layered architecture** separating UI (features), business logic (services/providers), and data (models/network)
- **Dual state management**: Provider for widget-tree-scoped state + GetIt for global singletons (AuthProvider accessible from interceptors without BuildContext)
- **Centralized API client** with Dio interceptors handling auth injection, 401 auto-refresh with concurrency lock, and 429 auto-retry with backoff
- **Feature-first organization** with each module owning its screens, widgets, and providers

---

## Tech Stack & Libraries

| Category | Library | Purpose |
|----------|---------|---------|
| **State Management** | `provider` | Widget-tree scoped state via ChangeNotifier |
| | `flutter_riverpod` | Declarative state for specific modules |
| | `get_it` | Service locator for DI outside widget tree |
| **Routing** | `go_router` | Declarative routing with auth redirect guards |
| **Networking** | `dio` | HTTP client with interceptors |
| | `pretty_dio_logger` | Debug-mode request/response logging |
| | `flutter_dotenv` | Environment variable management |
| | `supabase_flutter` | Backend service integration |
| **Maps & Location** | `maplibre_gl` | Interactive vector map rendering |
| | `geolocator` | Device GPS positioning |
| | `permission_handler` | Runtime permission management |
| **Forms** | `flutter_form_builder` | Declarative form construction |
| | `form_builder_validators` | Built-in validation rules |
| **Security** | `flutter_secure_storage` | Encrypted token/PIN persistence |
| **Local Storage** | `sqflite` | Offline GAP draft storage |
| | `shared_preferences` | User preferences (theme, locale) |
| **PDF** | `pdf` + `printing` | Certificate and report generation |
| | `share_plus` | Native share sheet for PDFs |
| **QR Code** | `mobile_scanner` | Camera-based QR code scanning |
| | `qr_flutter` | QR code image generation |
| **AI & Voice** | `http` | AI chat service communication |
| | `speech_to_text` | Voice input transcription |
| **UI** | `google_fonts` | Typography (Thai + English) |
| | `heroicons` | Icon set |
| | `google_nav_bar` | Bottom navigation |
| | `fl_chart` | Dashboard chart visualizations |
| | `cached_network_image` | Image caching and placeholder |
| **Utilities** | `intl` | Date/number formatting (Thai locale) |
| | `image_picker` | Photo capture and gallery selection |
| | `url_launcher` | External link handling |
| | `path_provider` | File system path resolution |
| | `package_info_plus` | App version display |

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.10.4
- Dart SDK >= 3.10.4
- Android Studio / Xcode (for emulator or physical device)
- A running instance of the [TAPTOM Backend (NestJS)](link-to-backend-repo)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/taptom-mobile.git
cd taptom-mobile

# 2. Create environment file
cp .env.example .env
# Edit .env and set your API_BASE_URL

# 3. Install dependencies
flutter pub get

# 4. Run the application
flutter run
```

### Environment Variables

Create a `.env` file in the project root:

```env
API_BASE_URL=https://your-api-domain.com
```

---

## Backend Integration

This mobile application connects to the **TAPTOM Backend** built with NestJS. The API client (`lib/core/network/api_client.dart`) handles:

- Automatic Bearer token injection on every request
- Silent token refresh on 401 Unauthorized with concurrency lock to prevent duplicate refresh calls
- Auto-retry on 429 (rate limiting) with 1-second backoff, up to 2 attempts
- Structured error handling with localized Thai error messages
- Configurable 8-second connect/receive timeout

API endpoints are centrally managed in `api_endpoints.dart`, covering 50+ endpoints across authentication, plots, GAP forms, traceability, admin operations, messaging, and analytics.