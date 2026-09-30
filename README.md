# ProofIT

> A secure mobile evidence vault for capturing, scanning, and verifying digital evidence with cryptographic integrity and on-device AI.

ProofIT is a mobile application designed to securely capture, organize, and protect digital evidence such as documents, images, audio, video, text, and GPS location data.

The application combines **on-device AI document scanning**, **encrypted local storage**, **cryptographic hashing**, and **biometric/PIN authentication** to help users maintain the integrity of evidence from the moment it is created.

---

## 🚀 Key Features

### 📄 AI-Powered Document Scanner
- Automatic document edge detection using on-device computer vision
- Perspective correction and automatic cropping
- Scan physical documents directly from the mobile camera
- Designed to process documents without requiring cloud-based image processing

### 🗄️ Multi-Format Evidence Vault
Store different types of evidence in a single protected vault:

- 📄 Documents
- 🖼️ Images
- 🎙️ Audio recordings
- 🎥 Video recordings
- 📝 Text evidence
- 📍 GPS location data

Each evidence item can be stored with its associated metadata for easier organization and verification.

### 🔐 Cryptographic Integrity Verification
ProofIT generates cryptographic hashes for evidence files.

When evidence is created:

```text
Evidence File
     ↓
Cryptographic Hash
     ↓
Stored with Evidence Metadata
