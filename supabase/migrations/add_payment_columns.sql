ALTER TABLE bookings
ADD COLUMN payment_status text NOT NULL DEFAULT 'pending',
ADD COLUMN payment_reference text,
ADD COLUMN payment_amount decimal(10,2),
ADD COLUMN payment_method text; 