CREATE DATABASE IF NOT EXISTS unitrack;
USE unitrack;

CREATE TABLE IF NOT EXISTS Students (
  student_id VARCHAR(12) PRIMARY KEY,
  roll_no VARCHAR(20) NOT NULL UNIQUE,
  student_name VARCHAR(100) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  program VARCHAR(80) NOT NULL DEFAULT 'CSE-Data Science',
  semester TINYINT NOT NULL,
  section CHAR(1) NOT NULL,
  admission_year YEAR NOT NULL,
  CHECK(semester BETWEEN 1 AND 20)
);

CREATE TABLE IF NOT EXISTS Faculty (
  faculty_id VARCHAR(12) PRIMARY KEY,
  faculty_name VARCHAR(100) NOT NULL,
  department VARCHAR(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS Subjects (
  subject_id VARCHAR(12) PRIMARY KEY,
  subject_name VARCHAR(100) NOT NULL,
  faculty_id VARCHAR(12),
  credits TINYINT NOT NULL DEFAULT 3,
  CONSTRAINT fk_subject_faculty FOREIGN KEY(faculty_id) REFERENCES Faculty(faculty_id)
);

CREATE TABLE IF NOT EXISTS Assessments (
  assessment_id VARCHAR(16) PRIMARY KEY,
  student_id VARCHAR(12) NOT NULL,
  subject_id VARCHAR(12) NOT NULL,
  assessment_type VARCHAR(30) NOT NULL,
  marks_obtained DECIMAL(5,2) NOT NULL,
  max_marks DECIMAL(5,2) NOT NULL,
  assessment_date DATE NOT NULL,
  CHECK (marks_obtained >= 0 AND max_marks > 0 AND marks_obtained <= max_marks),
  FOREIGN KEY(student_id) REFERENCES Students(student_id),
  FOREIGN KEY(subject_id) REFERENCES Subjects(subject_id)
);

CREATE TABLE IF NOT EXISTS Attendance (
  attendance_id VARCHAR(40) PRIMARY KEY,
  student_id VARCHAR(12) NOT NULL,
  subject_id VARCHAR(12) NOT NULL,
  attendance_percentage DECIMAL(5,2) NOT NULL,
  classes_held INT NOT NULL,
  classes_attended INT NOT NULL,
  as_of_date DATE NOT NULL,
  UNIQUE KEY uq_student_subject(student_id,subject_id),
  CHECK(attendance_percentage BETWEEN 0 AND 100),
  CHECK(classes_attended BETWEEN 0 AND classes_held),
  CHECK(attendance_percentage = ROUND(classes_attended / classes_held * 100, 2)),
  FOREIGN KEY(student_id) REFERENCES Students(student_id),
  FOREIGN KEY(subject_id) REFERENCES Subjects(subject_id)
);

CREATE TABLE IF NOT EXISTS Interventions (
  intervention_id VARCHAR(16) PRIMARY KEY,
  student_id VARCHAR(12) NOT NULL,
  intervention_type VARCHAR(50) NOT NULL,
  intervention_status ENUM('Open','In Progress','Completed') DEFAULT 'Open',
  intervention_date DATE NOT NULL,
  reason VARCHAR(100),
  FOREIGN KEY(student_id) REFERENCES Students(student_id)
);

CREATE OR REPLACE VIEW vw_student_academic_summary AS
SELECT s.student_id, s.roll_no, s.student_name, s.email, s.program, s.semester, s.section,
       COALESCE(m.average_marks,0) AS average_marks,
       COALESCE(a.average_attendance,0) AS average_attendance,
       CASE
         WHEN COALESCE(a.average_attendance,0) < 65 OR COALESCE(m.average_marks,0) < 40 THEN 'High'
         WHEN COALESCE(a.average_attendance,0) < 75 OR COALESCE(m.average_marks,0) < 55 THEN 'Medium'
         ELSE 'Low'
       END AS risk_level
FROM Students s
LEFT JOIN (
  SELECT student_id, AVG(marks_obtained/max_marks*100) average_marks
  FROM Assessments GROUP BY student_id
) m ON m.student_id=s.student_id
LEFT JOIN (
  SELECT student_id, AVG(attendance_percentage) average_attendance
  FROM Attendance GROUP BY student_id
) a ON a.student_id=s.student_id;
