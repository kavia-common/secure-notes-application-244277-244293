#!/bin/bash

# Secure Notes App: PostgreSQL Schema DDL Installer (run me once with: bash create_schema_notes_app.sh)
# This script assumes PostgreSQL is running and connection info is in db_connection.txt
set -e

if [ ! -f "db_connection.txt" ]; then
  echo "ERROR: db_connection.txt not found! Please start the database and ensure connection info is available."
  exit 1
fi

PSQL_CMD="$(cat db_connection.txt)"

# Helper to run commands with output
run_psql() {
  SQL="$1"
  $PSQL_CMD -c "$SQL"
}

echo "Creating schema: users, notes, tags, note_tags..."

# USERS TABLE: Authentication and user profile
run_psql "
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_email UNIQUE(email)
);
"

# NOTES TABLE: Stores notes, tied to users
run_psql "
CREATE TABLE IF NOT EXISTS notes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    content TEXT,
    pinned BOOLEAN NOT NULL DEFAULT FALSE,
    favorited BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"

# TAGS TABLE: Tag vocabulary, owned per user for privacy
run_psql "
CREATE TABLE IF NOT EXISTS tags (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_user_tag UNIQUE(user_id, name)
);
"

# NOTE_TAGS TABLE: M2M for notes↔tags (one note, many tags; one tag, many notes)
run_psql "
CREATE TABLE IF NOT EXISTS note_tags (
    note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY(note_id, tag_id)
);
"

echo "Adding indexes for search, filtering, and fast lookups..."

# Email index (redundant due to UNIQUE, but for explicit query perf)
run_psql "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);"

# Note title/content for ILIKE search (may be used by backend for fulltext)
run_psql "CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title);"
run_psql "CREATE INDEX IF NOT EXISTS idx_notes_fulltext ON notes USING GIN (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(content,'')));"

# Pin/favorite for filtering
run_psql "CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes(pinned);"
run_psql "CREATE INDEX IF NOT EXISTS idx_notes_favorited ON notes(favorited);"

# Notes per user
run_psql "CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);"

# Tags per user
run_psql "CREATE INDEX IF NOT EXISTS idx_tags_user_id ON tags(user_id);"

# Tags per note and vice-versa
run_psql "CREATE INDEX IF NOT EXISTS idx_note_tags_note_id ON note_tags(note_id);"
run_psql "CREATE INDEX IF NOT EXISTS idx_note_tags_tag_id ON note_tags(tag_id);"

echo "Schema successfully created!"
