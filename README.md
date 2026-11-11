# UniTrack — Academic Performance & Student Intelligence System

Individual TPDS-III project prepared for academic submission. Built to demonstrate:
- Module 1: data connection, dashboard charts, Power BI (final integration stage)
- Module 2: responsive Bootstrap web UI and Flutter Web UI
- Module 3: Node.js + Express REST API, MySQL and SQL queries
- Module 4: Git/GitHub workflow, Docker and deployment preparation

## Architecture

Bootstrap Faculty Portal + Flutter Web Student Portal → Express REST API → MySQL → Power BI (connect at the end).

## Requirements
- Node.js 20+
- MySQL 8+
- Flutter SDK (for the student web app)
- Git
- Power BI Desktop (Windows; if using macOS, use a Windows machine/VM for Power BI Desktop)

## 1. Recommended Docker setup

Docker Compose is the reproducible backend setup. It starts MySQL 8, initializes the schema and seed data on a new volume, waits for MySQL health, and starts Express.

Requirements: Docker Desktop with Compose v2.

```bash
docker compose down -v
docker compose up --build -d
docker compose ps
curl http://localhost:3000/api/health
```

Expected health response:

```json
{"status":"ok","database":"connected"}
```

Open the faculty website at `http://localhost:3000`.

To stop the stack:

```bash
docker compose down
```

To reset the demo database and rerun schema/seed initialization:

```bash
docker compose down -v
docker compose up --build -d
```

The Docker database password is a demo value used only by Compose. Do not reuse it in production. For native development, use `.env` or shell variables and never commit that file.

## 2. Native Node.js/MySQL setup

1. Create a MySQL database and run `database/schema.sql`.
2. Run `database/seed.sql`.
3. Copy `.env.example` to `.env` and update MySQL credentials.
4. In this folder:

```bash
npm install
npm run dev
```

API runs at `http://localhost:3000`; faculty portal at `http://localhost:3000`.

For a native macOS MySQL setup using Homebrew:

```bash
brew services start mysql
mysql --protocol=tcp -h 127.0.0.1 -P 3306 -u root < database/schema.sql
mysql --protocol=tcp -h 127.0.0.1 -P 3306 -u root < database/seed.sql
DB_HOST=127.0.0.1 DB_PORT=3306 DB_USER=root DB_PASSWORD='' DB_NAME=unitrack npm start
```

Demo login is intentionally simplified for the college prototype. The portal is a demo interface, not production-grade authentication.

## 3. Faculty website

Open `http://localhost:3000`. Use the dashboard to:
- View student counts and academic risk distribution
- Add a student
- Record marks
- Update attendance
- View student list and academic profile

## 4. Flutter Web student portal

In a terminal:

```bash
cd flutter_student
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

The Flutter app calls the Express API at `http://127.0.0.1:3000/api` by default.
The Express server enables CORS for the Flutter Web origin. For another host or deployed API, pass a different value through `API_BASE_URL`.

Build web output:

```bash
flutter build web
```

The Flutter project includes its Web platform scaffold. The student portal supports
student ID access, profile summaries, assessment history, attendance by subject,
academic risk display and a what-if future marks calculator.

## 5. API workflow coverage

The Express service currently provides:
- `GET /api/health`, `/api/students`, `/api/students/:id`, `/api/subjects` and `/api/interventions`
- `POST /api/students`, `/api/assessments` and `/api/interventions`
- `PUT /api/students/:id`, `/api/assessments/:id`, `/api/attendance/:studentId/:subjectId` and `/api/interventions/:id`

The faculty dashboard uses these APIs for student profiles, assessments, attendance,
intervention tracking and the shared risk summary.

## 6. Git / GitHub (Module 4)

```bash
git init
git branch -M main
git status --short
git add .
git commit -m "Build UniTrack academic intelligence system"
```

Create an empty GitHub repository, then:

```bash
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git push -u origin main
```

For later work, use a feature branch:

```bash
git switch -c feature/powerbi-integration
git add .
git commit -m "Add Power BI integration notes"
git push -u origin feature/powerbi-integration
```

Before the first commit, verify that secrets are ignored:

```bash
git status --short --ignored
git check-ignore -v .env node_modules .DS_Store
```

Do not commit `.env`, passwords, API keys, personal student data, `node_modules`, Flutter build output or `.dart_tool`.

## 7. Docker files

`Dockerfile` uses `npm ci --omit=dev` from the committed lockfile. `.dockerignore` excludes local dependencies, secrets and Flutter build files. The database schema and seed data are mounted into the MySQL initialization directory on first startup.

## 8. Academic submission documents

- [Architecture, ER diagram, DFD and risk rules](docs/architecture_and_diagrams.md)
- [Four-module mapping](docs/module_mapping.md)
- [SQL practice queries](docs/sql_practice.sql)
- [Test cases and actual execution results](docs/test_cases.md)
- [Viva explanation guide](docs/viva_guide.md)
- [Power BI DAX measures](powerbi/DAX_Measures.txt)
- [Power BI build guide](powerbi/PowerBI_Build_Guide.md)

## 9. Power BI — DO THIS LAST

Use `../UniTrack_PowerBI_Data.xlsx` (or the separately supplied dataset file) for the first visual demo. For a genuine live integration, connect Power BI to the same MySQL database:
- Get Data → MySQL database
- Server: `localhost:3306`
- Database: `unitrack`
- Choose Import mode for simplest setup
- Select Students, Subjects, Assessments, Attendance, Interventions and the `vw_student_academic_summary` view
- Create relationships and measures using `powerbi/DAX_Measures.txt`
- Build pages using `powerbi/PowerBI_Build_Guide.md`

Important: Power BI Desktop is primarily a Windows desktop application. If you are on macOS, use a Windows PC/VM or use the Excel dataset to prepare the report on an available Windows machine. The Power BI service alone may not support every Desktop authoring workflow.

## Demo flow for viva
1. Faculty adds a student or records marks in the website.
2. The record is stored in MySQL through Express.
3. Flutter Web fetches the same student's profile and displays marks/attendance.
4. Power BI connects to the same MySQL database and visualises academic performance.
5. Explain the risk rule: High risk if average marks < 40 OR attendance < 65%; Medium risk if average marks < 55 OR attendance < 75%; otherwise Low. This is a transparent rule-based indicator, not a machine-learning prediction.

## Limitations to state honestly
- Demo login is not secure production authentication.
- Synthetic sample data only.
- Power BI refresh is not instantaneous; refresh the dataset/report to show changed data.
- No real student data should be used without institutional permission.
