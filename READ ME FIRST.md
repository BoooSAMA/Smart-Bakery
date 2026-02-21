# Smart Bakery Monitoring System (Flutter App)

## Project Packaging & Optimization

All auto-generated build artifacts and local cache files were removed because too big to upload. So need to type the command to initialize the dependencies.

### 1. Initialize Dependencies

Open terminal in the project root directory and execute:

```bash
flutter pub get
```

To fetch all required packages as defined in the `pubspec.yaml` file and reconstruct the `.dart_tool/` directory specifically for local SDK environment.

### 2. Run the Application

Ensure connecting a mobile phone by cable and activate the debug mode, then run:

```bash
flutter run
```

## Core Directory Structure

- **`lib/`**: Contains the primary Dart source code, including the network scanning logic.

- **`android/`**: Includes platform-specific configurations, like network permissions required for ioT communication.

- **`pubspec.yaml`**:Contains version information and the list of third-party library dependencies.