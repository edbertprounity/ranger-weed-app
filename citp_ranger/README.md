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
2. In the SQL editor, run `supabase/schema.sql`, then `supabase/seed.sql`.
3. In Project Settings → API, copy the project URL and the anon public key.
4. Paste them into `lib/core/supabase_config.dart` (`pastedUrl` and `pastedAnonKey`).
5. Stop the app and run it again. Use the sync icon. Another phone with the same keys can see the same sites and photos.

The free project pauses after a week unused. Delete it when the demo is over. The anon key is enough to read and write this demo data, so keep the project private to the team.

Without those keys, the app still logs sites, photos, GPS or typed coordinates, sprays, and the 30-day re-check. Nothing is uploaded.
