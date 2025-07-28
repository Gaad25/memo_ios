# Memo iOS App

## Overview
Memo is a study tracking app focused on vestibulandos and students preparing for the ENEM exam. The app helps learners remember what they study by combining a timer-based session tracker with spaced repetition and a simple gamified system of points and streaks.

## Core Features
- **User Authentication** – registration and login managed through Supabase Auth. Credentials can be saved for automatic login via `SessionManager`.
- **Study Session Tracking** – start a timer for a subject, add notes and question statistics, then save the session.
- **Subject Management** – create subjects with categories and colors.
- **Study Goals** – define target hours and deadlines optionally linked to a subject.
- **Intelligent Reviews** – reviews are scheduled using spaced repetition logic and an adaptive algorithm.
- **Gamification** – earn points and streaks for each completed session or review.

## Application Architecture (Frontend)
The iOS interface is built with **SwiftUI** and follows the **MVVM** pattern.

- `HomeViewModel` is a shared singleton that holds dashboard state:

```swift
@MainActor
final class HomeViewModel: ObservableObject {
    static let shared = HomeViewModel()
    @Published var totalStudyMinutes: Int = 0
    @Published var recentStudyMinutes: Int = 0
    @Published var subjects: [Subject] = []
    @Published var goals: [StudyGoalViewData] = []
    @Published var userPoints: Int = 0
    @Published var userStreak: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private init() {}
}
```
【F:memo/Features/Home/HomeViewModel.swift†L20-L34】

- `MemoApp` loads this view model and attempts automatic login using `SessionManager` when the app starts.
- Each tab in `MainTabView` displays a feature screen (Home, Sessions, Reviews, Statistics, Settings).
- Views such as `StudySessionView` or the review flow update the shared `HomeViewModel` through the `userDidCompleteAction()` method to refresh points and streaks.

## Backend and Database
The backend relies on **Supabase** for data storage and authentication. Supabase Auth secures access with Row Level Security rules. Important tables include:
- `subjects` – user defined study subjects.
- `study_sessions` – individual study sessions with notes and question statistics.
- `goals` – target hours and deadlines tied to a subject or global.
- `reviews` – scheduled reviews for spaced repetition.
- `user_profiles` – points, streaks and last study date for each user.

A custom function `ensure_user_profile_exists` ensures each authenticated user has a corresponding row in `user_profiles` before updates occur.

### Database Schema
```
```

## How Key Features Work (End-to-End)
### Saving a New Study Session
1. The user taps **Save** in `StudySessionView`.
2. The view creates a struct with the session data and inserts it into `study_sessions`:
```swift
let sessionToInsert = InsertableSession(...)
let returnedSession: ReturnedSession = try await SupabaseManager.shared.client
    .from("study_sessions").insert(sessionToInsert, returning: .representation)
    .select("id, user_id, subject_id, start_time").single().execute().value
```
【F:memo/Features/Sessions/StudySessionView.swift†L208-L214】
3. `scheduleReviews(for:)` schedules review rows and local notifications.
4. `HomeViewModel.shared.userDidCompleteAction()` updates points and streaks then refreshes the dashboard.

### Completing a Review
1. In `ReviewsView`, the user marks a review as completed. The view model updates the `reviews` table and schedules the next review:
```swift
try await SupabaseManager.shared.client
    .from("reviews")
    .update(["status": "completed", "last_review_difficulty": difficulty.rawValue])
    .eq("id", value: detail.reviewData.id)
    .execute()
await scheduleNextReview(for: detail.reviewData, basedOn: difficulty)
await HomeViewModel.shared.userDidCompleteAction()
```
【F:memo/Features/Reviews/ReviewsViewModel.swift†L62-L73】
2. `scheduleNextReview` chooses the next interval using the difficulty and inserts a new row:
```swift
private func scheduleNextReview(for previousReview: Review, basedOn difficulty: ReviewDifficulty) async {
    let cycle = ["1d", "7d", "30d", "90d"]
    ...
    let nextReview = NewReview(
        userId: previousReview.userId,
        sessionId: previousReview.sessionId,
        subjectId: previousReview.subjectId,
        reviewDate: newReviewDate,
        reviewInterval: nextIntervalKey
    )
    try await SupabaseManager.shared.client.from("reviews").insert(nextReview).execute()
}
```
【F:memo/Features/Reviews/ReviewsViewModel.swift†L84-L129】

The shared `HomeViewModel` then refreshes the dashboard to show the updated points and streak.

---
