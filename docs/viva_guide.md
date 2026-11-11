# UniTrack Viva Guide

## One-minute explanation

UniTrack is a Student Academic Performance and Intelligence System. Faculty maintain student records, marks, attendance and interventions in a Bootstrap website. Students use a Flutter Web portal to view their profile. Both clients call the same Node.js and Express REST API, which stores data in MySQL. The system uses a transparent rule-based risk indicator rather than machine learning.

## Likely questions and answers

### Why did you use a REST API?

It provides one shared contract for the faculty website and Flutter Web client. GET reads data, POST creates records and PUT updates records. This prevents the two frontends from maintaining separate datasets.

### How is database integrity maintained?

Primary keys identify records, unique constraints protect roll numbers and emails, foreign keys connect students, subjects and faculty, and CHECK constraints validate marks, semester and attendance values.

### How did you avoid incorrect aggregate results?

The summary view aggregates assessments by student in one subquery and attendance by student in another subquery before joining both results to Students. Directly joining both one-to-many tables could multiply rows and distort averages.

### How is risk calculated?

The view computes average marks and average attendance, then applies the documented thresholds. It is a rule-based indicator and is not an ML prediction.

### How do both frontends share changes?

A faculty write is sent to Express and saved in MySQL. Flutter later requests the same student's profile from Express, so it reads the updated database record.

### Why is Flutter Web documented separately from Docker?

The Node.js API and MySQL are containerized in Docker Compose. Flutter Web is a client build that is run with the Flutter SDK and points to the API using `API_BASE_URL`. This keeps the student frontend simple to develop and deploy independently.

### What does Docker demonstrate?

The Dockerfile packages the Express service. Compose starts MySQL, mounts schema and seed scripts for first initialization, waits for database health, and starts the API with the internal service name `db`.

### What are the limitations?

The prototype has simplified demo access, synthetic records, no production authentication or role authorization, and Power BI refresh is not automatic in Import mode.

### What is the future scope?

Add secure authentication, role-based authorization, notifications, richer subject analytics, automated attendance ingestion, institutional deployment and an optional ML model after collecting consented historical data.

## Demo order

1. Open the faculty dashboard and show the KPIs.
2. Add or select a student and open the profile.
3. Record assessment marks and attendance.
4. Open the same ID in Flutter Web and show the updated profile.
5. Explain the High/Medium/Low rule.
6. Create an intervention and show its status.
7. Show the schema, summary view, API health response and Docker Compose file.
8. Finish with Power BI architecture and the documented limitation that Desktop authoring requires Windows.
