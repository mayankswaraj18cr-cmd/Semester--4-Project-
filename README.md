# Hospital DBMS

A browser-based hospital resource management system backed by a normalized MySQL database design. The project demonstrates how patients, doctors, departments, appointments, admissions, rooms, prescriptions, medicines, and payments can work together in one operational data model.

## Project Status

This is a Semester 4 DBMS mini project. The HTML interface is a self-contained visual demo with in-memory data, while the `sql/` directory contains the executable database implementation for MySQL 8.0 or newer.

## What This Project Solves

Hospitals manage several related workflows at the same time: registering patients, scheduling doctors, assigning rooms, recording admissions, issuing prescriptions, and collecting payments. Keeping these records in separate spreadsheets creates duplicate data and makes reporting difficult.

This project uses primary keys, foreign keys, constraints, indexes, views, and analytical queries to give those workflows a consistent relational structure. The web demo mirrors the core entities so the relationships are easy to present without requiring a running server.

## Features

- Interactive [hospital DBMS demo](src/hospital_dbms.html) with table tabs and query previews
- MySQL schema with nine normalized domain tables plus a stock-audit table
- Seed data for departments, patients, doctors, rooms, appointments, admissions, medicines, prescriptions, and payments
- Reusable views for doctor schedules, room occupancy, and patient visit summaries
- Reporting queries using joins, aggregation, conditional expressions, CTEs, and window functions
- Stored procedures for booking, admission, discharge, restocking, and patient summaries
- MySQL functions, workflow triggers, and medication stock audit history
- Research paper and presentation documenting the project background and design

## Data Model

The database is centered on `patients` and connects clinical, operational, and financial records around them.

| Table | Responsibility | Important relationships |
| --- | --- | --- |
| `departments` | Hospital units and contact details | Owns doctors and rooms |
| `patients` | Demographics and emergency contacts | Parent of appointments, admissions, prescriptions, and payments |
| `doctors` | Staff profiles and specialties | Belongs to a department; handles appointments and prescriptions |
| `rooms` | Beds and room availability | Belongs to a department; used by admissions |
| `appointments` | Scheduled and completed visits | Connects one patient to one doctor |
| `admissions` | Inpatient stays and diagnoses | Connects a patient, room, and admitting doctor |
| `medication` | Pharmacy stock and reorder levels | Parent of prescriptions |
| `prescriptions` | Medication instructions for patients | Connects patients, doctors, and medicines |
| `payments` | Appointment and admission billing | Connects patients to a billable event |

## Project Structure

```
.
├── src/
│   └── hospital_dbms.html          # interactive browser demo
├── sql/
│   ├── 01_schema.sql               # database, tables, indexes, and views
│   ├── 02_seed_data.sql             # sample hospital records
│   ├── 03_queries.sql               # reports and validation queries
│   └── 04_routines_and_triggers.sql # procedures, functions, triggers, and audit log
├── assets/                          # images and other static assets
├── docs/
│   ├── Hospital_DBMS_Research_Paper.pdf
│   └── Hospital_DBMS_Presentation.pptx
├── LICENSE
└── README.md
```

## Getting Started

Clone the project and enter the repository:

```bash
git clone https://github.com/mayankswaraj18cr-cmd/Semester--4-Project-.git
cd Semester--4-Project-
```

### View the browser demo

Open [src/hospital_dbms.html](src/hospital_dbms.html) directly in a browser. The demo has no package installation or build step because its sample data is held in JavaScript memory.

### Run the SQL database

Install MySQL 8.0+, start the MySQL service, and run the scripts in order:

```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p hospital_db < sql/02_seed_data.sql
mysql -u root -p hospital_db < sql/03_queries.sql
mysql -u root -p hospital_db < sql/04_routines_and_triggers.sql
```

The schema script can be rerun during development because it recreates the project tables and views. The seed script should normally be run once after the schema. Load the routines after the seed data so future inserts and updates use the workflow triggers. Change the sample dates and records before using this database for real testing.

