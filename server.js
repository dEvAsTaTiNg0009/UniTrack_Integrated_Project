require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./src/db');
const app = express();

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', async (_req,res) => {
  try { await db.query('SELECT 1'); res.json({status:'ok', database:'connected'}); }
  catch (e) { res.status(500).json({status:'error', message:'Database unavailable'}); }
});

app.get('/api/students', async (_req,res) => {
  try {
    const [rows] = await db.query('SELECT * FROM vw_student_academic_summary ORDER BY student_name');
    res.json(rows);
  } catch(e) { res.status(500).json({error:e.message}); }
});

app.get('/api/students/:id', async (req,res) => {
  try {
    const [student] = await db.query('SELECT * FROM vw_student_academic_summary WHERE student_id=?',[req.params.id]);
    if (!student.length) return res.status(404).json({error:'Student not found'});
    const [marks] = await db.query(`SELECT a.assessment_id, a.subject_id, a.assessment_type, a.marks_obtained, a.max_marks,
      a.assessment_date, sub.subject_name FROM Assessments a
      JOIN Subjects sub ON sub.subject_id=a.subject_id
      WHERE a.student_id=? ORDER BY a.assessment_date, a.assessment_id`,[req.params.id]);
    const [attendance] = await db.query(`SELECT atd.attendance_id, atd.subject_id, sub.subject_name, atd.attendance_percentage,
      atd.classes_attended, atd.classes_held FROM Attendance atd
      JOIN Subjects sub ON sub.subject_id=atd.subject_id WHERE atd.student_id=?`,[req.params.id]);
    res.json({profile:student[0], assessments:marks, attendance});
  } catch(e) { res.status(500).json({error:e.message}); }
});

app.post('/api/students', async (req,res) => {
  const {student_id, roll_no, student_name, email, program, semester, section} = req.body;
  if (!student_id || !roll_no || !student_name || !email) return res.status(400).json({error:'student_id, roll_no, student_name and email are required'});
  if (semester != null && (!Number.isInteger(Number(semester)) || Number(semester)<1 || Number(semester)>20))
    return res.status(400).json({error:'Semester must be an integer between 1 and 20'});
  if (section != null && !/^[A-Za-z]$/.test(String(section))) return res.status(400).json({error:'Section must be one letter'});
  try {
    await db.query(`INSERT INTO Students(student_id,roll_no,student_name,email,program,semester,section,admission_year)
      VALUES(?,?,?,?,?,?,?,YEAR(CURDATE()))`,
      [student_id,roll_no,student_name,email,program || 'CSE-Data Science',semester || 5,section || 'A']);
    res.status(201).json({message:'Student created',student_id});
  } catch(e) { res.status(400).json({error:e.code==='ER_DUP_ENTRY'?'Student ID, roll number or email already exists':e.message}); }
});

app.put('/api/students/:id', async (req,res) => {
  const {roll_no, student_name, email, program, semester, section} = req.body;
  if (!roll_no || !student_name || !email || !program || semester == null || !section)
    return res.status(400).json({error:'roll_no, student_name, email, program, semester and section are required'});
  if (!Number.isInteger(Number(semester)) || Number(semester)<1 || Number(semester)>20)
    return res.status(400).json({error:'Semester must be an integer between 1 and 20'});
  if (!/^[A-Za-z]$/.test(String(section))) return res.status(400).json({error:'Section must be one letter'});
  try {
    const [result] = await db.query(`UPDATE Students
      SET roll_no=?, student_name=?, email=?, program=?, semester=?, section=?
      WHERE student_id=?`, [roll_no, student_name, email, program, semester, section, req.params.id]);
    if (!result.affectedRows) return res.status(404).json({error:'Student not found'});
    res.json({message:'Student updated',student_id:req.params.id});
  } catch(e) { res.status(400).json({error:e.code==='ER_DUP_ENTRY'?'Roll number or email already exists':e.message}); }
});

app.delete('/api/students/:id', async (req,res) => {
  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();
    const [student] = await connection.query('SELECT student_id FROM Students WHERE student_id=? FOR UPDATE', [req.params.id]);
    if (!student.length) {
      await connection.rollback();
      return res.status(404).json({error:'Student not found'});
    }
    await connection.query('DELETE FROM Interventions WHERE student_id=?', [req.params.id]);
    await connection.query('DELETE FROM Assessments WHERE student_id=?', [req.params.id]);
    await connection.query('DELETE FROM Attendance WHERE student_id=?', [req.params.id]);
    await connection.query('DELETE FROM Students WHERE student_id=?', [req.params.id]);
    await connection.commit();
    res.json({message:'Student and related academic records deleted',student_id:req.params.id});
  } catch(e) {
    if (connection) await connection.rollback();
    res.status(500).json({error:'Student deletion failed'});
  } finally {
    if (connection) connection.release();
  }
});

