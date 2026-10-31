//
//  WorkoutText.swift
//  Actifit
//
//  Workout Wizard copy under Android's keys, so translations are shared through
//  ci_scripts/import_android_strings.py. English is the fallback.
//

import Foundation

enum WorkoutText {
    static var screenTitle: String { return Copy.text("workout_planning", "Workout Planning") }
    static var savedWorkouts: String { return Copy.text("saved_workouts", "Saved Workouts") }
    static var noSavedWorkouts: String { return Copy.text("no_saved_workouts_yet", "No saved workouts yet.") }
    static var retryLoading: String { return Copy.text("retry_loading_workouts", "Retry Loading Workouts") }
    static var generateNew: String { return Copy.text("generate_new_workout", "Generate New Workout") }
    static var workoutName: String { return Copy.text("workout_name", "Workout Name:") }
    static var workoutNameHint: String { return Copy.text("enter_a_name_for_your_workout", "Enter a name for your workout") }
    static var fitnessGoal: String { return Copy.text("fitness_goal", "Fitness Goal:") }
    static var experienceLevel: String { return Copy.text("experience_level", "Experience Level:") }
    static var weeklyTime: String { return Copy.text("weekly_time", "Weekly Time:") }
    static var frequency: String { return Copy.text("workout_frequency", "Workout Frequency:") }
    static var style: String { return Copy.text("preferred_workout_style", "Preferred Workout Style:") }
    static var equipment: String { return Copy.text("equipment", "Equipment:") }
    static var limitations: String { return Copy.text("physical_limitations", "Physical Limitations:") }
    static var otherLimitationsHint: String { return "Describe your limitations" }
    static var generate: String { return Copy.text("generate_workout_plan", "Generate Workout Plan") }
    static var regenerateFree: String { return Copy.text("regenerate_workout_free", "REGENERATE WORKOUT (FREE)") }
    static var overview: String { return Copy.text("workout_plan_overview", "Workout Plan Overview") }
    static var exercises: String { return Copy.text("exercises", "Exercises") }
    static var browseExercises: String { return Copy.text("navigate_to_exercise_search", "Browse All Exercises") }
    static var nameRequired: String { return Copy.text("prompt_enter_workout_name", "Please enter a name for your workout.") }
    static var planSaved: String { return Copy.text("success_workout_plan_saved", "Workout plan saved!") }
    static var generating: String { return "Building your workout plan… this can take up to a minute." }
    static var paying: String { return "Paying the workout fee on chain…" }
    static var startWorkout: String { return Copy.text("start_workout", "START WORKOUT") }
    static var cardSubtitle: String { return "AI workout plans and 870+ exercises with pictures" }

    static func generationFailed(_ m: String) -> String {
        return Copy.text("error_workout_generation_failed", "Workout generation failed:") + " " + m
    }
    static func saveFailed(_ m: String) -> String {
        return Copy.text("error_failed_to_save_workout", "Failed to save workout:") + " " + m
    }
    static func loadFailed(_ m: String) -> String {
        return Copy.text("error_loading_workouts", "Error loading workouts:") + " " + m
    }
    static func balanceFailed(_ m: String) -> String {
        return Copy.text("error_fetching_balance", "Error fetching balance:") + " " + m
    }

    static var confirmTitle: String { return Copy.text("dialog_title_confirm_workout_generation", "Confirm Workout Generation") }
    static var confirmMessage: String {
        return Copy.text("dialog_message_confirm_workout_generation_part1", "Generating this custom workout plan costs ")
            + "\(WorkoutOptions.feeAfit)"
            + Copy.text("dialog_message_confirm_workout_generation_part2", " AFIT. Do you want to proceed and pay?")
    }
    static var proceed: String { return Copy.text("proceed", "Proceed") }
    static var cancel: String { return Copy.text("dialog_button_cancel", "Cancel") }
    static var ok: String { return Copy.text("dialog_button_ok", "OK") }
    static var insufficientTitle: String { return Copy.text("dialog_title_insufficient_afit", "Insufficient AFIT") }
    static func insufficientMessage(_ balance: Int) -> String {
        return Copy.text("dialog_message_insufficient_afit_part1", "You need ") + "\(WorkoutOptions.feeAfit)"
            + Copy.text("dialog_message_insufficient_afit_part2", " AFIT to generate a workout plan. Your current balance is ")
            + "\(balance)"
            + Copy.text("dialog_message_insufficient_afit_part3", " AFIT. Please acquire more AFIT.")
    }
    static var loginFirst: String { return Copy.text("username_missing", "Please login first") }

