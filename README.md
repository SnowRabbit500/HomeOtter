# 🦦 HomeOtter

**HomeOtter** is a modern, lightweight macOS menu bar application designed to keep your Home Assistant instance right at your fingertips. Monitor your system's health, track specific sensors live in your menu bar, and receive native notifications—all with a beautiful, native macOS interface.

![HomeOtter Dashboard](https://raw.githubusercontent.com/SnowRabbit500/HomeOtter/main/Screenshot.png) *(Add your own screenshot here!)*

## ✨ Features

-   **🏠 Menu Bar Dashboard**: Quick access to your most important Home Assistant stats without leaving your current app.
-   **🌡️ Live Menu Bar Stats**: Display any Home Assistant sensor value (temperature, power, solar, etc.) directly in the macOS menu bar.
-   **📉 System Health Monitoring**: Real-time monitoring of CPU, Memory, and Disk usage with beautiful circular gauges.
-   **🔔 Native Notifications**: Get macOS alerts when system thresholds are exceeded or when a new Home Assistant Core update is available.
-   **🌐 Browser Shortcut**: Quickly open your full Home Assistant dashboard in Safari with one click.
-   **🚀 Launch at Login**: Automatically starts when you turn on your Mac.
-   **🌓 Appearance Modes**: Supports Light, Dark, and System (Auto) modes with a modern glassmorphism design.
-   **🔍 Entity Browser**: Easily browse, search, and pin any Home Assistant entity to your dashboard.

## 🚀 Getting Started

### Prerequisites

-   **macOS**: 13.0 (Ventura) or later.
-   **Home Assistant**: A running instance accessible via URL.
-   **Token**: A [Long-Lived Access Token](https://www.home-assistant.io/docs/authentication/#long-lived-access-token) from your Home Assistant profile.

## ⚙️ Configuration

1.  Click the 🦦 icon in your menu bar.
2.  Click the **Settings (⚙️)** icon.
3.  Enter your **Home Assistant URL** (e.g., `https://your-ha.ui.nabu.casa`).
4.  Paste your **Long-Lived Access Token**.
5.  Click **Test Connection** to verify.
6.  (Optional) Configure your System Health entities and Menu Bar sensor.

## 🛠️ Built With

-   **SwiftUI**: For the modern, native user interface.
-   **Combine**: For reactive data handling and timers.
-   **Home Assistant REST API**: For seamless integration with your smart home.
-   **UserNotifications**: For native macOS system alerts.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue for any bugs or feature requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
*Created with ❤️ for the Home Assistant community.*
