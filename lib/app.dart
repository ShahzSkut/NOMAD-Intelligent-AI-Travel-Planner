import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/core/services/supabase_service.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/data/repositories/activity_repository.dart';
import 'package:nomad_mobile/data/repositories/budget_repository.dart';
import 'package:nomad_mobile/data/repositories/checklist_repository.dart';
import 'package:nomad_mobile/data/repositories/trip_repository.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_bloc.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_event.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_bloc.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_event.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_state.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_event.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_bloc.dart';
import 'package:nomad_mobile/presentation/pages/auth/login_page.dart';
import 'package:nomad_mobile/presentation/pages/auth/register_page.dart';
import 'package:nomad_mobile/presentation/pages/auth/forgot_password.dart';
import 'package:nomad_mobile/presentation/pages/auth/update_password.dart';
import 'package:nomad_mobile/presentation/pages/home/trip_dashboard_page.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_bloc.dart';
import 'package:nomad_mobile/presentation/pages/trip/trip_edit_page.dart';
import 'package:nomad_mobile/presentation/pages/trip/trip_overview_page.dart';
import 'package:nomad_mobile/presentation/pages/trip/trip_planning_page.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    // Sets up repositories for dependency injection.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SupabaseService>.value(value: supabaseService),
        RepositoryProvider<TripRepository>(
          create: (_) => TripRepository(supabaseService),
        ),

        RepositoryProvider<ChecklistRepository>(
          create: (_) => ChecklistRepository(supabaseService),
        ),
        RepositoryProvider<ActivityRepository>(
          create: (_) => ActivityRepository(supabaseService),
        ),
        RepositoryProvider<BudgetRepository>(
          create: (_) => BudgetRepository(supabaseService),
        ),
      ],
      // Sets up BLoCs for state management.
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(supabaseService),
          ),
          BlocProvider<TripBloc>(
            create: (context) => TripBloc(context.read<TripRepository>()),
          ),
          BlocProvider<ChecklistBloc>(
            create: (context) =>
                ChecklistBloc(context.read<ChecklistRepository>()),
          ),
          BlocProvider<ActivityBloc>(
            create: (context) =>
                ActivityBloc(context.read<ActivityRepository>()),
          ),
          BlocProvider<BudgetBloc>(
            create: (context) => BudgetBloc(context.read<BudgetRepository>()),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primaryBlue,
            scaffoldBackgroundColor: AppColors.backgroundColor,
            fontFamily: 'Montserrat',
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.cardColor,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.primaryText),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
          home: const AuthWrapper(),
          routes: {
            LoginPage.routeName: (_) => const LoginPage(),
            RegisterPage.routeName: (_) => const RegisterPage(),
            TripDashboardPage.routeName: (_) => const TripDashboardPage(),
            TripPlanningPage.routeName: (_) => const TripPlanningPage(),
            ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),
            UpdatePasswordPage.routeName: (_) => const UpdatePasswordPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/trip-overview') {
              final trip = settings.arguments as Trip;
              return MaterialPageRoute(
                builder: (routeContext) {
                  routeContext.read<ActivityBloc>().add(
                    LoadActivities(trip.tripId, trip.startDate),
                  );
                  routeContext.read<ChecklistBloc>().add(
                    LoadChecklist(trip.tripId),
                  );

                  return TripOverviewPage(trip: trip);
                },
              );
            }
            if (settings.name == '/trip-edit') {
              return MaterialPageRoute(
                builder: (_) => const TripEditPage(),
                settings: settings,
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<sb.AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Check for an existing session on app start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthCheckRequested());
    });

    _authSubscription = sb.Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final session = data.session;
          final event = data.event;

          if (event == sb.AuthChangeEvent.passwordRecovery) {
            // 1. Clear any current stack to ensure we are on a fresh page
            Navigator.of(context).pushNamedAndRemoveUntil(
              UpdatePasswordPage.routeName,
              (route) => false,
            );
          } else if (event == sb.AuthChangeEvent.signedIn && session != null) {
            // 2. Make sure your Bloc knows the user is now logged in
            context.read<AuthBloc>().add(AuthCheckRequested());
          }
        });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Show a loader during the initial auth check.
        if (authState is AuthInitial || authState is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        return const TripDashboardPage();
      },
    );
  }
}
