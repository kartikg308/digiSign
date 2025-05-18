# digisign

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Features

1. **Import a document from storage**:
   - Users can select and import documents from their device's storage. This feature allows the application to access various document formats (e.g., PDF, DOCX) for signing.

2. **Create a digital signature and add that signature to the document at a custom location**:
   - Users can create a digital signature using touch or stylus input. Once created, the signature can be placed at a specific location on the document, allowing for customization of where the signature appears.
   - Multiple signatures can be created and saved within the application.
   - Users can add multiple signatures to a single PDF document at different locations.

3. **Save the document along with the signature of the application**:
   - After signing, users can save the modified document, which includes both the original content and the added digital signature(s). This ensures that the signed document is preserved for future reference.

4. **A dashboard where all documents can be viewed and sorted by last updated**:
   - The application will feature a dashboard that displays all imported documents. Users can view the list of documents and sort them based on the last updated date, making it easy to manage and access recent files.

5. **Select and share multiple documents**:
   - Users can select multiple documents from the dashboard and share them via various platforms (e.g., email, messaging apps). This feature enhances collaboration and allows for easy distribution of signed documents.
