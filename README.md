# Personal Allowance Manager

A multi-user allowance management Flutter application with Firebase backend.

## Features

- **Admin Dashboard**: User management, task assignment, transaction monitoring
- **User Interface**: PIN-based login, task completion, transaction history
- **Firebase Integration**: Real-time data synchronization, user authentication
- **Multi-Platform**: Web, iOS, Android support
- **Secure**: Firebase Auth with password reset functionality

## Screenshots

- Main screen with logo and user/admin options
- Admin dashboard for managing users and tasks
- User interface for completing tasks and viewing balances

## Getting Started

### Prerequisites

- Flutter SDK
- Firebase project configured
- Web browser for testing

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase (see Firebase Setup section)
4. Run `flutter run -d chrome` for web version

### Firebase Setup

This project uses Firebase for authentication and data storage. The Firebase configuration is included in `lib/firebase_options.dart`.

### Running the App

- **Web**: `flutter run -d chrome`
- **iOS**: `flutter run -d "iPhone Simulator"` (requires macOS)
- **Android**: `flutter run -d "Android Device"`

## Project Structure

- `lib/main.dart` - Main application entry point
- `lib/admin_*.dart` - Admin-related screens
- `lib/user_*.dart` - User-related screens
- `lib/firebase_options.dart` - Firebase configuration
- `assets/images/` - App logo and images

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.