app.post('/api/assessments', async (req,res) => {
  const {assessment_id,student_id,subject_id,assessment_type,marks_obtained,max_marks} = req.body;
  if (!assessment_id || !student_id || !subject_id || marks_obtained==null || max_marks==null)
    return res.status(400).json({error:'Missing required assessment fields'});
  if (!Number.isFinite(Number(marks_obtained)) || !Number.isFinite(Number(max_marks)) || Number(marks_obtained)<0 || Number(max_marks)<=0 || Number(marks_obtained)>Number(max_marks))
    return res.status(400).json({error:'Marks must be between 0 and maximum marks'});
  try {
    await db.query(`INSERT INTO Assessments(assessment_id,student_id,subject_id,assessment_type,marks_obtained,max_marks,assessment_date)
      VALUES(?,?,?,?,?,?,CURDATE())`,
      [assessment_id,student_id,subject_id,assessment_type || 'Internal',marks_obtained,max_marks]);
    res.status(201).json({message:'Assessment saved'});
  } catch(e) { res.status(400).json({error:e.message}); }
});

app.put('/api/assessments/:id', async (req,res) => {
  const {student_id, subject_id, assessment_type, marks_obtained, max_marks, assessment_date} = req.body;
  if (!student_id || !subject_id || marks_obtained == null || max_marks == null || !assessment_date)
    return res.status(400).json({error:'student_id, subject_id, marks_obtained, max_marks and assessment_date are required'});
  if (!Number.isFinite(Number(marks_obtained)) || !Number.isFinite(Number(max_marks)) || Number(marks_obtained) < 0 || Number(max_marks) <= 0 || Number(marks_obtained) > Number(max_marks))
    return res.status(400).json({error:'Marks must be between 0 and maximum marks'});
  try {
    const [result] = await db.query(`UPDATE Assessments SET student_id=?, subject_id=?, assessment_type=?,
      marks_obtained=?, max_marks=?, assessment_date=? WHERE assessment_id=?`,
      [student_id, subject_id, assessment_type || 'Internal', marks_obtained, max_marks, assessment_date, req.params.id]);
    if (!result.affectedRows) return res.status(404).json({error:'Assessment not found'});
    res.json({message:'Assessment updated',assessment_id:req.params.id});
  } catch(e) { res.status(400).json({error:e.message}); }
});

app.delete('/api/assessments/:id', async (req,res) => {
  try {
    const [result] = await db.query('DELETE FROM Assessments WHERE assessment_id=?', [req.params.id]);
    if (!result.affectedRows) return res.status(404).json({error:'Assessment not found'});
    res.json({message:'Assessment deleted',assessment_id:req.params.id});
  } catch(e) { res.status(500).json({error:'Assessment deletion failed'}); }
});

app.put('/api/attendance/:studentId/:subjectId', async (req,res) => {
  const pct=Number(req.body.attendance_percentage);
  const classesHeld=Number(req.body.classes_held ?? 100);
  const classesAttended=Number(req.body.classes_attended ?? Math.round(classesHeld*pct/100));
  if (!Number.isFinite(pct) || pct<0 || pct>100) return res.status(400).json({error:'Attendance must be between 0 and 100'});
  if (!Number.isInteger(classesHeld) || classesHeld<=0 || !Number.isInteger(classesAttended) || classesAttended<0 || classesAttended>classesHeld)
    return res.status(400).json({error:'Classes attended must be between 0 and classes held'});
  if (Math.abs(pct - (classesAttended / classesHeld * 100)) > 0.01)
    return res.status(400).json({error:'Attendance percentage must match classes attended and classes held'});
  try {
    await db.query(`INSERT INTO Attendance(attendance_id,student_id,subject_id,attendance_percentage,classes_held,classes_attended,as_of_date)
      VALUES(?,?,?,?,?,?,CURDATE()) ON DUPLICATE KEY UPDATE attendance_percentage=VALUES(attendance_percentage),
      classes_held=VALUES(classes_held), classes_attended=VALUES(classes_attended), as_of_date=CURDATE()`,
      [`AT-${req.params.studentId}-${req.params.subjectId}`,req.params.studentId,req.params.subjectId,pct,classesHeld,classesAttended]);
    res.json({message:'Attendance updated'});
  } catch(e) { res.status(400).json({error:e.message}); }
});

app.delete('/api/attendance/:studentId/:subjectId', async (req,res) => {
  try {
    const [result] = await db.query('DELETE FROM Attendance WHERE student_id=? AND subject_id=?', [req.params.studentId, req.params.subjectId]);
    if (!result.affectedRows) return res.status(404).json({error:'Attendance record not found'});
    res.json({message:'Attendance deleted',student_id:req.params.studentId,subject_id:req.params.subjectId});
  } catch(e) { res.status(500).json({error:'Attendance deletion failed'}); }
});

app.get('/api/assessments', async (req,res) => {
  try {
    const params = [];
    let query = `SELECT a.assessment_id, a.student_id, s.student_name, a.subject_id,
      sub.subject_name, a.assessment_type, a.marks_obtained, a.max_marks, a.assessment_date
      FROM Assessments a JOIN Students s ON s.student_id=a.student_id
      JOIN Subjects sub ON sub.subject_id=a.subject_id`;
    if (req.query.student_id) {
      query += ' WHERE a.student_id=?';
      params.push(req.query.student_id);
    }
    query += ' ORDER BY a.assessment_date DESC, a.assessment_id DESC';
    const [rows] = await db.query(query, params);
    res.json(rows);
  } catch(e) { res.status(500).json({error:e.message}); }
});

