#!/bin/bash

# Load environment variables
source .env

# Apply migrations
psql "$SUPABASE_URL" -f supabase/migrations/20240318000000_initial_schema.sql 