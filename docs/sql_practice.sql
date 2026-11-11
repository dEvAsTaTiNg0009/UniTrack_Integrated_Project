USE unitrack;

-- 1. Student count by section
SELECT section, COUNT(*) AS total_students
FROM Students
GROUP BY section;

-- 2. Average marks by subject
SELECT sub.subject_name,
       ROUND(AVG(a.marks_obtained / a.max_marks * 100), 2) AS average_percentage
FROM Assessments a
JOIN Subjects sub ON sub.subject_id = a.subject_id
GROUP BY sub.subject_id, sub.subject_name
ORDER BY average_percentage DESC;

-- 3. Students with attendance below 75%
SELECT s.roll_no, s.student_name, sub.subject_name, atd.attendance_percentage
FROM Attendance atd
JOIN Students s ON s.student_id = atd.student_id
JOIN Subjects sub ON sub.subject_id = atd.subject_id
WHERE atd.attendance_percentage < 75;

-- 4. Students with no intervention recorded
SELECT s.student_id, s.student_name
FROM Students s
LEFT JOIN Interventions i ON i.student_id = s.student_id
WHERE i.intervention_id IS NULL;

-- 5. Intervention count by status
SELECT intervention_status, COUNT(*) AS total
FROM Interventions
GROUP BY intervention_status;

-- 6. View academic risk summary
SELECT student_name, average_marks, average_attendance, risk_level
FROM vw_student_academic_summary
ORDER BY FIELD(risk_level,'High','Medium','Low'), average_marks;
