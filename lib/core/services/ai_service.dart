import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nomad_mobile/data/models/activity.dart';
import 'package:nomad_mobile/data/models/checklist_item.dart';
import '../../data/models/trip.dart';

// Handles interaction with the Gemini AI model for itinerary generation.
class AiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY']!;

  Future<Map<String, dynamic>> generateItinerary(
    Trip tripPreferences,
    List<Activity> currentActivities,
    List<ChecklistItem> currentChecklist, {
    String currency = 'MYR',
  }) async {
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    final lockedActivities = currentActivities
        .where(
          (e) => e.isCustom || e.status == 'Completed' || e.status == 'Ongoing',
        )
        .map(
          (e) =>
              "- Day ${e.dayNumber} at ${e.time}: ${e.name} ${e.locationName != null ? '(Location: ${e.locationName})' : ''} (STRICT: Keep this, do not change)",
        )
        .join("\n");

    final lockedChecklist = currentChecklist
        .map(
          (e) => "- ${e.item} (status: ${e.status}, is_custom: ${e.isCustom})",
        )
        .join("\n");

    String accommodationPrompt;
    if (tripPreferences.accommodationType == null ||
        tripPreferences.accommodationType!.isEmpty) {
      accommodationPrompt =
          "- PREFERRED ACCOMMODATION: None selected. Assume user is staying with friends/family. DO NOT allocate any budget for accommodation.";
    } else {
      accommodationPrompt =
          "- PREFERRED ACCOMMODATION: ${tripPreferences.accommodationType}";
    }

    String transportPrompt;
    if (tripPreferences.transportType == null ||
        tripPreferences.transportType!.isEmpty) {
      transportPrompt =
          "- PREFERRED TRANSPORT: None selected. Assume user is walking. DO NOT allocate any budget for transport unless an activity absolutely requires it (e.g., island hopping).";
    } else {
      transportPrompt =
          "- PREFERRED TRANSPORT: ${tripPreferences.transportType}";
    }

    final now = DateTime.now();
    final startDate = DateTime(
      tripPreferences.startDate.year,
      tripPreferences.startDate.month,
      tripPreferences.startDate.day,
    );
    final currentDay = now.difference(startDate).inDays + 1;
    final startDateStr =
        "${startDate.year}-${startDate.month}-${startDate.day}";

    String timeContext = "";
    if (currentDay >= 1 &&
        currentDay <= (tripPreferences.durationDays ?? 999)) {
      final hour = now.hour;
      final minute = now.minute.toString().padLeft(2, '0');
      final timeStr =
          "${hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)}:$minute ${hour >= 12 ? 'PM' : 'AM'}";

      timeContext =
          """
      REAL-TIME UPDATE:
      - It is currently Day $currentDay of the trip.
      - Current Time: $timeStr.
      - CONSTRAINT: For Day $currentDay, DO NOT suggest new activities for times that have already passed ($timeStr). Only schedule new activities for the rest of the day.
      """;
    }

    String originPrompt = "";
    if (tripPreferences.locationFrom != null &&
        tripPreferences.locationFrom!.isNotEmpty) {
      originPrompt = "- TRAVELING FROM: ${tripPreferences.locationFrom}";
    }

    final prompt =
        """
      ACT AS: A local Travel Expert for ${tripPreferences.destination} and GPS data specialist.
      LANGUAGE: Strict English.
      TARGET: Travelers visiting ${tripPreferences.destination}.
      
      TRIP PREFERENCES:
      - DESTINATION: ${tripPreferences.destination}
      $originPrompt
      - START DATE: $startDateStr
      - DURATION: ${tripPreferences.durationDays} Days
      - PURPOSES: ${tripPreferences.tripPurpose}
      - TRAVEL PACE: ${tripPreferences.travelPace}
      - TRAVELERS: ${tripPreferences.numTravelers} Pax
      ${accommodationPrompt}
      ${transportPrompt}
      - BUDGET RANGE: $currency ${tripPreferences.budgetMin} - $currency ${tripPreferences.budgetMax}
      - STRICT BUDGET RULE: The total estimated cost for all categories MUST be within the provided budget range. Do not suggest expensive luxury activities if the budget is low. The activities you suggest must align with the user's budget.
      - ACCOMMODATION BUDGET: When estimating 'accommodation' cost, do NOT use the cheapest option. Use the AVERAGE price for a comfortable, well-rated stay (best value) suitable for the user's budget.
      - TRANSPORT BUDGET: If 'TRAVELING FROM' is specified, include the estimated cost of travel (flight/bus/fuel) from the origin to the destination in the 'transport' budget.
      - BUDGET COMPLETENESS: The 'budget_estimate' JSON object MUST include all keys (total, accommodation, transport, food, activities, shopping, misc), even if their value is 0.
      $timeContext

      STRICT LOGISTICAL CHECKS:
      1. GEOGRAPHICAL CLUSTERING (CRITICAL): For multi-day trips, assign a specific district or area to each day. 
         - Example: Day 1 = Ayer Keroh area ONLY. Day 2 = Bandar Hilir area ONLY.
         - DO NOT mix locations from far-apart districts in the same day.
         - Activities within a day MUST be close to each other (short driving distance).
         - If 'TRAVELING FROM' is specified, consider the travel time for Day 1. If the distance is long, Day 1 should have fewer activities or start later.
      2. CLIMATE & SEASON: Check the climate/season for the travel date ($startDateStr). Do NOT suggest activities/places that are closed during this time (e.g., winter closures, monsoon season).
      3. OPERATING HOURS: Verify opening hours for the specific day. Do NOT suggest a time when the place is closed (e.g., suggesting 6 PM for a place that closes at 5 PM).

      STRICT ACTIVITY TYPES:
      1. NO "DEPARTURE", "TRAVEL", OR "ACCOMMODATION" ITEMS: Do NOT list "Depart from Home", "Driving to Destination", "Return to Home", "Check-in", or "Travel to Hotel" as activities. The user calculates their own travel time and accommodation arrangements.

      STRICT RULES FOR 'location_name':
      1. FOOD/DINING: DO NOT suggest specific restaurants, cafes, or eateries. Instead, suggest a general area, street, or food hub known for food.
         - Bad Example: "Restoran Ali Maju" (Might not exist).
         - Good Example: "Jalan Alor Food Street" or "SS15 Bubble Tea Street".
      
      2. PHYSICAL ATTRACTIONS (Gardens, Malls, Parks, Landmarks): You MUST provide the FULL SPECIFIC ADDRESS or PRECISE LANDMARK NAME including the street/town. It must be detailed enough to be pasted directly into Waze or Google Maps. 
         - Good Example: "Perdana Botanical Garden, Jalan Kebun Bunga, Tasik Perdana"
         - Good Example: "A Famosa, Jalan Kota, Bandar Hilir, Melaka"
         - Bad Example: "The Garden" or "The Mall"

      3. THEME & PACE: Align activities with ${tripPreferences.tripPurpose} and the budget.
         - 'Relaxed': Target 2-3 activities per day.
         - 'Balanced': Target 3-4 activities per day.
         - 'Packed': Target 5+ activities per day.
         - CRITICAL: If the "EXISTING ACTIVITIES" list provided below already meets or exceeds this target for a specific day, DO NOT add any more activities for that day. Just keep the existing ones.

      4. FULL ITINERARY: You MUST generate a complete itinerary for ALL ${tripPreferences.durationDays} days. Do not skip any days.

      STRICT PRESERVATION RULES:
      1. EXISTING ACTIVITIES:
      $lockedActivities
      The user has already completed the above or specifically added them. You MUST include these in the final 'activities' list exactly as provided. Design the rest of the trip around these timings.

      2. EXISTING CHECKLIST:
      $lockedChecklist
      Keep all items marked 'COMPLETED' or 'Custom' in the final checklist. Do not remove them.

      RULES FOR CHECKLIST GENERATION:
      - YOU MUST include all items from the 'EXISTING CHECKLIST' above exactly as they are.
      - The final checklist should ideally have around 6 items.
      - Checklist item names MUST be short (around 4 words max).
      - If 'EXISTING CHECKLIST' already has 6 or more items, DO NOT add any new items unless it is a critical item like "Book ${tripPreferences.accommodationType}", "Book ${tripPreferences.transportType}", or "Check Passport".
      - If 'EXISTING CHECKLIST' has fewer than 6 items, you can add new logical items (like "Pack clothes", "Top up Toll Card") to bring the total to 6.
      - All new items you generate must have 'status' set to false.
      - Keep the status of existing items as they are.

      OUTPUT FORMAT (Valid JSON only):
      {
        "trip_name": "A creative and short name for this trip (e.g., 'Melaka Heritage Adventure')",
        "activities": [
          {
            "day_number": 1, 
            "name": "Activity Name", 
            "location_name": "Full Landmark Name + Street + Area (Searchable in Waze)", 
            "time": "09:00 AM", 
            "is_custom": false
          }
        ],
        "budget_estimate": {"total": 0.0, "accommodation": 0.0, "transport": 0.0, "food": 0.0, "activities": 0.0, "shopping": 0.0, "misc": 0.0},
        "checklist": [{"item": "Short Name", "category": "Logistics", "status": false, "is_custom": false}]
      }
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception("AI returned empty text");
      }

      String rawText = response.text!.trim();
      if (rawText.startsWith('```')) {
        rawText = rawText.replaceAll(RegExp(r'^```json|```$'), '').trim();
      }

      int startIndex = rawText.indexOf('{');
      int endIndex = rawText.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) {
        print("Raw AI Output: $rawText");
        throw Exception("No JSON found in response");
      }

      String cleanJson = rawText.substring(startIndex, endIndex + 1);
      return jsonDecode(cleanJson);
    } catch (e) {
      print("Detailed AI Error: $e");
      throw Exception("Generation failed: $e");
    }
  }
}
