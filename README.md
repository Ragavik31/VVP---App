# StockSync - Order & Inventory Management System

A full-stack application for managing inventory, client accounts, staff assignments, and orders with real-time updates using WebSockets and in-depth admin analytics.

## Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB (Mongoose)
- **Real-time Communication**: Socket.io
- **Authentication**: JWT (JSON Web Tokens) with role-based access control

### Frontend
- **Framework**: Flutter
- **Language**: Dart
- **Platform Support**: iOS, Android, Web, Linux, macOS, Windows

---

## Project Structure

```
StockSync---App/
├── backend/                              # Node.js Express API
│   ├── src/
│   │   ├── app.js                       # Express app configuration
│   │   ├── server.js                    # Server entry point
│   │   ├── config/
│   │   │   └── db.js                    # MongoDB connection
│   │   ├── controllers/                 # Business logic
│   │   │   ├── analytics.controller.js  # Sales & KPI analytics
│   │   │   ├── auth.controller.js       # Auth, user, phone mgmt
│   │   │   ├── client.controller.js     # Client CRUD
│   │   │   ├── order.controller.js      # Order lifecycle
│   │   │   ├── payment.controller.js    # Payment processing
│   │   │   ├── product.controller.js    # Product CRUD
│   │   │   └── vaccine.controller.js    # Vaccine inventory
│   │   ├── models/                      # MongoDB schemas
│   │   │   ├── user.model.js
│   │   │   ├── client.model.js
│   │   │   ├── order.model.js
│   │   │   ├── product.model.js
│   │   │   └── vaccine.model.js
│   │   ├── routes/                      # API endpoints
│   │   │   ├── analytics.routes.js
│   │   │   ├── auth.routes.js
│   │   │   ├── client.routes.js
│   │   │   ├── order.routes.js
│   │   │   ├── payment.routes.js
│   │   │   ├── product.routes.js
│   │   │   └── vaccine.routes.js
│   │   ├── middlewares/
│   │   │   └── auth.middleware.js       # JWT auth + role guard
│   │   └── utils/
│   │       └── socket.js               # WebSocket configuration
│   ├── scripts/                         # Utility/seed scripts
│   │   ├── seed-clients-and-users.js
│   │   ├── seed-clients.js
│   │   ├── seed-vaccines.js
│   │   ├── setup-default-users.js
│   │   ├── smoke-test.js
│   │   ├── update-user-role-to-client.js
│   │   └── verify-client-login.js
│   ├── package.json
│   └── .gitignore
│
└── stocksync_frontend/                  # Flutter application
    ├── lib/
    │   ├── main.dart                    # App entry point
    │   ├── api_client.dart              # HTTP & API communication
    │   ├── auth/
    │   │   └── auth_provider.dart       # Auth state management
    │   ├── models/
    │   │   └── app_user.dart            # User model
    │   ├── providers/                   # State providers
    │   ├── services/                    # Business logic services
    │   ├── theme/                       # App theming
    │   └── screens/
    │       ├── login_screen.dart                    # Unified login (Admin/Staff/Client)
    │       ├── home_shell.dart                      # Navigation shell
    │       ├── dashboard_screen.dart                # Admin dashboard
    │       ├── admin_order_management_screen.dart    # Admin order control
    │       ├── admin_sales_analytics_screen.dart     # Sales KPIs & analytics
    │       ├── client_dashboard_screen.dart          # Client overview
    │       ├── client_home_screen.dart               # Client home
    │       ├── client_list_screen.dart               # Admin client list
    │       ├── client_form_screen.dart               # Add/edit client
    │       ├── client_my_orders_screen.dart          # Client order history
    │       ├── client_order_placement_screen.dart    # Place new order
    │       ├── product_list_screen.dart              # Product inventory
    │       ├── product_form_screen.dart              # Add/edit product
    │       ├── staff_order_management_screen.dart    # Staff order handling
    │       ├── vaccine_list_screen.dart              # Vaccine inventory
    │       └── vaccine_form_page.dart                # Add/edit vaccine
    ├── test/
    │   └── widget_test.dart
    ├── android/
    ├── ios/
    ├── web/
    ├── windows/
    ├── linux/
    ├── macos/
    ├── pubspec.yaml
    └── .gitignore
```

---

## Features

### 👑 Admin
- **Sales Analytics Dashboard**: Live KPIs — Total Revenue, Outstanding Receivables, Active Staff Load; Top 5 Products, Top Clients by Spend, Staff Efficiency (avg. acceptance time & order volume), with date-range filtering and CSV export.
- **Order Management**: View all orders, assign to staff, update statuses, track payment (cash/online), and delete orders.
- **Client Management**: Create, edit, and manage client accounts with custom entry codes.
- **Product & Vaccine Inventory**: Full CRUD for products and vaccines with stock tracking.
- **Collection Tracker**: Highlights upcoming and overdue cash payments.

### 🧑‍🔧 Staff
- **Order Handling**: View assigned orders, accept them, and update delivery status.
- **Real-time Notifications**: Instant Socket.io push when a new order is assigned.

### 🛒 Client
- **Order Placement**: Browse products/vaccines and place orders with cash or online payment.
- **Order Tracking**: View order history, statuses, and assigned staff contact details.
- **Account Management**: Change phone number directly from the dashboard.
- **Due-Soon Alerts**: View approaching payment due dates within a 7-day window.

