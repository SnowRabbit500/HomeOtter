<table>
  <tr>
    <td width="200">
      <img src="https://i.postimg.cc/14xS0GNn/Screenshot-2026-01-15-at-12-08-10.png" alt="HomeOtter Logo" width="180">
    </td>
    <td>
      <h1>HomeOtter</h1>
      <p><strong>HomeOtter</strong> is a free, open-source <strong>Home Assistant menu bar app for macOS</strong>. Monitor your smart home sensors, track system health, and get native macOS notifications, all from your menu bar. The perfect Home Assistant companion app for Mac users who want quick access to their smart home dashboard without opening a browser.</p>
      <p>💙 <em>If you find HomeOtter useful, consider supporting its development!</em></p>
      <p>
        <a href="https://buymeacoffee.com/snowrabbit500" target="_blank">
          <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="40">
        </a>
      </p>
    </td>
  </tr>
</table>

## 📸 Screenshots

<p align="center">
  <a href="https://i.postimg.cc/yYH36Svw/Screenshot_2026_01_16_at_11_19_48.png" target="_blank">
    <img src="https://i.postimg.cc/yYH36Svw/Screenshot_2026_01_16_at_11_19_48.png" alt="HomeOtter Dashboard" width="500">
  </a>
</p>

<p align="center">
  <a href="https://i.postimg.cc/dtYZQT4b/Screenshot_2026_01_16_at_11_20_59.png" target="_blank">
    <img src="https://i.postimg.cc/dtYZQT4b/Screenshot_2026_01_16_at_11_20_59.png" alt="HomeOtter System Health" width="250">
  </a>
  <a href="https://i.postimg.cc/zXrHDR06/Screenshot_2026_01_16_at_11_21_23.png" target="_blank">
    <img src="https://i.postimg.cc/zXrHDR06/Screenshot_2026_01_16_at_11_21_23.png" alt="HomeOtter Settings" width="250">
  </a>
  <a href="https://i.postimg.cc/WbvqpJXW/Screenshot_2026_01_16_at_11_22_08.png" target="_blank">
    <img src="https://i.postimg.cc/WbvqpJXW/Screenshot_2026_01_16_at_11_22_08.png" alt="HomeOtter Entity Browser" width="250">
  </a>
</p>

## ✨ Features

-   **🏠 Menu Bar Dashboard**: Quick access to your most important Home Assistant stats without leaving your current app.
-   **🌡️ Live Menu Bar Stats**: Display up to 6 Home Assistant sensor values (temperature, power, solar, etc.) directly in the macOS menu bar.
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

> ⚠️ **URL Tips**:
> - **Do NOT include a trailing slash** at the end of your URL
>   - ✅ Correct: `https://your-ha.ui.nabu.casa`
>   - ❌ Wrong: `https://your-ha.ui.nabu.casa/`
> - Use the full URL including `https://`

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

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
*Created with ❤️ for the Home Assistant community.*
