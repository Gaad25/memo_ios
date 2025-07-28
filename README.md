# Memo: Study Session Tracker

## Overview

Memo helps users monitor and optimize their study sessions through a simple, intuitive interface equipped with productivity-focused features. Available for Android and iOS.


## Application Structure and Flow

### Login Screen
- Email and password entry
- Quick login option via Google
- Password recovery

### Main Dashboard
After logging in, users are automatically directed to the main dashboard, which includes:

#### Performance Summary
- Total study time (hours/minutes)
- Currently active goals
- Recent progress (latest study sessions)

### Subjects Tab
#### Custom Subjects Registration
- Subject name
- Category (e.g., Humanities, Exact Sciences, Biological Sciences)
- Custom color selection

#### Start Study Session
- Select a registered subject
- Record study duration (automatic timer or manual entry)
- Record the number of questions attempted
- Record the number of correct answers
- Add session notes

### Sessions Management
- View all study sessions
- Filter by subject
- Sort by date, duration, or performance
- Delete sessions

### Performance Statistics
Upon completing a study session, the application automatically updates statistics displaying:

#### Performance Graphs by Subject
- Average study time
- Total number of questions attempted
- Accuracy rate (%)
- Study time distribution by day of week

### Study Goals
Users can create and track specific goals, such as:
- Defining the goal duration (e.g., 30 hours)
- Specifying the subject associated with the goal
- Setting a deadline for completion
- Real-time visual tracking of progress on the main dashboard

## Database Schema

### users
- id: uuid (primary key)
- email: text (unique)
- password: text (hashed)
- created_at: timestamp
- updated_at: timestamp
- name: text
- avatar_url: text
- preferences: jsonb

### categories
- id: uuid (primary key)
- name: text
- created_at: timestamp

### subjects
- id: uuid (primary key)
- name: text
- category_id: uuid (foreign key to categories.id)
- user_id: uuid (foreign key to users.id)
- created_at: timestamp
- updated_at: timestamp
- color: text
- icon: text

### study_sessions
- id: uuid (primary key)
- subject_id: uuid (foreign key to subjects.id)
- user_id: uuid (foreign key to users.id)
- start_time: timestamp
- end_time: timestamp
- duration_minutes: integer
- questions_attempted: integer
- questions_correct: integer
- notes: text
- created_at: timestamp
- updated_at: timestamp

### goals
- id: uuid (primary key)
- user_id: uuid (foreign key to users.id)
- subject_id: uuid (foreign key to subjects.id)
- title: text
- description: text
- target_hours: float
- start_date: timestamp
- end_date: timestamp
- completed: boolean
- created_at: timestamp
- updated_at: timestamp

## Application Folder Structure

```
memo/
├── app/                      # Main application code using Expo Router
│   ├── auth/                 # Authentication routes
│   │   ├── login.tsx
│   │   ├── register.tsx
│   │   └── forgot-password.tsx
│   ├── dashboard.tsx         # Main dashboard
│   ├── subjects/             # Subject management
│   │   ├── index.tsx         # List subjects
│   │   ├── [id].tsx          # View subject details
│   │   └── create.tsx        # Create new subject
│   ├── sessions/             # Session management
│   │   ├── index.tsx         # List sessions
│   │   ├── [id].tsx          # View session details
│   │   └── create.tsx        # Start new session
│   ├── stats/                # Statistics
│   │   └── index.tsx         # Stats overview
│   ├── _layout.tsx           # Root layout
│   └── index.tsx             # Entry point
├── components/               # Reusable components
│   ├── auth/                 # Auth-related components
│   ├── subjects/             # Subject-related components
│   ├── sessions/             # Session-related components
│   ├── stats/                # Statistics components
│   └── ui/                   # UI components
├── constants/                # App constants
├── context/                  # React context providers
├── hooks/                    # Custom hooks
├── lib/                      # Library code
│   └── supabase.ts           # Supabase client
├── services/                 # Service layer
│   ├── auth.ts
│   ├── subjects.ts
│   ├── sessions.ts
│   └── stats.ts
├── types/                    # TypeScript type definitions
├── utils/                    # Utility functions
```

## Implementation Progress
- ⬜ Authentication screens (login, register, forgot password)
- ⬜ Dashboard
- ⬜ Subjects management (list, create, details)
- ⬜ Sessions management (list, create, details)
- ⬜ Statistics overview
- ⬜ Study goals (list, create, details, progress tracking)
- ⬜ Reminders
- ⬜ Backend integration with Supabase
- ⬜ AI-powered insights from DeepSeek
