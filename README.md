# Inventory Management App

A full-stack mobile application for managing inventory in a religious offerings shop selling Khmer Spirit Houses, statues, incense, and religious decorations.

## 🏗️ Project Structure

```
Grocery Store/
├── backend/                    # Node.js Express API
│   ├── config/                 # Database and service configs
│   ├── database/              # SQL schema
│   ├── middleware/            # Auth and upload middleware
│   ├── routes/                # API route handlers
│   ├── scripts/               # Utility scripts
│   ├── server.js              # Main entry point
│   └── package.json
│
└── mobile/                     # Flutter mobile app
    ├── lib/
    │   ├── models/            # Data models
    │   ├── providers/         # State management
    │   ├── screens/           # UI screens
    │   ├── services/          # API service
    │   ├── utils/             # Colors, configs
    │   ├── widgets/           # Reusable components
    │   └── main.dart          # App entry
    └── pubspec.yaml
```

## 🚀 Quick Start

### Prerequisites

- **PostgreSQL** 14+ installed and running
- **Node.js** 18+ with npm
- **Flutter** 3.0+ with Dart SDK
- **Android Studio** or **Xcode** for mobile development

### 1. Database Setup

```bash
# Create database
psql -U postgres -c "CREATE DATABASE inventory_db;"

# Run schema
psql -U postgres -d inventory_db -f backend/database/schema.sql
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Update .env with your database credentials:
# DATABASE_URL=postgresql://username:password@localhost:5432/inventory_db
# JWT_SECRET=your_secret_key

# Start the server
npm run dev
```

The API will be running at `http://localhost:3000`

### 3. Flutter App Setup

```bash
cd mobile

# Get dependencies
flutter pub get

# Update API URL in lib/utils/api_config.dart:
# - Android Emulator: http://10.0.2.2:3000/api
# - iOS Simulator: http://localhost:3000/api
# - Physical Device: http://YOUR_COMPUTER_IP:3000/api

# Run the app
flutter run
```

## 🔑 Default Login Credentials

| Role  | Email           | Password  |
|-------|-----------------|-----------|
| Admin | admin@shop.com  | admin123  |

## 📱 Features

### For Admin
- ✅ Full dashboard with inventory value & profit margins
- ✅ Add/Edit/Delete products
- ✅ View cost prices and profit per item
- ✅ Profit calculator screen
- ✅ Manage staff accounts

### For Staff
- ✅ View products (selling price only)
- ✅ Adjust stock quantities
- ✅ View low stock alerts
- ✅ Basic dashboard stats

## 🔌 API Endpoints

| Method | Endpoint                    | Description              |
|--------|----------------------------|--------------------------|
| POST   | /api/auth/login            | User login               |
| POST   | /api/auth/register         | Register user (Admin)    |
| GET    | /api/products              | List products            |
| POST   | /api/products              | Create product (Admin)   |
| PUT    | /api/products/:id          | Update product (Admin)   |
| PATCH  | /api/products/:id/stock    | Update stock             |
| DELETE | /api/products/:id          | Delete product (Admin)   |
| GET    | /api/categories            | List categories          |
| GET    | /api/dashboard/stats       | Dashboard statistics     |
| GET    | /api/dashboard/profit-calculator | Profit data (Admin) |

## 🎨 Theme Colors

| Color          | Hex       | Usage            |
|----------------|-----------|------------------|
| Warm Wood      | #8B4513   | Primary accents  |
| Gold           | #D4AF37   | Highlights       |
| Saffron Orange | #F4A460   | Buttons, active  |
| Deep Wood      | #3E2723   | Text, headers    |
| Clean White    | #FAFAFA   | Backgrounds      |

## 📝 Notes

- Stock status colors: 🟢 Green (Good) | 🟡 Yellow (Low) | 🔴 Red (Out)
- Cost prices and profit data are hidden from staff users
- Images are uploaded to Cloudinary (configure in .env)
- Passwords are hashed with bcrypt
- JWT tokens expire after 7 days
