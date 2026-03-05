# StockSync - Vaccine & Order Management System

A full-stack application for managing vaccine inventory, client accounts, and orders with real-time updates using WebSockets.

## Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB
- **Real-time Communication**: Socket.io
- **Authentication**: JWT (JSON Web Tokens)

### Frontend
- **Framework**: Flutter
- **Language**: Dart
- **Platform Support**: iOS, Android, Web, Linux, macOS, Windows

## Project Structure

```
ConsultancyProject_1/
├── backend/                          # Node.js Express API
│   ├── src/
│   │   ├── app.js                   # Express app configuration
│   │   ├── server.js                # Server entry point
│   │   ├── config/
│   │   │   └── db.js                # Database configuration
│   │   ├── controllers/             # Business logic
│   │   │   ├── auth.controller.js
│   │   │   ├── client.controller.js
│   │   │   ├── order.controller.js
│   │   │   ├── product.controller.js
│   │   │   └── vaccine.controller.js
│   │   ├── models/                  # MongoDB schemas
│   │   │   ├── user.model.js
│   │   │   ├── client.model.js
│   │   │   ├── vaccine.model.js
│   │   │   ├── order.model.js
│   │   │   └── product.model.js
│   │   ├── routes/                  # API endpoints
│   │   │   ├── auth.routes.js
│   │   │   ├── client.routes.js
│   │   │   ├── vaccine.routes.js
│   │   │   ├── order.routes.js
│   │   │   └── product.routes.js
│   │   ├── middlewares/             # Custom middleware
│   │   │   └── auth.middleware.js
│   │   └── utils/
│   │       └── socket.js            # WebSocket configuration
│   ├── scripts/                      # Utility scripts
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
└── stocksync_frontend/              # Flutter mobile application
    ├── lib/
    │   ├── main.dart                # Application entry point
    │   ├── api_client.dart          # API communication
    │   ├── auth/                    # Authentication screens/logic
    │   ├── models/                  # Dart data models
    │   ├── screens/                 # UI screens
    │   └── services/                # Business logic services
    ├── test/
    │   └── widget_test.dart
    ├── android/                     # Android-specific configuration
    ├── ios/                         # iOS-specific configuration
    ├── web/                         # Web build configuration
    ├── windows/                     # Windows build configuration
    ├── linux/                       # Linux build configuration
    ├── macos/                       # macOS build configuration
    ├── pubspec.yaml                 # Flutter dependencies
    ├── analysis_options.yaml        # Lint rules
    └── .gitignore
```

## Features

- **User Authentication**: Secure login/registration with JWT tokens
- **Client Management**: Create and manage client accounts
- **Vaccine Inventory**: Track vaccine stock and availability
- **Order Management**: Create and manage orders with real-time updates
- **Product Management**: Manage products in the system
- **Real-time Updates**: WebSocket integration for instant notifications
- **Role-based Access**: Different access levels for users and clients

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Flutter SDK
- MongoDB (local or cloud instance)

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
   Create a `.env` file in the `backend` directory:
   ```
   PORT=5000
   MONGODB_URI=mongodb://localhost:27017/stocksync
   JWT_SECRET=your_secret_key_here
   NODE_ENV=development
   ```

4. **Initialize database (optional)**
   Run seed scripts to populate initial data:
   ```bash
   npm run seed-clients
   npm run seed-vaccines
   npm run setup-users
   ```

5. **Start the server**
   ```bash
   npm start
   ```
   The API will be available at `http://localhost:5000`

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd stocksync_frontend
   ```

2. **Get Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   Update the API client configuration to point to your backend:
   - Edit `lib/api_client.dart`
   - Set the `baseURL` to your backend server address

4. **Run the application**
   ```bash
   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios

   # For Web
   flutter run -d web

   # For specific device
   flutter run -d <device_id>
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

### Clients
- `GET /api/clients` - Get all clients
- `POST /api/clients` - Create new client
- `GET /api/clients/:id` - Get client details
- `PUT /api/clients/:id` - Update client
- `DELETE /api/clients/:id` - Delete client

### Vaccines
- `GET /api/vaccines` - Get all vaccines
- `POST /api/vaccines` - Create new vaccine
- `GET /api/vaccines/:id` - Get vaccine details
- `PUT /api/vaccines/:id` - Update vaccine
- `DELETE /api/vaccines/:id` - Delete vaccine

### Orders
- `GET /api/orders` - Get all orders
- `POST /api/orders` - Create new order
- `GET /api/orders/:id` - Get order details
- `PUT /api/orders/:id` - Update order
- `DELETE /api/orders/:id` - Delete order

### Products
- `GET /api/products` - Get all products
- `POST /api/products` - Create new product
- `GET /api/products/:id` - Get product details
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

## Available Scripts

### Backend Scripts
```bash
npm start              # Start the server
npm test              # Run tests
npm run seed-clients  # Seed client data
npm run seed-vaccines # Seed vaccine data
npm run setup-users   # Setup default users
npm run smoke-test    # Run smoke tests
```

## Database Models

### User
- username
- email
- password (hashed)
- role (admin, user, client)
- createdAt
- updatedAt

### Client
- name
- email
- phone
- address
- registrationDate
- status

### Vaccine
- name
- manufacturer
- batchNumber
- expiryDate
- quantity
- price
- description

### Order
- clientId
- items (products/vaccines)
- totalAmount
- status (pending, completed, cancelled)
- orderDate
- deliveryDate

### Product
- name
- description
- price
- quantity
- category

## Real-time Features

The application uses Socket.io for real-time communication. Connected clients receive instant updates for:
- Order status changes
- Inventory updates
- New client registrations
- Product availability changes

## Troubleshooting

### Backend Issues
- **MongoDB Connection Error**: Ensure MongoDB is running and connection string is correct in `.env`
- **Port Already in Use**: Change the PORT in `.env` file
- **Module Not Found**: Run `npm install` to ensure all dependencies are installed

### Frontend Issues
- **API Connection Error**: Verify the backend is running and API endpoint is correctly configured
- **Build Errors**: Run `flutter clean` and `flutter pub get`
- **Device Not Found**: Run `flutter devices` to list available devices

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

**Last Updated**: February 8, 2026
