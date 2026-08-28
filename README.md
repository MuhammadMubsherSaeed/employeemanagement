# Employee Management / HRMS

Production-oriented HRMS: Flutter mobile app and Django REST API.

UI/UX reference: [Employee Management template on Behance](https://www.behance.net/gallery/162879483/Employee-Management-UIUX-Page-Template-Design)

Architecture: [`docs/architecture.md`](docs/architecture.md)

This repository is in **initialization**. Authentication flows and employee features are not implemented yet.

## Layout

```
mobile/     Flutter app (existing boilerplate + Clean Architecture folders)
backend/    Django + DRF + PostgreSQL settings
docs/       Architecture
docker/     Backend image, Postgres notes
```

## Prerequisites

- Flutter SDK (this repo is verified with Flutter 3.47 / Dart 3.13)
- Python 3.12
- PostgreSQL 16 (Docker Compose or local)

## Mobile

```bash
cd mobile
cp .env.example .env
flutter pub get
flutter analyze
flutter test
flutter run
```

The running app is still the existing splash/login shell (`flutter_base`). New features belong under `lib/features/<name>/{data,domain,presentation}`.

## Backend

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# Unix:    source .venv/bin/activate
pip install -r requirements/development.txt
cp .env.example .env
python manage.py check
python manage.py makemigrations
python manage.py migrate   # needs PostgreSQL
python manage.py runserver
```

- Health: `GET http://127.0.0.1:8000/api/health/`
- API root: `GET http://127.0.0.1:8000/api/v1/`
- Admin: `http://127.0.0.1:8000/admin/` (after migrate + `createsuperuser`)

## Docker

```bash
cp .env.example .env
cp backend/.env.example backend/.env
docker compose up --build
```

Compose starts PostgreSQL 16 and the Django app. Redis, Celery, and object storage are documented for later — they are not enabled yet.

## Roles

Admin, Manager, Employee. See the architecture document for the permission model.

## License

Private.
