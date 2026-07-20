# Firebase Setup Guide - ZimPower Tracker

I have already configured your code and Gradle files to support Firebase. Now, you need to set up the project in the Firebase Console and add the configuration files.

## Step 1: Create a Firebase Project
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Click **"Add project"** and name it `ZimPower Tracker`.
3.  Choose whether to enable Google Analytics (optional).

## Step 2: Register the Android App
1.  In the Firebase Project Overview, click the **Android icon**.
2.  **Android Package Name**: `com.example.zim_tracker` (Matches your `app/build.gradle.kts`).
3.  **App Nickname**: `ZimPower Tracker Android`.
4.  Click **"Register app"**.

## Step 3: Add Configuration File
1.  Download the `google-services.json` file.
2.  Place it in the following directory:
    `C:\Users\TINASHE\Documents\StudioProjects\zim_tracker\android\app\`
3.  Click **"Next"** in the console. (I have already completed the "Add Firebase SDK" steps for you in the Gradle files).

## Step 4: Configure Firebase Services
To make the app functional, you need to enable these services in the Firebase Console:

### 1. Authentication
- Go to **Build > Authentication** in the sidebar.
- Click **"Get Started"**.
- Enable **"Email/Password"** as a sign-in provider.

### 2. Cloud Firestore
- Go to **Build > Firestore Database**.
- Click **"Create database"**.
- Choose a location and start in **"Test mode"** (to allow initial reads/writes).
- **CRITICAL**: Create a collection named `zones` and add a sample document:
  - **Document ID**: `harare_central`
  - **Fields**:
    - `name` (string): `Harare Central`
    - `region` (string): `Grid Zone A1`
    - `status` (string): `OFF`
    - `lastUpdated` (timestamp): `Current Time`

## Step 5: Run the App
Once you've added the `google-services.json` file, run:
```bash
flutter run
```

> [!TIP]
> If you want to use the **FlutterFire CLI** for a faster setup that also handles iOS/Web, run:
> `dart pub global activate flutterfire_cli`
> `flutterfire configure`
