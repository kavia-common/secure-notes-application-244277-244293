# Secure Notes App - Database Container

## Overview
This directory contains resources for the PostgreSQL database for the Secure Notes application.  
It includes a schema creation shell script and instructions on integrating with backend services.

---

## Requirements

- PostgreSQL 13+
- Environment variables set for connection:
  - `POSTGRES_URL`       (host-url, e.g. localhost or postgres-server)
  - `POSTGRES_USER`      (db username)
  - `POSTGRES_PASSWORD`  (db password)
  - `POSTGRES_DB`        (database name)
  - `POSTGRES_PORT`      (db port, default 5432)

## Creating Database Schema

To create the database schema needed by the backend:

1. **Ensure the environment variables above are set.**  
   If you are running as a Docker container, pass them explicitly or use a `.env` file that your backend will load.

2. **Connect to PostgreSQL:**  
   Use the provided `create_schema_notes_app.sh` script, which expects env vars for connection:
   ```bash
   ./create_schema_notes_app.sh
   ```

   - Alternatively, copy and run the relevant SQL commands in your own psql session.
   - The script runs commands like:
     ```
     psql "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_URL}:${POSTGRES_PORT}/${POSTGRES_DB}" -f schema.sql
     ```

3. **Verify tables:**  
   Connect using psql to your database and run `\dt` to list tables.

---

## Notes for Integration

- The backend must use the same environment variables for DB access.
- After schema is created, the backend will auto-migrate if fields/models change (see FastAPI/SQLAlchemy settings).
- JWT settings (`JWT_SECRET_KEY`, `JWT_ALGORITHM`) must also be set for the backend container.

## Troubleshooting

- Confirm network and credential access between backend and database.
- Errors like `psycopg2.OperationalError` or “could not connect to server” indicate invalid host/credentials or misconfigured ports/firewall.
