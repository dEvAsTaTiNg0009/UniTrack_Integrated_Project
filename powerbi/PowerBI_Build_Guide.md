# UniTrack Power BI — final integration stage

## Recommended pages

### Page 1: Academic Overview
- KPI cards: Total Students, Average Marks %, Average Attendance %, At-Risk Students
- Bar chart: Average Marks % by Subject
- Donut: Student count by Risk Level
- Column chart: Average Marks by Assessment Type
- Slicers: Semester, Section, Subject

### Page 2: Student Risk & Performance
- Table: Student, Roll No, Average Marks, Attendance, Risk Level
- Scatter: Average Attendance vs Average Marks
- Bar: At-risk count by section
- Slicers: Risk Level, Section

### Page 3: Attendance & Interventions
- Bar: Average Attendance by Subject
- Donut: Intervention Status
- Bar: Intervention Count by Type
- Table: Student, Intervention Type, Status, Reason

## Data connection — use live MySQL database
Power BI Desktop → Get Data → MySQL database:
- Server: localhost:3306
- Database: unitrack
- Select Import mode for easiest setup.
- Select Students, Faculty, Subjects, Assessments, Attendance, Interventions and vw_student_academic_summary.
- If the MySQL connector/driver is missing, install the MySQL Connector/NET compatible with your Power BI Desktop version.

## Relationships
- Students[student_id] 1:* Assessments[student_id]
- Students[student_id] 1:* Attendance[student_id]
- Students[student_id] 1:* Interventions[student_id]
- Subjects[subject_id] 1:* Assessments[subject_id]
- Subjects[subject_id] 1:* Attendance[subject_id]
- Faculty[faculty_id] 1:* Subjects[faculty_id]

Do not relate the student summary view to all fact tables unless you understand the resulting filter paths. Prefer Students as the central dimension.

## Measures
Use the accompanying DAX_Measures.txt. Create measures individually from Modeling → New measure.

## Refresh demonstration
1. Keep Power BI connected to the same MySQL database.
2. Add or update a student/assessment in the faculty portal.
3. Refresh the Power BI report.
4. Show the changed KPI/chart.

Refresh is not guaranteed to be instantaneous. Import mode requires refresh. DirectQuery can be considered later if the environment supports it.

## Synthetic data
The SQL seed file is a small demo dataset. For a richer report, import the separately supplied UniTrack_PowerBI_Data.xlsx workbook. Do not combine duplicate records from both sources in the same model.
