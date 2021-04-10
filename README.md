<img src="https://github.com/Glartek/flutter-unity/raw/master/flutter-unity.png">

# flutter_unity

A Flutter plugin for embedding Unity projects in Flutter projects.

Both Android and iOS are supported.

## Usage
To use this plugin, add `flutter_unity` as a [dependency in your pubspec.yaml file](https://flutter.dev/platform-plugins/).
```
    flutter_unity:
        git:
            url: git@github.com:gatari/flutter-unity.git
            ref: 1.1.0
```

## Example
Refer to the [template](https://github.com/t5ujiri/flutter_unity_blueprints) project.

## Configuring your Unity project
#### Android
1. In the [Player Settings](https://docs.unity3d.com/Manual/class-PlayerSettings.html) window, configure the following:
<table>
  <thead>
    <tr>
      <th>Setting
      </th>
      <th>Value
      </th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Resolution and Presentation > Start in fullscreen mode
      </td>
      <td>No
      </td>
    </tr>
    <tr>
      <td>Other Settings > Rendering > Graphics APIs
      </td>
      <td>OpenGLES3
      </td>
    </tr>
    <tr>
      <td>Other Settings > Configuration > Scripting Backend
      </td>
      <td>IL2CPP
      </td>
    </tr>
    <tr>
      <td>Other Settings > Configuration > Target Architectures
      </td>
      <td>ARMv7, ARM64
      </td>
    </tr>
  </tbody>
</table>

1. Select `Build/Export Android` to export Gradle project into flutter android directory.
#### iOS

1. Select `Build/Export IOS` to export Gradle project into flutter android directory.

## Configuring your Flutter project
#### Android
1. Run `flutter pub run flutter_unity:unity_export_transmogrify`.
1. Open `<your_flutter_project>/android/build.gradle` and, under `allprojects { repositories {} }`, add the following:
```
flatDir {
    dirs "${project(':unityExport').projectDir}/libs"
}
```
3. Open `<your_flutter_project>/android/settings.gradle` and add the following:
```
include ':unityExport'
```
4. Open `<your_flutter_project>/android/app/src/main/AndroidManifest.xml` and add the following:
```
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

Steps 1 must be repeated for every new build of the Unity project.

#### iOS
1. Open `<your_flutter_project>/ios/Runner.xcworkspace` in **Xcode**.
2. Go to **File** > **Add Files to "Runner"...**, and add `<your_flutter_project>/ios/UnityProject/Unity-iPhone.xcodeproj`.
3. Select `Runner`, select **TARGETS** : **Runner**, and, in the **General** tab, configure the following:
<table>
  <thead>
    <tr>
      <th>Setting
      </th>
      <th>Value
      </th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Frameworks, Libraries, and Embedded Content
      </td>
      <td>
        <table>
          <thead>
            <tr>
              <th>Name
              </th>
              <th>Embed
              </th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>UnityFramework.framework
              </td>
              <td>Embed & Sign
              </td>
            </tr>
          </tbody>
        </table>
      </td>
    </tr>
  </tbody>
</table>

## Exchanging messages between Flutter and Unity

#### Flutter

To send a message, define the `onCreated` callback in your `UnityView` widget, and use the `send` method from the received `controller`.

To receive a message, define the `onMessage` callback in your `UnityView` widget.

#### Unity

To export from Unity editor, import [Unity Package](https://github.com/t5ujiri/flutter-unity/tree/main/example/unity/Packages).
Post build process scripts are in Editor directory to transform exported builds, making them adapt to flutter app.

```json
"dependencies": {
    ...
    "net.caffeineinject.flutter-unity-plugin": "https://github.com/t5ujiri/flutter-unity.git?path=example/unity/flutter_unity_example_unity/Packages/FlutterUnityPlugin"
    ...
}
```

To send messages from Unity, use [Messages.Send](https://github.com/t5ujiri/flutter_unity_blueprints/blob/main/example/unity/flutter_unity_example_unity/Packages/FlutterUnityPlugin/Runtime/Messages.cs);

To receive messages, use singleton instance of [FlutterMessageReceiver](https://github.com/t5ujiri/flutter_unity_blueprints/blob/main/example/unity/flutter_unity_example_unity/Packages/FlutterUnityPlugin/Runtime/FlutterMessageReceiver.cs).

A `Message` object has the following members:

* **id** (`int`)

A non-negative number representing the source view when receiving a message, and the destination view when sending a message. When sending a message, it can also be set to a negative number, indicating that the message is intended for any existing view.

* **data** (`string`)

The actual message.