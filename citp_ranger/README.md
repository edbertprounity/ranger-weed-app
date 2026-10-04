# Ranger App

Offline prototype for Lama Lama weed management. Each phone keeps its own copy of every site, photo, spray, and follow-up. When a Supabase project is connected, phones upload that copy and download everyone else's records.

## Run it

```powershell
cd citp_ranger
flutter run -d windows
```

On an Android phone, turn on USB debugging and run `flutter run -d android`.

The first screen asks for a ranger name. Sample sites from Alex, Sam, and Jo are already stored on the phone: one overdue sicklepod, two upcoming re-checks, and three sites that still need a spray.

## What stays after a flat battery

Records are written to a SQLite database in the app documents folder as soon as they are captured, including an unfinished site. Charging the phone and opening the app shows those rows again. The follow-up list is rebuilt from the saved re-check dates.

## Share records for the demo

1. Create a free project at [supabase.com](https://supabase.com).
2. In the SQL editor, run `supabase/schema.sql`, then `supabase/accounts.sql`, then `supabase/seed.sql`.
3. In Project Settings → API, copy the project URL and the publishable key.
4. Copy `dart_defines.example.json` to `dart_defines.json` in this folder and paste those two values there. `dart_defines.json` is gitignored.
5. Stop the app and run:

```powershell
flutter run -d windows --dart-define-from-file=dart_defines.json
```

GitHub Pages builds read the same values from the repository secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

The free project pauses after a week unused. Delete it when the demo is over. The publishable key can read and write this demo data, so keep the project private to the team.

Without those values, the app still logs sites, photos, GPS or typed coordinates, sprays, and the 30-day re-check. Nothing is uploaded. An admin can still add a ranger on this phone from **Add ranger**. Sharing that account with other phones needs the database connection, and the `create_account` function from `accounts.sql`.
