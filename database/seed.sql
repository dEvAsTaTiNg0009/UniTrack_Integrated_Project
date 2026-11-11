USE unitrack;
INSERT IGNORE INTO Faculty VALUES
('FAC01','Dr. Ananya Rao','Data Science'),
('FAC02','Prof. Kunal Mehta','Web Technologies'),
('FAC03','Dr. Neha Iyer','Systems'),
('FAC04','Prof. Rohan Shah','Networks');

INSERT IGNORE INTO Subjects VALUES
('SUB01','Data Analytics','FAC01',4),
('SUB02','Web Technologies','FAC02',4),
('SUB03','Database Management Systems','FAC03',4),
('SUB04','Software Engineering','FAC01',3),
('SUB05','Computer Networks','FAC04',3),
('SUB06','Operating Systems','FAC03',4);

INSERT IGNORE INTO Students VALUES
('STU001','CSD2401','Aarav Sharma','student001@unitrack.demo','CSE-Data Science',5,'A',2024),
('STU002','CSD2402','Aditi Verma','student002@unitrack.demo','CSE-Data Science',5,'A',2024),
('STU003','CSD2403','Aditya Rao','student003@unitrack.demo','CSE-Data Science',5,'B',2024),
('STU004','CSD2404','Ananya Singh','student004@unitrack.demo','CSE-Data Science',5,'B',2024),
('STU005','CSD2405','Arjun Mehta','student005@unitrack.demo','CSE-Data Science',5,'A',2024),
('STU006','CSD2406','Diya Patel','student006@unitrack.demo','CSE-Data Science',5,'B',2024),
('STU007','CSD2407','Ishaan Gupta','student007@unitrack.demo','CSE-Data Science',5,'A',2024),
('STU008','CSD2408','Ira Nair','student008@unitrack.demo','CSE-Data Science',5,'B',2024),
('STU009','CSD2409','Kabir Khan','student009@unitrack.demo','CSE-Data Science',5,'A',2024),
('STU010','CSD2410','Kavya Joshi','student010@unitrack.demo','CSE-Data Science',5,'B',2024);

INSERT IGNORE INTO Assessments VALUES
('ASM001','STU001','SUB01','Midsem',78,100,'2026-09-01'),
('ASM002','STU001','SUB02','Midsem',72,100,'2026-09-02'),
('ASM003','STU001','SUB03','Midsem',84,100,'2026-09-03'),
('ASM004','STU002','SUB01','Midsem',42,100,'2026-09-01'),
('ASM005','STU002','SUB02','Midsem',48,100,'2026-09-02'),
('ASM006','STU002','SUB03','Midsem',55,100,'2026-09-03'),
('ASM007','STU003','SUB01','Midsem',35,100,'2026-09-01'),
('ASM008','STU003','SUB02','Midsem',39,100,'2026-09-02'),
('ASM009','STU003','SUB03','Midsem',44,100,'2026-09-03'),
('ASM010','STU004','SUB01','Midsem',91,100,'2026-09-01'),
('ASM011','STU004','SUB02','Midsem',86,100,'2026-09-02'),
('ASM012','STU004','SUB03','Midsem',89,100,'2026-09-03'),
('ASM013','STU005','SUB01','Midsem',64,100,'2026-09-01'),
('ASM014','STU005','SUB02','Midsem',69,100,'2026-09-02'),
('ASM015','STU005','SUB03','Midsem',58,100,'2026-09-03');

INSERT IGNORE INTO Attendance VALUES
('AT-STU001-SUB01','STU001','SUB01',92,50,46,'2026-11-01'),
('AT-STU001-SUB02','STU001','SUB02',88,50,44,'2026-11-01'),
('AT-STU001-SUB03','STU001','SUB03',90,50,45,'2026-11-01'),
('AT-STU002-SUB01','STU002','SUB01',72,50,36,'2026-11-01'),
('AT-STU002-SUB02','STU002','SUB02',68,50,34,'2026-11-01'),
('AT-STU002-SUB03','STU002','SUB03',75,40,30,'2026-11-01'),
('AT-STU003-SUB01','STU003','SUB01',58,50,29,'2026-11-01'),
('AT-STU003-SUB02','STU003','SUB02',62,50,31,'2026-11-01'),
('AT-STU003-SUB03','STU003','SUB03',60,50,30,'2026-11-01'),
('AT-STU004-SUB01','STU004','SUB01',96,50,48,'2026-11-01'),
('AT-STU004-SUB02','STU004','SUB02',94,50,47,'2026-11-01'),
('AT-STU004-SUB03','STU004','SUB03',98,50,49,'2026-11-01'),
('AT-STU005-SUB01','STU005','SUB01',80,50,40,'2026-11-01'),
('AT-STU005-SUB02','STU005','SUB02',78,50,39,'2026-11-01'),
('AT-STU005-SUB03','STU005','SUB03',82,50,41,'2026-11-01');

INSERT IGNORE INTO Interventions VALUES
('INT001','STU002','Academic Counselling','In Progress','2026-10-10','Low attendance'),
('INT002','STU003','Extra Classes','Open','2026-10-12','Low marks and attendance'),
('INT003','STU005','Mentoring','Completed','2026-10-15','Assessment performance');
