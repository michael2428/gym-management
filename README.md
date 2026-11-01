# IRON-PASS | Elite Gym & ITF Taekwon-Do Management App

A modern, responsive gym management and front-desk entry verification web application powered by **Supabase PostgreSQL** cloud database and **Realtime** synchronization.

## Features
- **Member Management**: Full profiles for General Gym members and ITF Taekwon-Do students (belts, rank, emergency contacts, fees).
- **Front-Desk Entry Verification**: Built-in QR scanner and manual search for quick front-desk check-ins with sound alerts.
- **Digital Membership Pass**: Generate printable and downloadable passes with personalized QR codes.
- **ITF Roll Call Attendance**: Daily digital checklist for martial arts sessions.
- **Audit History**: Complete event logging for check-ins, renewals, access denials, and profile updates.
- **Supabase Cloud Database**: Realtime cloud synchronization across front-desk tablets, phones, and PCs.
- **Offline-First Hybrid Architecture**: Automatically functions offline with local browser storage and syncs when back online.

## Database
The database schema and Row Level Security policies are located in [`supabase_schema.sql`](./supabase_schema.sql).

## Deployment
This app requires zero build steps and deploys directly to Vercel as a static site.
