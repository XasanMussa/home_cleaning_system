-- Add location and description columns to bookings table
ALTER TABLE bookings
ADD COLUMN IF NOT EXISTS location text,
ADD COLUMN IF NOT EXISTS description text; 