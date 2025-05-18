# digisign

A Flutter web application for digitally signing documents.

## Getting Started

This project is a Flutter web application.

A few resources to get you started if this is your first Flutter web project:

- [Lab: Write your first Flutter web app](https://docs.flutter.dev/get-started/web)
- [Cookbook: Useful Flutter web samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter web development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on web development, and a full API reference.

## Features

1. **Select Document via File Picker**:
    - Users can select documents from their local file system using the web browser's file picker. This feature allows the application to access various document formats (e.g., PDF) for signing.

2. **Digital Signature Creation and Placement**:
    - Users can create a digital signature using mouse or stylus input.
    - The created signature can be placed at any desired location on the document.
    - Multiple signatures can be created and saved within the application for reuse.
    - Users can add multiple signatures to a single document at different locations.

3. **Save Signed Document with Custom Name**:
    - After signing, users are prompted to provide a new name for the document.
    - The signed document is then saved directly to the user's downloads folder with the specified name. This ensures that the signed document is easily accessible.

## Running the Web App

To run this application in web mode:

1. Make sure you have Flutter installed and set up for web development:
   ```
   flutter channel stable
   flutter upgrade
   flutter config --enable-web
   ```

2. Run the application:

   ```
   flutter run -d chrome
   ```

3. For production builds:

   ```
   flutter build web
   ```

## Privacy and Security

This application processes all documents locally in the browser. No data is sent to any server:

- Files are selected using the browser's file picker and loaded into memory
- Document signing happens entirely in the client's browser
- The signed document is downloaded directly to the user's device
- No data persistence beyond what the user explicitly saves

This ensures complete privacy and security of your sensitive documents.
