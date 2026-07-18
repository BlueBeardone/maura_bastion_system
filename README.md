# Maura Bastion System

A Flutter application for bastion management and news aggregation.

## Prerequisites

- Flutter SDK 3.0+
- Docker and Docker Compose (for containerized deployment)

## Docker

To run the web app use Docker:

1. Ensure Docker and Docker Compose are installed.
2. Run `docker compose up -d` to build and start the app.
3. Access the app at http://localhost:8080.



Goal: Setting up Appwrite SDK in the project depending on if a project already exists or not.

Following are the project details:

```
class Environment {
  static const String appwriteProjectId = '6a5bc196000fb1f857a6';
  static const String appwriteProjectName = 'Maura's Bastions';
  static const String appwritePublicEndpoint = 'https://fra.cloud.appwrite.io/v1';
}
```

Follow the steps depending on if a project already exists on user's working directory or not:

## If a project already exists:

Install the Appwrite Flutter SDK using the following command:

```
flutter pub add appwrite:25.3.0
```

From a suitable lib directory, export the Appwrite client as a global variable, hardcode the project details too:

```
final Client client = Client()
  .setProject("6a5bc196000fb1f857a6")
  .setEndpoint("https://fra.cloud.appwrite.io/v1");
```

On the homepage of the app, create a button that says "Send a ping" and when clicked, it should call the following function:

```
client.ping();
```
        

## If a project does not exist:

1. Clone the starter kit using the terminal. Make sure to clone in the current working directory so that the cloned files are directly available in the working directory.

```bash
git clone https://github.com/appwrite/starter-for-flutter
cd starter-for-flutter .
```

2. Replace all occurrences of the environment variables described in the project details section with their corresponding values. This effectively hardcodes the project details wherever those environment variables are used. Use grep (or an equivalent search) to find and update all occurrences.
3. Run the app on a connected device or simulator using `flutter run -d [device_name]`, then click the `Send a ping` button to verify the setup. Ask the user if the AI agent should run the command to run the app for them. Provide the full command while you ask for permission.