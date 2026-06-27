# 🌿 GEMS — Green Environment Maintenance System

A professional Flutter Web application for monitoring and managing the green environment
of a Nigerian university — faculty by faculty.

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0.0 or higher) — https://docs.flutter.dev/get-started/install
- Chrome browser (for running Flutter Web)

### Setup Steps

1. **Open this folder in VS Code**
   ```
   Right-click the `gems` folder → "Open with Code"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run in Chrome**
   ```bash
   flutter run -d chrome
   ```

4. **Build for production**
   ```bash
   flutter build web
   ```

---

## 📱 Screens & Features

| Screen | Description |
|--------|-------------|
| **Login** | Animated login with floating leaves, role selector, parallax mouse effect |
| **Dashboard** | Campus-wide overview with GHI score, alerts, trend charts, faculty cards |
| **Faculties** | Full list view of all 4 faculties with scores and hazard levels |
| **Faculty Detail** | Deep dive: Overview, Vegetation pie chart, Maintenance tasks |
| **Tasks** | All maintenance tasks across faculties with filters |
| **Reports** | Bar charts, pie charts, vegetation breakdown analytics |

---

## 🏫 Faculty Profiles

| Faculty | Score | Status |
|---------|-------|--------|
| Natural & Applied Sciences | 22/100 | 🔴 Critical |
| Environmental Science | 78/100 | 🟢 Good (Benchmark) |
| Engineering | 28/100 | 🔴 Critical + Fire Risk |
| Medical Science | 51/100 | 🟡 Moderate |

---

## 🎨 Design

- **Colors**: University green (#1B5E20) & white
- **Typography**: Playfair Display (headings) + Poppins (body)
- **Animations**: Flutter Animate, hover effects, parallax, animated score rings
- **Charts**: fl_chart (line, bar, pie charts)

---

## 📦 Key Dependencies

```yaml
flutter_animate: ^4.5.0    # Smooth animations
fl_chart: ^0.68.0          # Beautiful charts
google_fonts: ^6.2.1       # Playfair Display + Poppins
percent_indicator: ^4.2.3  # Progress indicators
```

---

## 🗂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme/
│   └── gems_theme.dart          # Colors, typography, shadows
├── models/
│   └── app_data.dart            # Faculty data, tasks, reports
├── screens/
│   ├── login_screen.dart        # Animated login page
│   ├── dashboard_screen.dart    # Main dashboard + sub-pages
│   └── faculty_detail_screen.dart # Faculty deep-dive
└── widgets/
    ├── sidebar.dart             # Collapsible nav sidebar
    ├── faculty_card.dart        # Faculty grid card
    ├── stat_card.dart           # KPI stat cards
    └── animated_score_ring.dart # Animated GHI ring
```

---

Built with 💚 for sustainable university campuses in Nigeria.

 
