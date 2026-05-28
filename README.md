# Real-Time Chat App

A complete, production-ready real-time chat application built with Node.js, Socket.io, MongoDB, and Flutter.

## Features

- Real-time messaging with Socket.io
- JWT-based authentication
- Create and join chat rooms via invite codes
- Typing indicators
- Emoji reactions on messages
- Persistent token storage
- Dark mode support

## Setup Instructions

### Backend Setup

1. Navigate to the `backend` folder:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Copy `.env.example` to `.env` and fill in your variables (especially `MONGO_URI`):
   ```bash
   cp .env.example .env
   ```
4. Start the development server:
   ```bash
   npm run dev
   ```

### Flutter App Setup

1. Navigate to the `flutter_app` folder:
   ```bash
   cd Frontend_app_UI
   ```
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Ensure the emulator is running, or update `AppConstants.baseUrl` and `AppConstants.socketUrl` in `lib/utils/constants.dart` if using a real device.
4. Run the app:
   ```bash
   flutter run
   ```

## Screenshots

*Screenshots will be added here*

## Resume Bullet Points

- Developed a full-stack real-time chat application using Flutter and Node.js/Socket.io, serving seamless instant messaging capabilities across mobile platforms.
- Implemented robust JWT authentication and structured room-based chat logic, leveraging MongoDB for persistent message history and user data.
- Engineered dynamic UI elements in Flutter including real-time typing indicators, reaction pickers, and auto-scrolling message lists, managed efficiently via the Provider pattern.
