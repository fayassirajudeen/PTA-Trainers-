# PTA Staff App

Extract this ZIP, open public/index.html in Chrome or Edge, and select Try demo. Switch between the trainer and supervisor views on the same device. Demo data resets on refresh or sign-out.

## Publish for staff

1. Create a private GitHub repository. Upload the extracted api and public folders, schema.sql, vercel.json and README.md at the repository root, preserving their folder structure.
2. Create a Supabase project. In SQL Editor run schema.sql once against the fresh database. Enable the Data API for the public schema and email/password authentication.
3. In Authentication → Users create a confirmed user with an email and password for each staff member. In Table Editor → staff insert their authentication UUID as id, their display name, and either trainer or supervisor as role. Set opening_days to their confirmed opening comp-off balance. Staff membership must be assigned by the administrator.
4. In Vercel import the GitHub repository as a new project. Use the Other preset, leave the build command empty and use public as the output directory. Set SUPABASE_URL to the project's HTTPS URL and SUPABASE_PUBLISHABLE_KEY to its public publishable key. Never use a secret or service-role key here. Deploy.
5. On the Vercel URL sign in as a test trainer, submit a duty, then sign in separately as a supervisor and approve it. Refresh the trainer's entries to verify the shared totals. A second trainer should only see their own entries.

## Review rules

One active entry per trainer per date, for a single same-day shift. Rejected entries can be resubmitted. The reviewer confirms payable amounts. Normal duty suggests time above 8.5 hours, capped at 3.5 hours. Holiday duty suggests one day per full eight hours and offers remaining hours as overtime. Comp-off taken records one day against the approved balance. Pending and rejected records do not change balances.

This version tracks whole comp-off days. It does not calculate historical carry hours, staff-specific class conversions or payroll. Agree the allocations and opening balances before using live records. Sign in again if the access token expires.
