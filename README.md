# 🏋️ Hero Fitness App

A Flutter e-commerce application for fitness supplements and gym accessories, built with Supabase as the backend.

## 📱 Features

- **Authentication** — Sign in / Sign up with Supabase Auth
- **Product Catalog** — Browse all products with categories
- **Featured Products** — Highlighted products carousel
- **Search** — Real-time product search
- **Categories** — Filter products by category
- **Cart** — Add and manage cart items
- **Personal Profile** — User account management

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| State Management | Flutter BLoC / Cubit |
| Backend | Supabase |
| Navigation | Go Router |
| HTTP Client | Dio |
| Local Storage | Shared Preferences |
| Image Caching | Cached Network Image |
| Fonts | Google Fonts |

## 🗂️ Project Structure

```
lib/
├── config/
│   ├── app_routes.dart        # Go Router configuration
│   └── app_theme.dart         # App theme & colors
├── core/
│   ├── errors/                # Failure entities
│   ├── utils/                 # Colors, constants
│   └── widgets/               # Reusable widgets
├── data/
│   ├── models/                # Data models
│   └── services/              # API & database services
└── presentation/
    └── pages/
        ├── auth/              # Sign in / Sign up
        ├── home_screens/      # Home, Cart, Categories, Profile
        ├── on_Borading/       # Onboarding screen
        └── splash/            # Splash screen
```

## ⚙️ Setup

### 1. Clone the repository
```bash
git clone https://github.com/muuahmmed/hero.git
cd hero
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure environment variables

Create `assets/.env` file:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_PUBLISHABLE_KEY=your_publishable_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 4. Run the app
```bash
flutter run
```

## 🗃️ Database Schema

| Table | Description |
|-------|-------------|
| `users` | User profiles |
| `categories` | Product categories |
| `products` | Product listings with images and pricing |
| `product_images` | Additional product images |
| `orders` | Customer orders |
| `order_items` | Items within each order |
| `payments` | Payment records |

## 📦 Product Categories

- 💪 Creatine
- 🥛 Proteins (Whey)
- ⚖️ Mass Gainers
- 🔥 Fat Burners
- 💊 Vitamins
- 🧬 Amino Acids
- ⚡ Pre-Workout
- 🎽 Accessories

## 📸 Storage

Product images are stored in **Supabase Storage** under the `products` bucket, organized by category folders.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License