app.get('/api/attendance', async (req,res) => {
  try {
    const params = [];
    let query = `SELECT atd.attendance_id, atd.student_id, s.student_name, atd.subject_id,
      sub.subject_name, atd.attendance_percentage, atd.classes_attended, atd.classes_held, atd.as_of_date
      FROM Attendance atd JOIN Students s ON s.student_id=atd.student_id
      JOIN Subjects sub ON sub.subject_id=atd.subject_id`;
    if (req.query.student_id) {
      query += ' WHERE atd.student_id=?';
      params.push(req.query.student_id);
    }
    query += ' ORDER BY atd.as_of_date DESC, atd.attendance_id';
    const [rows] = await db.query(query, params);
    res.json(rows);
  } catch(e) { res.status(500).json({error:e.message}); }
});

app.get('/api/interventions', async (req,res) => {
  try {
    const params = [];
    let query = `SELECT i.*, s.student_name, s.roll_no FROM Interventions i
      JOIN Students s ON s.student_id=i.student_id`;
    if (req.query.student_id) {
      query += ' WHERE i.student_id=?';
      params.push(req.query.student_id);
    }
    query += ' ORDER BY i.intervention_date DESC, i.intervention_id DESC';
    const [rows] = await db.query(query, params);
    res.json(rows);
  } catch(e) { res.status(500).json({error:e.message}); }
});

app.post('/api/interventions', async (req,res) => {
  const {intervention_id, student_id, intervention_type, intervention_status, intervention_date, reason} = req.body;
  if (!intervention_id || !student_id || !intervention_type || !intervention_date)
    return res.status(400).json({error:'intervention_id, student_id, intervention_type and intervention_date are required'});
  if (intervention_status && !['Open','In Progress','Completed'].includes(intervention_status))
    return res.status(400).json({error:'Invalid intervention status'});
  try {
    await db.query(`INSERT INTO Interventions
      (intervention_id,student_id,intervention_type,intervention_status,intervention_date,reason)
      VALUES(?,?,?,?,?,?)`, [intervention_id, student_id, intervention_type,
      intervention_status || 'Open', intervention_date, reason || null]);
    res.status(201).json({message:'Intervention created',intervention_id});
  } catch(e) { res.status(400).json({error:e.code==='ER_DUP_ENTRY'?'Intervention ID already exists':e.message}); }
});

app.put('/api/interventions/:id', async (req,res) => {
  const {intervention_type, intervention_status, intervention_date, reason} = req.body;
  if (!intervention_type || !intervention_date)
    return res.status(400).json({error:'intervention_type and intervention_date are required'});
  if (intervention_status && !['Open','In Progress','Completed'].includes(intervention_status))
    return res.status(400).json({error:'Invalid intervention status'});
  try {
    const [result] = await db.query(`UPDATE Interventions SET intervention_type=?, intervention_status=?,
      intervention_date=?, reason=? WHERE intervention_id=?`,
      [intervention_type, intervention_status || 'Open', intervention_date, reason || null, req.params.id]);
    if (!result.affectedRows) return res.status(404).json({error:'Intervention not found'});
    res.json({message:'Intervention updated',intervention_id:req.params.id});
  } catch(e) { res.status(400).json({error:e.message}); }
});

app.delete('/api/interventions/:id', async (req,res) => {
  try {
    const [result] = await db.query('DELETE FROM Interventions WHERE intervention_id=?', [req.params.id]);
    if (!result.affectedRows) return res.status(404).json({error:'Intervention not found'});
    res.json({message:'Intervention deleted',intervention_id:req.params.id});
  } catch(e) { res.status(500).json({error:'Intervention deletion failed'}); }
});

app.get('/api/analytics/overview', async (_req,res) => {
  try {
    const [[students]] = await db.query('SELECT COUNT(*) total_students FROM Students');
    const [[marks]] = await db.query('SELECT COALESCE(ROUND(AVG(marks_obtained/max_marks)*100,1),0) average_marks_pct FROM Assessments');
    const [[attendance]] = await db.query('SELECT COALESCE(ROUND(AVG(attendance_percentage),1),0) average_attendance_pct FROM Attendance');
    const [[risk]] = await db.query(`SELECT COALESCE(SUM(average_marks < 55 OR average_attendance < 75),0) at_risk_students
      FROM vw_student_academic_summary`);
    res.json({...students,...marks,...attendance,...risk});
  } catch(e) { res.status(500).json({error:e.message}); }
});

app.get('/api/subjects', async (_req,res) => {
  try { const [rows]=await db.query('SELECT * FROM Subjects ORDER BY subject_name'); res.json(rows); }
  catch(e) { res.status(500).json({error:e.message}); }
});

const port=process.env.PORT || 3000;
if (require.main === module) app.listen(port,()=>console.log(`UniTrack running at http://localhost:${port}`));
module.exports = app;