    static var deleteTitle: String { return Copy.text("dialog_delete_workout_title", "Confirm Deletion") }
    static func deleteMessage(_ name: String) -> String {
        return Copy.format("dialog_delete_workout_message", "Are you sure you want to delete \"%1$@\"? This action cannot be undone.", name)
    }
    static var delete: String { return Copy.text("dialog_delete_workout_positive", "Delete") }
    static func deleted(_ name: String) -> String {
        return Copy.format("toast_workout_deleted_success", "Workout \"%1$@\" deleted successfully.", name)
    }
    static func deleteFailed(_ m: String) -> String {
        return Copy.format("toast_workout_deleted_failure", "Failed to delete workout: %1$@", m)
    }
    static var edit: String { return Copy.text("edit_workout_button_description", "Edit Workout") }

    // Exercise search
    static var searchTitle: String { return Copy.text("exercise_search_title", "Search Exercises") }
    static var searchHint: String { return Copy.text("search_hint", "Search by exercise name...") }
    static var filterLevel: String { return Copy.text("filter_by_level", "Level:") }
    static var filterEquipment: String { return Copy.text("filter_by_equipment", "Equipment:") }
    static var filterCategory: String { return Copy.text("filter_by_category", "Category:") }
    static var filterMuscle: String { return Copy.text("filter_by_primary_muscle", "Primary Muscle:") }
    static var filterAll: String { return Copy.text("filter_none", "All") }
    static var noExercisesFound: String { return Copy.text("no_exercises_found", "No exercises found matching your criteria.") }
    static var saveWorkout: String { return Copy.text("action_save_workout", "Save Workout") }
    static var newWorkoutTitle: String { return Copy.text("dialog_new_workout_title", "Save New Workout Plan") }
    static var titleHint: String { return Copy.text("hint_workout_title", "Workout Title") }
    static var descriptionHint: String { return Copy.text("hint_workout_description", "Description (Optional)") }
    static var enterTitle: String { return Copy.text("toast_enter_workout_title", "Please enter a workout title.") }
    static var noDescription: String { return "No description provided." }
    static var noExplanation: String { return "No explanation provided." }
    static func saved(_ name: String) -> String {
        return Copy.format("toast_workout_save_success", "Workout \"%1$@\" saved successfully!", name)
    }
    static func selectedDone(_ n: Int) -> String {
        return String(format: Copy.text("selected_exercises_done", "Done (%1$ld)"), n)
    }

    // Edit
    static var editTitle: String { return Copy.text("edit_workout_title", "Edit Workout Plan") }
    static var nameField: String { return Copy.text("edit_workout_name_hint", "Workout Name") }
    static var descriptionField: String { return Copy.text("edit_workout_description_hint", "Description") }
    static var explanationField: String { return Copy.text("edit_workout_explanation_hint", "Explanation") }
    static var currentExercises: String { return Copy.text("current_exercises", "Current Exercises") }
    static var addExercises: String { return Copy.text("add_exercises", "Add Exercises") }
    static var noExercisesInWorkout: String { return Copy.text("no_exercises_in_workout", "No exercises in this workout.") }
    static var saveChanges: String { return Copy.text("save_changes", "Save Changes") }
    static func updated(_ name: String) -> String {
        return Copy.format("toast_workout_updated_success", "Workout \"%1$@\" updated successfully!", name)
    }
    static func updateFailed(_ m: String) -> String {
        return Copy.format("toast_workout_updated_failure", "Failed to update workout: %1$@", m)
    }
    static var removeTitle: String { return Copy.text("confirm_remove_exercise_title", "Remove Exercise?") }
    static func removeMessage(_ name: String) -> String {
        return Copy.format("confirm_remove_exercise_message", "Are you sure you want to remove \"%1$@\" from this workout?", name)
    }
    static var remove: String { return Copy.text("dialog_button_remove", "Remove") }

    // Detail
    static var primaryMuscles: String { return "Primary Muscles" }
    static var secondaryMuscles: String { return "Secondary Muscles" }
    static var instructions: String { return "Instructions" }
    static var days: String { return "Days" }

    // Errors
    static var badResponse: String { return Copy.text("error_invalid_response_format", "Invalid response format from server.") }
    static var badPlan: String { return "The AI answered in an unexpected format. Tap Generate again; you won't be charged twice." }
    static var blocked: String { return "Your request couldn't be processed because it may violate content guidelines." }
    static func serverError(_ status: Int) -> String { return "Server error (\(status)). Please try again." }
}
