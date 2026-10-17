# MediSchedule

Medication reminder app for elderly users (60+).

- `backend`: Java Spring Boot REST API
- `frontend`: Flutter mobile app

## Backend setup

### 1. Install
- Java 17 (Eclipse Temurin)
- Git
- VS Code with "Extension Pack for Java" and "Spring Boot Extension Pack"

### 2. Clone and open
```
git clone https://github.com/RobynD00/MediSchedule.git
```
Open the `backend` folder in VS Code (File, Open Folder).

### 3. Create your local config
Create `backend/src/main/resources/application-local.properties`.
Copy the contents from `application-local.properties.example` and fill in the real values.
DB password and secret available on request just reach out to the group.
This file is gitignored. Never commit it.

### 4. Run
Open `BackendApplication.java` and click Run above `main`.
Stop the app with the red square before running again, otherwise port 8080 stays busy.

### 5. Test
- `http://localhost:8080/api/health` should return `{"status":"UP"}`
- Any other `/api/...` endpoint should return 401 until you send a token

Flutter on the Android emulator reaches the backend at `http://10.0.2.2:8080`.
A real phone on the same Wi-Fi uses the laptop IP, e.g. `http://192.168.x.x:8080`.

## Backend structure

All code is in `backend/src/main/java/com/medischedule/backend`.

| Folder | Purpose |
|---|---|
| `enums` | Role, DoseStatus, LinkStatus, ScanOutcome, Frequency |
| `entity` | Database tables (do not edit without telling Robyn) |
| `repository` | Database queries. Add new ones here |
| `dto` | Request and response objects for the API |
| `service` | Business logic |
| `controller` | API endpoints |
| `security` | JWT, login filter, CurrentUser |
| `exception` | ApiException and the global error handler |

## Rules for every module

- Build in this order: DTOs, service, controller
- Never return an entity from a controller. Return a DTO
- Get the logged-in user with `CurrentUser.id()`. Never read the user id from the request body
- Fail with `throw new ApiException(HttpStatus.NOT_FOUND, "Medication not found.")`. No try/catch needed in controllers
- Hash passwords with the `PasswordEncoder` bean. Never store plain passwords
- Log important actions with `AuditService.log(...)`. Never put medical data or passwords in the log
- Public endpoints must be added to the `permitAll` list in `SecurityConfig`
- Comment your code for the next developer
- Medication delete is soft: set `active` to false

## Ready-made helpers

- `SessionService.createSession(user)` returns a token at login
- `SessionService.revoke(token)` logs out
- `AuditService.log(user, "ACTION", "details")`
- `CurrentUser.id()`
- Repositories already have the common finders. Add more if needed

## Who builds what

| Member | Module | Endpoints |
|---|---|---|
| 3 | Authentication | `POST /api/auth/register`, `/verify`, `/login`, `/forgot-password`, `/logout` |
| 4 | Medication | `GET/POST /api/medications`, `PUT/DELETE /api/medications/{id}` |
| 5 | Reminders and doses | `POST /api/medications/{id}/reminders`, `POST /api/doses/{id}/taken`, `/snooze`, `/skip`, `GET /api/doses/history`, `POST /api/caregivers/link` |
| 6 | Medical info and QR | `GET/PUT /api/medical-info`, `POST /api/qr/generate`, `POST /api/qr/revoke`, `GET /api/qr/scan/{token}` (public) |

## Git workflow

- `main` always has working code. Do not push to it directly
- Create your own branch:
```
git checkout -b feature/your-module
```
- Commit often:
```
git add .
git commit -m "Describe what you did"
git push -u origin feature/your-module
``` 
