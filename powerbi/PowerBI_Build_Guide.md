# UniTrack Power BI — final integration build guide

This report must connect to the same `unitrack` MySQL database used by Express. Do not import an unrelated Excel dataset for the final demonstration.

## Environment

Power BI Desktop and the MySQL connector are Windows tools. They are not available in the current macOS environment, so the `.pbix` report cannot be generated or refreshed here. Build it on a Windows machine, Windows VM or institutional lab computer.

Before opening Power BI, start the backend database:

```bash
docker compose up --build -d
curl http://localhost:3000/api/health
```

When using Docker Desktop on Windows, Power BI connects to `localhost:3306`. If MySQL runs in another VM or host, use that host's reachable address instead.

## Connect to live MySQL data

1. Install MySQL Connector/NET 8.x matching the Power BI Desktop bitness.
2. Open Power BI Desktop.
3. Select **Home → Get data → MySQL database**.
4. Server: `localhost:3306`; database: `unitrack`.
5. Select **Import** mode for the simplest academic demonstration.
6. Select exactly: `Students`, `Faculty`, `Subjects`, `Assessments`, `Attendance`, `Interventions`, and `vw_student_academic_summary`.
7. Load the data and open **Model view**.

## Model relationships

Create these active relationships with single-direction filters from dimensions to facts:

| From | To | Cardinality |
|---|---|---|
| `Students[student_id]` | `Assessments[student_id]` | 1:* |
| `Students[student_id]` | `Attendance[student_id]` | 1:* |
| `Students[student_id]` | `Interventions[student_id]` | 1:* |
| `Subjects[subject_id]` | `Assessments[subject_id]` | 1:* |
| `Subjects[subject_id]` | `Attendance[subject_id]` | 1:* |
| `Faculty[faculty_id]` | `Subjects[faculty_id]` | 1:* |
| `Students[student_id]` | `vw_student_academic_summary[student_id]` | 1:1 |

Set the 1:1 student-summary relationship to **Both** cross-filter direction so Student slicers filter the summary risk table. Do not connect the summary view directly to Assessments or Attendance; that would create ambiguous filter paths and duplicate fact logic.

## Measures

Create the measures from `DAX_Measures.txt` under the `Students` table or a dedicated measure table. Format percentage measures as `0.0%` where the measure returns a ratio, or `0.0` with a percent sign where the measure returns 0-100. The supplied measures intentionally include both `Average Marks %` (average assessment percentage) and `Weighted Marks %` (total marks divided by total maximum marks).

## Recommended pages

### Page 1: Academic Overview
- KPI cards: `Total Students`, `Average Marks %`, `Average Attendance %`, `Pass Rate %`
- Clustered bar: `Subjects[subject_name]` with `Average Marks by Subject %`
- Donut: `vw_student_academic_summary[risk_level]` with count of `student_id`
- Clustered column: `Assessments[assessment_type]` with `Average Marks %`
- Slicers: `Students[semester]`, `Students[section]`, `Subjects[subject_name]`

### Page 2: Student Risk & Performance
- Table: `student_name`, `roll_no`, `average_marks`, `average_attendance`, `risk_level` from the summary view
- Scatter: X axis `average_attendance`, Y axis `average_marks`, Details `student_id`, Legend `risk_level`
- Clustered bar: `Students[section]` with `At-Risk Students`
- Slicers: `vw_student_academic_summary[risk_level]`, `Students[section]`, `Students[semester]`

### Page 3: Attendance & Interventions
- KPI cards: `Average Attendance %`, `Completed Interventions`, `Open Interventions`, `Intervention Completion %`
- Bar: `Subjects[subject_name]` with `Average Attendance %`
- Donut: `Interventions[intervention_status]` with count of `intervention_id`
- Bar: `Interventions[intervention_type]` with count of `intervention_id`
- Table: student name, intervention type, status, date and reason
- Slicers: intervention status, intervention type, section and semester

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

## Refresh demonstration
1. Keep Power BI connected to the same MySQL database.
2. Record the current KPI values and the selected student risk row.
3. Add or update a student, assessment, attendance record or intervention in the faculty portal.
4. In Power BI select **Home → Refresh**.
5. Recheck the KPI, risk table and relevant visual.
6. Capture before/after screenshots for the viva evidence.

Refresh is not guaranteed to be instantaneous. Import mode requires refresh. DirectQuery can be considered later if the environment supports it.

## Professional formatting

- Canvas background: `#F5F7FB`.
- Primary navy: `#14213D` for titles and navigation.
- Primary blue: `#2563EB` for marks and selected controls.
- Teal: `#0F9F92` for attendance and completed states.
- Amber: `#D78A1F` for medium risk and open work.
- Red: `#D94B55` for high risk.
- Use one consistent title size, aligned KPI cards, visible units and meaningful visual titles.
- Enable cross-highlighting and keep slicers synchronized across pages where appropriate.

## Viva demonstration

1. Show the Model view and explain the Students/Subjects dimensions and fact tables.
2. Show the Academic Overview KPIs and explain the assessment percentage measure.
3. Filter to a section and show how the visuals cross-filter.
4. Open Student Risk Analysis and explain why a student is High, Medium or Low risk.
5. Add an assessment or attendance record in the faculty website.
6. Refresh Power BI and show the changed KPI or student row from the same MySQL database.
7. Show the intervention page and explain open versus completed support.
8. State honestly that Import mode requires a manual refresh and that the prototype uses synthetic data.

## Troubleshooting

- Connector error: install a compatible MySQL Connector/NET and restart Power BI Desktop.
- Connection refused: confirm MySQL is running and port 3306 is reachable; run `docker compose ps`.
- Empty tables after schema changes: reset the demo volume with `docker compose down -v` and start again.
- Duplicate records: do not combine the SQL database with any separate Excel workbook.
