# DigiSign - Digital Document Signing App

A Flutter web application for digitally signing PDF documents, designed to work completely locally in the browser without sending data to any server.

## Features

1. **Select Document via File Picker**:
   - Upload PDF documents directly from your local file system
   - Privacy-focused: all document processing happens in your browser

2. **Digital Signature Management**:
   - Create signatures using mouse or touch input
   - Save multiple signatures with custom names for reuse
   - Manage (rename, delete) your saved signatures

3. **Document Signing**:
   - Place signatures anywhere on PDF documents
   - Add multiple signatures to a single document
   - Position signatures precisely where needed
   - Support for multi-page documents

4. **Save Signed Documents**:
   - Download signed documents directly to your device
   - Customize file names for signed documents
   - No data is sent to any server—everything stays on your device

## Getting Started

### Running the Web App

1. **Clone the repository**:
   ```
   git clone https://github.com/yourusername/digisign.git
   cd digisign
   ```

2. **Install dependencies**:
   ```
   flutter pub get
   ```

3. **Run the app in development mode**:
   ```
   flutter run -d chrome
   ```

4. **Build for production**:
   ```
   flutter build web
   ```

### Using the App

1. **Upload a Document**:
   - Launch the app in your browser
   - Click "Select Document" to upload a PDF
   - The document will appear in the viewer

2. **Create and Manage Signatures**:
   - Navigate to the Signatures screen by clicking the signature icon in the app bar
   - Create a new signature by clicking the + button
   - Draw your signature using mouse or touch
   - Save it with a name for later use

3. **Sign a Document**:
   - With a document open, click the signature icon in the toolbar
   - Choose to draw a new signature or use a saved one
   - Tap where you want to place the signature
   - Add multiple signatures as needed

4. **Save the Signed Document**:
   - Click the save icon in the toolbar
   - Enter a name for your signed document
   - Click "Save" to download the document to your device

## Privacy and Security

DigiSign is designed with privacy and security in mind:

- All document processing happens locally in your browser
- No data is sent to any server or stored in the cloud
- Signatures are stored in browser memory only
- Documents are downloaded directly to your device

## Technical Details

- Built with Flutter Web
- Uses SyncFusion PDF library for document manipulation
- Employs the flutter_signature_pad package for signature creation
- All data is stored in browser memory—no server or database required

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
