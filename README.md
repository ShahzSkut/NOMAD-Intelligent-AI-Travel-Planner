# NOMAD — Intelligent AI Travel Planner

**Nomad: Intelligent Travel Planner** is a cross-platform mobile application built with Flutter, designed to eliminate the complexity of trip planning. Powered by generative AI and location services, Nomad automatically constructs customized day-by-day travel itineraries, optimizes multi-stop routes, and securely syncs user preferences to cloud storage.

---

## ✨ Key Features

- **Generative AI Itineraries:** Instantly generates tailored travel schedules based on chosen destinations, trip duration, and custom preferences.
- **Interactive Maps & Route Optimization:** Built-in Google Maps SDK integration for smooth location visualization, place details, and seamless route navigation.
- **Cloud Synchronization & Persistence:** Integrated with Supabase (PostgreSQL) to handle user authentication, saved travel plans, and real-time data sync.
- **Smart Local Caching:** Fast, offline-first state handling and dynamic state updates managed through Flutter BLoC.

---

## 🛠️ Technology Stack

- **Framework:** Flutter (Dart)
- **State Management:** `flutter_bloc`
- **AI Engine:** Google Gemini API
- **Mapping & Location:** Google Maps SDK, Google Places & Directions APIs
- **Database & Auth:** Supabase (PostgreSQL Cloud Backend)
- **Environment Management:** `flutter_dotenv`

---

## 🚀 Environment Setup & API Configuration

Because sensitive API keys and database credentials are excluded from version control, you must create your own `.env` file in the root directory before running the app.

### 1. Create a `.env` File
In the root directory of the project, create a file named `.env`:

```env
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### 2. How to Obtain Required Keys

- **Google Gemini API Key:**
  1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey).
  2. Sign in and click **Create API Key**.
  3. Copy the key and assign it to `GEMINI_API_KEY`.

- **Google Maps API Key:**
  1. Open the [Google Cloud Console](https://console.cloud.google.com/).
  2. Enable **Maps SDK for Android**, **Places API**, and **Directions API**.
  3. Navigate to **Credentials**, generate an API Key, and assign it to `GOOGLE_MAPS_API_KEY`.

- **Supabase Credentials:**
  1. Log in to your [Supabase Dashboard](https://supabase.com/).
  2. Go to **Project Settings** $\rightarrow$ **API**.
  3. Copy your **Project URL** (`SUPABASE_URL`) and **anon/public Key** (`SUPABASE_ANON_KEY`).

## 📸 App Previews

[Pitch Video](https://youtu.be/F0IFK5uCo7A)

[App Walkthrough](https://youtu.be/P7Zq44j0iOU)

<img width="591" height="1280" alt="WhatsApp Image 2026-10-27 at 19 08 15" src="https://github.com/user-attachments/assets/b87b7409-ac28-4493-892a-732ecf917078" />
<img width="591" height="1280" alt="WhatsApp Image 2026-10-27 at 19 08 14" src="https://github.com/user-attachments/assets/39c59c2f-2c3f-4449-b9c1-d0319ff41329" /><img width="591" height="1280" alt="WhatsApp Image 2026-10-27 at 19 08 15 (2)" src="https://github.com/user-attachments/assets/c012433c-8dca-4b83-8c84-17bcfb4e0f2e" />
<img width="591" height="1280" alt="WhatsApp Image 2026-10-27 at 19 08 15 (1)" src="https://github.com/user-attachments/assets/99927282-5035-4faf-95f4-e1bfddb3c483" />



# nomad_mobile

lib/
│
├── main.dart
├── app.dart                          
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── date_utils.dart          
│   │   ├── network_utils.dart   
│   │   └── status_helper.dart
│   │
│   ├── services/
│   │   ├── supabase_service.dart      
│   │   ├── google_api_service.dart   
│   │   └── ai_service.dart           
│   │
│   └── widgets/                       
│       ├── confirmation_dialog.dart
│       ├── primary_button.dart│
├── data/
│   ├── models/
│   │   ├── user.dart
│   │   ├── trip.dart
│   │   ├── activity.dart
│   │   ├── checklist_item.dart
│   │   └── budget.dart
│   │
│   └── repositories/
│       ├── trip_repository.dart
│       ├── activity_repository.dart
│       ├── checklist_repository.dart
│       └── budget_repository.dart
│
├── logic/
│   └── blocs/
│      ├── auth_bloc/
│      │   ├── auth_bloc.dart
│      │   ├── auth_event.dart
│      │   └── auth_state.dart
│      │
│      ├── checklist_bloc/
│      │   ├── checklist_bloc.dart
│      │   ├── checklist_event.dart
│      │   └── checklist_state.dart
│      │
│      ├── budget_bloc/
│      │   ├── budget_bloc.dart
│      │   ├── budget_event.dart
│      │   └── budget_state.dart
│      │
│      ├── activity_bloc/
│      │   ├── activity_bloc.dart
│      │   ├── activity_event.dart
│      │   └── activity_state.dart
│      │
│      └── trip_bloc/
│          ├── trip_bloc.dart
│          ├── trip_event.dart
│          └── trip_state.dart
│
└── presentation/
    ├── pages/
    │   ├── auth/
    │   │   ├── login_page.dart
    │   │   └── register_page.dart
    │   │
    │   ├── home/
    │   │   ├── trip_dashboard_page.dart      
    │   │   ├── widgets/                     
    │   │   │   ├── search_filter_section.dart
    │   │   │   └── trip_content_section.dart
    │   │   │
    │   │   └── components/                   
    │   │       ├── trip_card_widget.dart
    │   │       └── empty_state_widget.dart
    │   │
    │   └── trip/
    │       ├── trip_planning_page.dart
    │       ├── trip_overview_page.dart
    │       ├── trip_edit_page.dar
    │       ├── itinerary_section.dart
    │       ├── checklist_section.dart
    │       ├── budget_section.dart
    │       └── map_section.dart
    │
    └── components/                         
        └── input_field.dart
