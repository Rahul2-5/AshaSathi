# 🏥 AshaSathi – Offline-First Digital Companion for ASHA Workers

> Empowering grassroots healthcare workers with reliable, offline-capable digital tools.

AshaSathi is a **mobile-first healthcare application** built to support **ASHA (Accredited Social Health Activist) workers** in managing patient data efficiently in **low-connectivity rural environments**.

It replaces traditional paper-based workflows with a **robust offline-first system**, ensuring data is never lost and always synced when connectivity is available.

---

## 🌍 Why This Project Matters

In many rural areas:
- Internet connectivity is unreliable  
- Healthcare records are maintained on paper  
- Patient tracking is inconsistent and error-prone  

This leads to:
- Missed vaccinations  
- Poor maternal care tracking  
- Loss of critical health data  

**AshaSathi solves this by:**
- Enabling offline data capture  
- Structuring patient records  
- Providing reliable sync mechanisms  

---

## ✨ Key Features

### 👩‍⚕️ Smart Patient Management
- Store complete patient profiles:
  - Name, Age, Gender, DOB  
  - Family members  
  - Medical history & diseases  
- Special handling for:
  - 🤰 Pregnancy tracking (months, expected delivery)  
  - 👶 Child care (vaccination schedules & dosage tracking)  

---

### 🏠 Household-Based Tracking
- Tracks families instead of isolated individuals  
- Stores:
  - Building name  
  - Room/House number  
- Auto-generates unique IDs  

---

### 📸 Patient Identification
- Capture and store patient images  
- Improves identification accuracy  

---

### 📶 Offline-First Architecture
- Works without internet  
- Uses SQLite for local storage  
- Fast and reliable access  

---

### 🔄 Smart Sync System
- Tracks record states:
  - `pending`
  - `synced`
- Automatically syncs when internet is available  
- Prevents data loss  

---

## 🧠 System Architecture
    ┌───────────────────────┐
    │     Flutter App       │
    │  (ASHA Worker UI)     │
    └─────────┬─────────────┘
              │
    (Offline Writes)
              │
    ┌─────────▼───────────┐
    │     SQLite DB       │
    │ (Local Storage)     │
    └─────────┬───────────┘
              │
    (Sync Trigger)
              │
    ┌─────────▼────────────┐
    │   Sync Manager       │
    │ (Queue + Retry)      │
    └─────────┬────────────┘
              │
    (REST API)
              │
    ┌─────────▼────────────┐
    │   Spring Boot API    │
    └─────────┬────────────┘
              │
    ┌─────────▼────────────┐
    │   Remote Database    │
    └──────────────────────┘

    
---

## 🛠️ Tech Stack

| Layer        | Technology |
|-------------|-----------|
| Frontend     | Flutter (Dart) |
| Backend      | Spring Boot |
| Local DB     | SQLite |
| API          | REST APIs |
| Architecture | Offline-first |

---

## ⚙️ Core Concepts

- Offline-first system design  
- Eventual consistency  
- Sync state management (`pending/synced`)  
- Mobile database handling  
- Real-world healthcare use case  

---

## 📱 App Workflow

1. ASHA worker enters patient data  
2. Data is saved locally (SQLite)  
3. Record marked as `pending`  
4. Sync service checks connectivity  
5. When online:
   - Data syncs to backend  
   - Status becomes `synced`  

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK  
- Java (JDK 17+)  
- Android Studio / VS Code  

---

### Installation

```bash
# Clone the repository
git clone https://github.com/Rahul2-5/AshaSathi.git

# Navigate to project
cd AshaSathi

# Install dependencies
flutter pub get

# Run the app
flutter run

📂 Project Structure
AshaSathi/
│── lib/
│   ├── screens/
│   ├── models/
│   ├── services/
│   ├── database/
│── backend/
│── assets/
│── pubspec.yaml

🔒 Project Status

🚧 Actively under development
This is a personal project focused on:

-Improving reliability
-Enhancing UI/UX
-Expanding healthcare features
-Preparing for real-world deployment

🔮 Future Roadmap
🤖 AI-based health insights


👨‍💻 Author

Rahul Temkar
GitHub: https://github.com/Rahul2-5

⭐ Final Note

This project demonstrates real-world system design by solving healthcare challenges with an offline-first approach.
