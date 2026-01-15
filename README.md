# 🦦 HomeOtter

**HomeOtter** is a modern, lightweight macOS menu bar application designed to keep your Home Assistant instance right at your fingertips. Monitor your system's health, track specific sensors live in your menu bar, and receive native notifications all with a beautiful, native macOS interface.

## 📸 Screenshots

<p align="center">
  <a href="https://i.postimg.cc/9XB1B7QM/Screenshot-2026-01-15-at-08-18-41.png" target="_blank">
    <img src="https://i.postimg.cc/9XB1B7QM/Screenshot-2026-01-15-at-08-18-41.png" alt="HomeOtter Dashboard" width="500">
  </a>
</p>

<p align="center">
  <a href="https://i.postimg.cc/pXhhLw4P/Screenshot-2026-01-15-at-08-21-44.png" target="_blank">
    <img src="https://i.postimg.cc/pXhhLw4P/Screenshot-2026-01-15-at-08-21-44.png" alt="HomeOtter System Health" width="250">
  </a>
  <a href="https://i.postimg.cc/4dxnkqpg/Screenshot-2026-01-15-at-08-23-06.png" target="_blank">
    <img src="https://i.postimg.cc/4dxnkqpg/Screenshot-2026-01-15-at-08-23-06.png" alt="HomeOtter Settings" width="250">
  </a>
  <a href="https://i.postimg.cc/7PgPtqFL/Screenshot-2026-01-15-at-08-27-46.png" target="_blank">
    <img src="https://i.postimg.cc/7PgPtqFL/Screenshot-2026-01-15-at-08-27-46.png" alt="HomeOtter Entity Browser" width="250">
  </a>
</p>

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

## 📊 Setting Up System Monitor (Required for System Health)

To display CPU, Memory, and Disk usage in HomeOtter, you need to enable the **System Monitor** integration in Home Assistant:

1.  Go to **Settings** → **Devices & Services** in Home Assistant.
2.  Click **+ Add Integration** (bottom right).
3.  Search for **"System Monitor"** and select it.
4.  Choose which sensors you want to monitor:
    -   ✅ **Processor use** (CPU usage)
    -   ✅ **Memory use** (RAM usage)  
    -   ✅ **Disk use** (Storage usage)
5.  Click **Submit** to create the integration.
6.  The sensors will now appear as entities (e.g., `sensor.processor_use`, `sensor.memory_use`, `sensor.disk_use`).

> 💡 **Tip**: After adding System Monitor, go to HomeOtter Settings and select the correct entities for CPU, Memory, and Disk in the **System Health Entities** section.

For more details, see the [System Monitor documentation](https://www.home-assistant.io/integrations/systemmonitor/).

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
