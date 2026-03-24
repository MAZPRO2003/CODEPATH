# Code Arena - 1v1 Problem Solving Arena

A dual-platform competitive coding arena featuring live problem sets, testcase execution frameworks, and real-time multiplayer overlays.

---

## 🛠️ Prerequisites & Installation (For Beginners)

If you have never run a codebase from GitHub, follow these exact steps to set up your computer.

### 1. Install [Git](https://git-scm.com/downloads)
Git handles downloaded code packages.
- **Windows/Mac**: Download the installer and run it, leaving settings as default (click Next through the prompts).
- **Linux**: Open terminal and type `sudo apt install git`.

### 2. Install [Node.js](https://nodejs.org/) (Required for Web App)
- Download the **LTS (Long Term Support)** green button version.
- Ensure the checkbox "Add to PATH" is checked during install to let your computer recognize commands.
- **Check Success**: Open your terminal (Command Prompt or Terminal app) and type:
  ```bash
  node -v
  npm -v
  ```
  *(Should print versions like v20.x or v22.x)*

### 3. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (Required for Desktop app)
- Follow the official OS instructions linked to install correctly.
- Run `flutter doctor` in your terminal to see if everything is green.

---

## 🌐 Web Application (React + Vite)

### 📂 Location
Files reside in the `/web_app` subdirectory.

### 🚀 How to Run
1. **Open your Terminal** (or use the terminal tab in your Code Editor).
2. **Navigate into the web directory**:
   ```bash
   cd web_app
   ```
3. **Download all app packages**:
   ```bash
   npm install
   ```
4. **Launch the app live stream**:
   ```bash
   npm run dev
   ```
5. **View in Browser**: Open the link shown in the terminal, usually [http://localhost:5173](http://localhost:5173).

---

## 🖥️ Desktop / Mobile Application (Flutter)

### 📂 Location
Files reside in the **root folder** of this repository.

### 🚀 How to Run
1. **Open your Terminal** in the root folder of the project (Do NOT enter web_app folder).
2. **Fetch packages**:
   ```bash
   flutter pub get
   ```
3. **Launch the application**:
   ```bash
   flutter run
   ```
   *Make sure you have an operating system desktop target active or an emulator open beforehand.*


