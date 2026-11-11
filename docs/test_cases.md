# UniTrack Test Cases

| ID | Test | Expected result |
|---|---|---|
| T01 | Open faculty portal with backend and DB running | Dashboard loads |
| T02 | GET /api/health | status=ok, database=connected |
| T03 | Add valid student | HTTP 201, student saved |
| T04 | Add duplicate student ID | HTTP 400 with duplicate message |
| T05 | Submit assessment with marks above maximum | HTTP 400 validation error |
| T06 | Submit valid assessment | HTTP 201 |
| T07 | Request existing student profile | Profile, marks and attendance returned |
| T08 | Request unknown student ID | HTTP 404 |
| T09 | Update attendance to 110% | HTTP 400 |
| T10 | Update attendance to 80% | Success |
| T11 | Compare risk label with rule thresholds | High/Medium/Low follows documented rule |
| T12 | Power BI refresh after assessment entry | Updated records visible after refresh |
| T13 | Update a student through `PUT /api/students/:id` | HTTP 200, updated profile returned |
| T14 | Create intervention with invalid status | HTTP 400 validation error |
| T15 | Create and list an intervention | HTTP 201, then intervention appears in `GET /api/interventions` |
| T16 | Submit attendance with classes attended above classes held | HTTP 400 validation error |
| T17 | Run Flutter widget smoke test | Test passes and portal access controls render |

Record actual test results and screenshots when you run the project. Do not claim tests passed until executed.

## Executed integration results — 2026-11-11

| Workflow step | Actual result | Status |
|---|---|---|
| Start Express and MySQL | `/api/health` returned HTTP 200 with `database=connected`; seeded baseline was 10 students, 15 assessments, 15 attendance rows and 3 interventions | PASS |
| Add student through faculty workflow | Browser form created `E2E001` / `E2E Integration Student`; success toast displayed and the student appeared in the live directory | PASS |
| Record assessment marks | `E2EASM1` saved for `E2E001` with 35/100; API returned HTTP 201 and the faculty form displayed the save state | PASS |
| Update attendance | `E2E001` / `SUB01` updated to 10/20 classes and 50%; API returned HTTP 200 | PASS |
| Open the same student through Flutter Web/API | Flutter Web server returned HTTP 200; the shared `/api/students/E2E001` payload contained the saved assessment and attendance records | PASS |
| Verify risk classification | Combined profile and MySQL view returned 35.00 average marks, 50.00 average attendance and `High` risk | PASS |
| Create faculty intervention | `E2EINT1` was created for `E2E001` with status `Open`; API returned HTTP 201 and the intervention read endpoint returned it | PASS |
| Verify database persistence | Direct MySQL query returned the student, assessment, attendance, intervention and derived High risk in one result | PASS |
| Restore test data | Temporary E2E rows were deleted; final counts returned to 10 students, 15 assessments, 15 attendance rows and 3 interventions | PASS |

### Observations and unexecuted coverage

- The first browser attempt to open the next Bootstrap modal while the assessment modal was still transitioning timed out. Reloading the faculty page confirmed this was a browser automation timing issue; the REST write path and persistence completed successfully.
- Flutter static validation and Web build were executed separately: `flutter analyze`, `flutter test`, and `flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:3000/api` passed.
- Power BI refresh (T12) was not executed because Power BI Desktop is not available in this macOS environment. It remains unverified.