### 🔌 Real-time (Socket.io)
- Order status updates pushed instantly to all relevant parties
- New order notifications for admin and staff
- Inventory change broadcasts

---

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- npm
- Flutter SDK (stable channel)
- MongoDB (local or Atlas cloud instance)

### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   Create a `.env` file in the `backend/` directory:
   ```env
   PORT=5000
   MONGODB_URI=mongodb://localhost:27017/stocksync
   JWT_SECRET=your_secret_key_here
   NODE_ENV=development
   ```

4. **Seed the database (optional)**
   ```bash
   npm run seed-clients
   npm run seed-vaccines
   npm run setup-users
   ```

5. **Start the server**
   ```bash
   npm start
   ```
   API available at `http://localhost:5000`

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd stocksync_frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure the API endpoint**
   Edit `lib/api_client.dart` and set the `baseURL` to your backend server address.

4. **Run the application**
   ```bash
   # Android
   flutter run -d android

   # iOS
   flutter run -d ios

   # Web
   flutter run -d chrome

   # Any connected device
   flutter run
   ```

---

## API Endpoints

### Authentication (`/api/auth`)
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/register` | Public | Register a new user |
| POST | `/login` | Public | Login and receive JWT |
| POST | `/change-password` | Public | Change user password |
| PATCH | `/phone` | Authenticated | Update phone number |
| GET | `/me` | Authenticated | Get current user info |
| GET | `/users` | Authenticated | Get all users |
| GET | `/users/by-role` | Authenticated | Get users filtered by role |

### Orders (`/api/orders`)
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/` | Client | Place a new order |
| GET | `/` | All | Get orders (filtered by role) |
| GET | `/pending` | Admin | Get all pending orders |
| GET | `/due-soon` | Client | Get orders with upcoming payments |
| PATCH | `/:id/status` | Admin, Staff | Update order status |
| PATCH | `/:id/payment` | Admin, Staff | Update payment status |
| PATCH | `/:id/assign` | Admin | Assign order to staff |
| PATCH | `/:id/accept` | Staff | Accept an assigned order |
| DELETE | `/:id` | Admin | Delete an order |

### Clients (`/api/clients`)
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/` | Admin | List all clients |
| POST | `/` | Admin | Create a new client |
| GET | `/:id` | Admin | Get a client's details |
| PUT | `/:id` | Admin | Update a client |
| DELETE | `/:id` | Admin | Delete a client |

### Products (`/api/products`)
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/` | All | List all products |
| POST | `/` | Admin | Create a new product |
| GET | `/:id` | All | Get product details |
| PUT | `/:id` | Admin | Update a product |
| DELETE | `/:id` | Admin | Delete a product |

### Vaccines (`/api/vaccines`)
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/` | All | List all vaccines |
| POST | `/` | Admin | Create a new vaccine |
| GET | `/:id` | All | Get vaccine details |
| PUT | `/:id` | Admin | Update a vaccine |
| DELETE | `/:id` | Admin | Delete a vaccine |

### Analytics (`/api/analytics`)
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/` | Admin | Full analytics dashboard data |

### Payments (`/api/payments`)
| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/create-order` | Authenticated | Initiate a payment order |
| POST | `/verify` | Authenticated | Verify a completed payment |

---

## Available Scripts

### Backend
```bash
npm start              # Start the server (nodemon)
npm run seed-clients   # Seed client data
npm run seed-vaccines  # Seed vaccine data
npm run setup-users    # Setup default admin/staff users
npm run smoke-test     # Run smoke tests
```

---

## Database Models

### User
| Field | Type | Notes |
|-------|------|-------|
| username | String | Unique login name |
| password | String | Bcrypt hashed |
| role | String | `admin`, `staff`, `client` |
| phone | String | Contact number |

### Client
| Field | Type | Notes |
|-------|------|-------|
| name | String | |
| phone | String | |
| address | String | |
| entryCode | String | Unique login code |
| status | String | Active/Inactive |

### Order
| Field | Type | Notes |
|-------|------|-------|
| clientId / clientName | Ref / String | |
| items | Array | Products/vaccines with qty & price |
| totalPrice | Number | |
| status | String | `pending` → `assigned` → `accepted` → `delivered` |
| paymentMethod | String | `cash` or `online` |
| paymentStatus | String | `paid` or `unpaid` |
| paymentDueDate | Date | |
| assignedTo | Ref (User) | Staff assigned |
| timestamps | Date | `createdAt`, `assignedAt`, `acceptedAt`, `deliveredAt` |

### Product
| Field | Type |
|-------|------|
| name | String |
| description | String |
| price | Number |
| quantity | Number |
| category | String |

### Vaccine
| Field | Type |
|-------|------|
| name | String |
| manufacturer | String |
| batchNumber | String |
| expiryDate | Date |
| quantity | Number |
| price | Number |

---

## Troubleshooting

### Backend
- **MongoDB Connection Error**: Check MongoDB is running and `MONGODB_URI` in `.env` is correct.
- **Port Already in Use**: Change `PORT` in `.env`.
- **Module Not Found**: Run `npm install`.

### Frontend
- **API Connection Error**: Confirm backend is running and `baseURL` in `api_client.dart` is correct.
- **Build Errors**: Run `flutter clean && flutter pub get`.
- **Device Not Found**: Run `flutter devices` to list connected devices.

---

**Last Updated**: March 2026
