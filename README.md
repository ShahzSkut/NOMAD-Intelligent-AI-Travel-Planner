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
