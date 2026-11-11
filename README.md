# Employee app — retired

The employee app now lives inside the admin app (the `flu` repository,
under `src/employee/`). There is one app for everyone, with three ways in
on its first screen:

| Who | Button | Signs in with |
| --- | --- | --- |
| Office staff | **LOGIN TO ERP** | email code or password, as before |
| Employees | **SIGN IN AS EMPLOYEE** | the phone number on their employee record and a PIN the office sets |
| Floor supervisor | **Floor entry with the shift PIN** | the shift's four-digit PIN (no login) |

Both sign-in forms link to each other, so an employee who has an email
login can use it too ("Sign in with email instead"), and the email form
offers "Employee? Sign in with phone and PIN". Either way, the server
decides which screens open: a worker's login lands on the employee
screens, an office login on the office screens.

This repository is kept for reference only. Do not build or release it
again; once the new app is on a worker's phone, uninstall this one.

## Before moving workers over

- Each worker needs a phone number on their employee record and a PIN.
  On the web: Employees → the employee → App access → Give app access
  (that sets the PIN). Five wrong PINs lock the login for 15 minutes;
  Reset PIN on the same card unlocks it.
- A login that still signs in with email and password keeps working
  through LOGIN TO ERP. If it is a worker's own login (no office
  modules), it lands on the employee screens. If it has office modules,
  it lands on the office screens, and its own payslip, leave and shifts
  are under More → **My work**.
- A phone kept by the looms for everyone can be marked shared (signed in
  as office staff: More → My account → Shared phone). It then opens on
  the employee sign-in and signs anyone out after a few untouched
  minutes, with a 30-second warning first.

## What changed on the way

- Every employee screen moved across: home, attendance, leave, payroll
  and advances, yearly bonus, current jobs, notices, feedback, profile,
  shift production and history, machine issues, wastage, warping,
  covering and packing.
- Sign-in, sign-out and the app lock are the main app's own; the
  employee screens' controllers were renamed (`Emp…`) so they cannot be
  confused with the office screens' controllers of the same name.
- The attendance calendar no longer needs `table_calendar`, and the
  bonus certificate opens in the app's PDF viewer (share and print from
  there) instead of needing `share_plus` and `path_provider`.
- Shift production is entered through the worker's own route
  (`/me/shifts/:id/production`), which a phone sign-in may use. The old
  office route refused those logins.
- The payroll screen lists the worker's own advance requests. The old
  app read them through an office-only list, so for every worker login
  the payslip failed to load as well. The server now allows a worker to
  list their own requests.
- Warping, covering, wastage and packing entries are office modules on
  the server, so a worker's phone sign-in is not shown those tiles.
  Office logins see them, as before.
- Floor entry on the phone can take the run time from a photo of the
  loom's timer, as the web does, and keeps the photo with the shift for
  whoever verifies it.