## SQL Highlights

The SQL implementation demonstrates:

- `PRIMARY KEY` and `AUTO_INCREMENT` identifiers for every entity
- `FOREIGN KEY` constraints to prevent orphaned appointments, admissions, and prescriptions
- `UNIQUE` constraints for patient contact details, room numbers, doctor appointments, and payment references
- `CHECK` constraints for fees, dates, stock-related values, and billable sources
- `ENUM` status fields for controlled workflow states
- Composite indexes for appointment dates, admission status, prescriptions, and payments
- Views that hide repeated joins from application and reporting code
- Aggregation, conditional sums, CTEs, and `ROW_NUMBER()` in reporting queries
- Stored procedures with transactions, row locks, validation, and `SIGNAL` errors
- Reusable functions for patient age and outstanding balance
- Triggers that synchronize room state, validate billable payments, and audit stock changes

The design keeps patient, doctor, department, room, and medication facts in their own tables. Transactional tables store relationships and events, which avoids repeating the same descriptive data and supports 1NF, 2NF, and 3NF.

## Example Reports

`sql/03_queries.sql` includes reports for:

1. The scheduled doctor calendar with patient details
2. Current room occupancy and active admissions
3. Rooms available for a new patient
4. Patient appointment and admission activity
5. Doctor workload by department
6. Medicines that need reordering
7. Revenue grouped by payment method and status
8. Patients with multiple clinical interactions
9. The latest appointment for every patient
10. Room-status consistency validation

`sql/04_routines_and_triggers.sql` provides operational database behavior:

- `sp_book_appointment` checks the patient, doctor, and time-slot conflict before booking
- `sp_admit_patient` locks and assigns an available room inside a transaction
- `sp_discharge_patient` closes an admission and moves the room to cleaning
- `sp_restock_medication` updates stock and records an audit event
- `sp_patient_summary` combines age, balance, visits, and admissions for one patient
- `fn_patient_age` and `fn_patient_balance` provide reusable computed values

## Development Workflow

The repository uses `main` for the stable project state. Feature work can be developed independently and merged after review:

```bash
git checkout main
git pull origin main
git checkout -b feature/sql-reports
# edit, test, and commit your changes
git push -u origin feature/sql-reports
```

Useful branch purposes include:

- `develop` for integration work
- `docs/updates` for documentation revisions
- `feature/sql-schema` for database structure changes
- `feature/sql-reports` for new reports and views
- `testing/sql-validation` for test data and validation checks

## Validation Checklist

- [ ] Run the schema script successfully on MySQL 8.0+
- [ ] Load seed data without foreign-key errors
- [ ] Run each report in `03_queries.sql`
- [ ] Open the HTML demo on desktop and mobile widths
- [ ] Confirm room occupancy and payment totals against expected sample data
- [ ] Review SQL changes before merging them into `main`

## Documentation

- [Research Paper](docs/Hospital_DBMS_Research_Paper.pdf) — background, problem framing, and database design
- [Presentation](docs/Hospital_DBMS_Presentation.pptx) — project overview and presentation materials
- [Schema](sql/01_schema.sql) — executable DDL and reusable views
- [Seed Data](sql/02_seed_data.sql) — sample records for local development
- [Reports](sql/03_queries.sql) — example joins, analytics, and integrity checks
- [Routines and Triggers](sql/04_routines_and_triggers.sql) — procedures, functions, workflow rules, and audit logging

## Roadmap

- [ ] Connect the browser interface to the MySQL database through an API
- [ ] Add authentication and role-based access for administrators, doctors, and reception staff
- [ ] Add patient search, appointment creation, and admission forms
- [ ] Add automated database tests and migration versioning
- [ ] Add audit history for changes to clinical and billing records

## License

MIT — see [LICENSE](LICENSE)

## Contact

Mayank Swaraj — [mayankswaraj18cr@gmail.com](mailto:mayankswaraj18cr@gmail.com)