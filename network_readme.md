# Network Configuration & Troubleshooting Guide

## Overview

This document outlines the network configuration required to connect the **CCET Alumni Mobile App** (running on a physical Android device or emulator) to the **Local Backend Server** running on your PC.

## Configuration Details

### 1. Host Machine (PC)

* **IP Address**: `192.168.1.33` (Dynamic, check `ipconfig`)
* **Backend Port**: `3000`
* **API Base URL**: `http://192.168.1.33:3000/api`

### 2. Mobile App Config (`api_service.dart`)

Ensure `lib/services/api_service.dart`:

```dart
static String get baseUrl {
  return 'http://192.168.1.33:3000/api';
}
```

## How to Find Your Mobile IP Address

### Android

1. Open **Settings**.
2. Go to **Network & Internet** or **Wi-Fi**.
3. Tap on the **Wi-Fi network** you are currently connected to (or the gear icon/arrow next to it).
4. Scroll down to see **IP Address** (e.g., `192.168.1.35`).

### iOS (iPhone)

1. Open **Settings**.
2. Tap **Wi-Fi**.
3. Tap the blue **(i)** info icon next to your connected network.
4. Look for **IP Address** under the "IPV4 Address" section.

## Troubleshooting "No route to host" / Connection Refused

### Step 1: Firewall Rules (Access Denied? Run as Admin!)

You must allow Port 3000 through the Windows Firewall.
**Run PowerShell as Administrator** and execute:

```powershell
New-NetFirewallRule -DisplayName "Allow Node Port 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

* **Verify**: `Get-NetFirewallRule -DisplayName "Allow Node Port 3000"` should show `Enabled: True`.

### Step 2: Restart Node Server

**Important**: If you added the firewall rule *while* the server was running, it might not pick it up.

1. Stop the server (Ctrl+C).
2. Start it again: `node server.js`

### Step 3: Verify Device Visibility (Ping Test)

Can your PC see your phone?

```powershell
ping <YOUR_MOBILE_IP_ADDRESS>
```

* *Example*: `ping 192.168.1.35`
* **Success**: `Reply from ...` (Good, network is physically working).
* **Failure**: `Request timed out`. (Devices are on isolated networks. Use a Mobile Hotspot instead).

### Step 4: Advanced Firewall Troubleshooting

If connection still fails despite the rule:

1. **Temporarily Disable Firewall** (To test if Windows is the blocker):
    * **Admin Powerhshell**:

        ```powershell
        Set-NetFirewallProfile -Profile Private,Public -Enabled False
        ```

    * Try the app again.
    * **Success?** Windows Firewall is definitely the issue. Re-enable it (`-Enabled True`) and check your rules carefully.

2. **Check Third-Party Antivirus**
    * Do you have **McAfee**, **Norton**, **QuickHeal**, or **Kaspersky**?
    * **Windows Firewall rules do NOT affect them.**
    * You must go into your Antivirus Settings -> Firewall -> Ports -> Add Port 3000.

### Step 5: Network Profile

Ensure your specific WiFi network is trusted.

```powershell
Get-NetConnectionProfile
```

If `NetworkCategory` is `Public`, Windows blocks more traffic. Change it to Private:

```powershell
Set-NetConnectionProfile -InterfaceAlias "WiFi" -NetworkCategory Private
```
# Go to Settings > Wi-Fi.
# Tap the gear icon or the name of your connected network.
# Expand Advanced (if needed) and look for IP Address.
# For iOS:

# Go to Settings > Wi-Fi.
# Tap the blue (i) icon next to your network.
# Look for IP Address.