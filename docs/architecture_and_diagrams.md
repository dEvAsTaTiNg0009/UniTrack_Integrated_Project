# UniTrack Architecture and Diagrams

## Problem statement

Academic records are often spread across marksheets, attendance files and faculty notes. UniTrack gives faculty one place to maintain these records and gives students a consistent view of their own academic profile.

## Objectives and scope

- Store students, faculty, subjects, assessments, attendance and interventions in MySQL.
- Expose the records through a simple Express REST API.
- Provide a Bootstrap faculty dashboard for academic operations.
- Provide a Flutter Web student portal using the same API.
- Apply transparent rule-based academic risk classification.
- Prepare a reproducible Docker and Power BI integration path.

The prototype uses synthetic data and simplified demo access. It does not implement production authentication, institutional authorization or machine-learning prediction.

## System architecture

```mermaid
flowchart LR
    F[Faculty Bootstrap Website] -->|HTTP REST requests| API[Node.js + Express API]
    S[Flutter Web Student Portal] -->|HTTP REST requests| API
    API -->|mysql2 connection pool| DB[(MySQL 8 Database)]
    DB -->|Import or DirectQuery refresh| P[Power BI Desktop]
    D[Docker Compose] -. runs .-> API
    D -. runs .-> DB
```

## Request workflow

```mermaid
sequenceDiagram
    participant Faculty
    participant Flutter
    participant Express
    participant MySQL

    Faculty->>Express: POST student or assessment
    Express->>MySQL: Parameterized INSERT/UPDATE
    MySQL-->>Express: Commit result
    Express-->>Faculty: HTTP status and JSON
    Flutter->>Express: GET /api/students/:id
    Express->>MySQL: Summary view + detail queries
    MySQL-->>Express: Profile, marks, attendance
    Express-->>Flutter: Shared current data
```

## ER diagram

```mermaid
erDiagram
    FACULTY ||--o{ SUBJECTS : teaches
    STUDENTS ||--o{ ASSESSMENTS : receives
    SUBJECTS ||--o{ ASSESSMENTS : contains
    STUDENTS ||--o{ ATTENDANCE : has
    SUBJECTS ||--o{ ATTENDANCE : measures
    STUDENTS ||--o{ INTERVENTIONS : receives

    FACULTY {
        varchar faculty_id PK
        varchar faculty_name
        varchar department
    }
    STUDENTS {
        varchar student_id PK
        varchar roll_no UK
        varchar student_name
        varchar email UK
        varchar program
        tinyint semester
        char section
        year admission_year
    }
    SUBJECTS {
        varchar subject_id PK
        varchar subject_name
        varchar faculty_id FK
        tinyint credits
    }
    ASSESSMENTS {
        varchar assessment_id PK
        varchar student_id FK
        varchar subject_id FK
        varchar assessment_type
        decimal marks_obtained
        decimal max_marks
        date assessment_date
    }
    ATTENDANCE {
        varchar attendance_id PK
        varchar student_id FK
        varchar subject_id FK
        decimal attendance_percentage
        int classes_held
        int classes_attended
        date as_of_date
    }
    INTERVENTIONS {
        varchar intervention_id PK
        varchar student_id FK
        varchar intervention_type
        enum intervention_status
        date intervention_date
        varchar reason
    }
```

## Data-flow diagram (DFD Level 1)

```mermaid
flowchart TD
    Faculty([Faculty]) --> P1[1. Manage academic records]
    Student([Student]) --> P2[2. View academic profile]
    P1 -->|REST requests| P3[3. Express API]
    P2 -->|Student ID REST request| P3
    P3 --> D1[(D1 MySQL records)]
    D1 --> V1[Academic summary view]
    V1 --> P3
    P3 -->|Risk, marks, attendance, interventions| Faculty
    P3 -->|Profile and history JSON| Student
    D1 --> P4[4. Analytics data source]
    P4 --> PowerBI([Power BI dashboard])
```

## Risk rules

The database view calculates risk after separate per-student aggregations, preventing accidental multiplication from joining multiple one-to-many tables:

- High: average marks below 40% OR average attendance below 65%.
- Medium: average marks below 55% OR average attendance below 75%.
- Low: neither threshold is crossed.
