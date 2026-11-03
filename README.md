# Salon Booking (Flutter) — UI demo

Runs with in-memory sample data: no backend, keys or internet needed.
Any email/password signs you in. Data resets when the app restarts.

    flutter pub get
    flutter run

Backend later: `lib/services/api.dart` is the only file the screens use for data.
`supabase/schema.sql` is a ready-made PostgreSQL schema if you want to connect a real database.
