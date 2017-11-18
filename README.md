# SwiftMosquitto
Swift bindings for the libmosquitto MQTT library

## Building

### Linux

```
sudo apt install libmosquitto-dev
swift build
```

### macOS

Since libmosquitto does not come with a `pkg-config` file, the library search path for [libmosquitto](https://mosquitto.org/) needs to be added manually.  E.g. to install libmosquitto via [Homebrew](https://brew.sh/) and then build, use

```
brew install mosquitto
swift build -Xlinker -L/usr/local/lib
```

To build using Xcode, use

```
brew install mosquitto
swift build -Xlinker -L/usr/local/lib
open 
```

