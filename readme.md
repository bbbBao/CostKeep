# 📱 CostKeep

<div align="center">

![iOS](https://img.shields.io/badge/iOS-18.2+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A modern, intuitive iOS app for receipt tracking and expense management, powered by Firebase and Vertex AI.

</div>

## ✨ Features

- 📸 **Smart Receipt Scanning**: Capture receipts using your device's camera
- 🤖 **AI-Powered Recognition**: Automatically extracts store names, items, and totals
- 📊 **Organized Timeline**: View your expenses in a clean, chronological interface
- 📅 **Calendar Integration**: Browse receipts by date with an elegant calendar view
- 🔐 **Secure Authentication**: Firebase-powered user authentication
- ☁️ **Cloud Storage**: All receipts safely stored in Firebase
- 📱 **Native iOS Experience**: Built with SwiftUI for seamless integration

## 🛠 Technical Stack

- **Frontend**: SwiftUI
- **Backend**: Firebase
- **AI/ML**: Vertex AI (Gemini 1.5)
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage & Firestore
- **Security**: Firebase App Check

## 🚀 Getting Started

1. Clone the repository
2. Add your `GoogleService-Info.plist` to the project
3. Install dependencies using Swift Package Manager
4. Build and run the project

## 🏗 Architecture

The app follows a clean architecture pattern with the following key components:

### 📱 Views
- `MainView`: Primary interface with receipt timeline
- `LoginView`: User authentication interface
- `DetailedReceiptView`: Individual receipt examination
- `CalendarView`: Date-based receipt browsing

### 🔧 Services
- `FirebaseService`: Handles all Firebase operations
- `AuthService`: Manages user authentication
- `VertexAI`: Processes receipt images using machine learning



## 🔒 Security

- Device Check integration for app verification
- Secure cloud storage with Firebase
- Protected API endpoints
- User data encryption

## 📸 Screenshots

[Coming Soon]

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.



