# Flutter Seminar 2 Project

This is a simple Flutter application developed for Seminar 2. It demonstrates basic user authentication including registration and login, and navigation between screens.

## Features

-   **User Registration:** New users can create an account with a username and password.
-   **User Login:** Existing users can log in to access the application.
-   **Protected Route:** A home screen that is only accessible to authenticated users.
-   **Basic Form Validation:** Ensures that user inputs for registration and login are not empty.

## Screenshots

*(Add screenshots of your application here to provide a visual overview.)*

| Login Screen | Register Screen | Home Screen |
| :---: |:---:|:---:|
| *Login Screen Screenshot* | *Register Screen Screenshot* | *Home Screen Screenshot* |

## Built With

*   [Flutter](https://flutter.dev/) - UI toolkit for building natively compiled applications.
*   [Dart](https://dart.dev/) - The programming language for Flutter.
*   [go_router](https://pub.dev/packages/go_router) - For declarative routing.
*   [provider](https://pub.dev/packages/provider) - For state management.

## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

-   Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

### Installation

1.  Clone the repo
    ```sh
    git clone <repository-url>
    ```
2.  Install packages
    ```sh
    flutter pub get
    ```
3.  Run the app
    ```sh
    flutter run
    ```

## Project Structure

The project follows a standard Flutter application structure, with logic separated into screens, services, and models.

```
seminar2/
├── android/                    # Android specific project files.
├── build/                      # Build output directory.
├── ios/                        # iOS specific project files.
├── lib/                        # Main application code.
│   ├── main.dart               # App entry point, sets up routing.
│   ├── data/
│   │   └── bookings.json       # Static data for bookings.
│   ├── models/
│   │   └── booking_model.dart  # Data model for bookings.
│   ├── providers/
│   │   └── app_state.dart      # Global application state (e.g., theme, auth).
│   ├── screens/
│   │   ├── admin_screen.dart
│   │   ├── analytics_screen.dart
│   │   ├── booking_screen.dart
│   │   ├── facilities_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── my_bookings_screen.dart
│   │   ├── register_screen.dart
│   │   ├── splash_screen.dart  # App landing/splash screen.
│   │   ├── user_management_screen.dart
│   │   └── user_profile_screen.dart
│   ├── services/
│   │   ├── auth_service.dart   # Handles user authentication.
│   │   └── firebase_service.dart # Handles Firebase interactions.
│   ├── utils/
│   │   └── date_formatter.dart # Utility for date formatting.
│   └── widgets/
│       ├── app_shell.dart      # Main app shell with AppBar and Drawer.
│       ├── analytics_dashboard.dart
│       ├── availability_checker.dart
│       ├── booking_details_dialog.dart
│       ├── booking_form.dart
│       ├── edit_booking_dialog.dart
│       ├── footer.dart
│       ├── header.dart
│       ├── login_dialog.dart
│       ├── public_seminars_list.dart
│       ├── rejection_dialog.dart
│       ├── stat_card.dart
│       ├── suggestion_dialog.dart
│       └── user_management.dart
├── test/                       # Contains all the tests for the project.
│   └── widget_test.dart        # Example widget test.
├── .gitignore                  # Specifies intentionally untracked files to ignore.
├── analysis_options.yaml       # Linter rules for static analysis.
├── pubspec.lock                # Auto-generated file specifying package versions.
├── pubspec.yaml                # Project dependencies and configuration.
└── README.md                   # This file.
```

### File Descriptions

-   **`android/`**: Contains the Android-specific project files. You would edit files here to configure Android-native settings.
-   **`ios/`**: Contains the iOS-specific project files. You would edit files here to configure iOS-native settings.
-   **`lib/`**: The most important directory, containing all the Dart code for your Flutter application.
    -   **`main.dart`**: The main entry point for the application. Configures `provider` and `go_router`.
    -   **`data/`**: Contains static data files like JSON.
    -   **`models/`**: Contains data model classes.
    -   **`providers/`**: Contains state management classes using the Provider package.
    -   **`screens/`**: Contains the main screens of the application.
    -   **`services/`**: Contains business logic, API clients, and database services.
    -   **`utils/`**: Contains utility functions and helpers.
    -   **`widgets/`**: Contains reusable UI components (widgets), including the main `AppShell`.
-   **`test/`**: Contains automated tests for your project.
-   **`pubspec.yaml`**: The project's configuration file, used to manage dependencies (packages), assets (like images and fonts), and other metadata.
-   **`README.md`**: This file, providing information about the project.

## API Reference

The application communicates with a backend service for authentication.

#### Register User

```http
  POST /api/register
```

**Request Body:**

```json
{
  "username": "your_username",
  "password": "your_password"
}
```

**Responses:**

-   `201 Created`: If the user is successfully registered.
-   `400 Bad Request`: If the username already exists or the input is invalid.

#### Login User

```http
  POST /api/login
```

**Request Body:**

```json
{
  "username": "your_username",
  "password": "your_password"
}
```

**Responses:**

-   `200 OK`: On successful login, returns a token.
-   `401 Unauthorized`: If the credentials are incorrect.
