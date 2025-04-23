-- Create users table
CREATE TABLE users (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'employee', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create cleaning_packages table
CREATE TABLE cleaning_packages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    duration INTEGER NOT NULL, -- Duration in minutes
    services TEXT[] NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create bookings table
CREATE TABLE bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    package_id UUID REFERENCES cleaning_packages(id) ON DELETE RESTRICT NOT NULL,
    employee_id UUID REFERENCES users(id) ON DELETE SET NULL,
    booking_date DATE NOT NULL,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    address TEXT NOT NULL,
    special_instructions TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'inProgress', 'completed', 'cancelled')),
    total_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaning_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can view their own profile" 
    ON users FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" 
    ON users FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Admins can update all profiles" 
    ON users FOR UPDATE 
    USING (EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    ));

-- Create policies for cleaning_packages table
CREATE POLICY "Anyone can view active packages" 
    ON cleaning_packages FOR SELECT 
    USING (is_active = true);

CREATE POLICY "Admins can manage packages" 
    ON cleaning_packages FOR ALL 
    USING (EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    ));

-- Create policies for bookings table
CREATE POLICY "Users can view their own bookings" 
    ON bookings FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Employees can view their assigned bookings" 
    ON bookings FOR SELECT 
    USING (auth.uid() = employee_id);

CREATE POLICY "Admins can view all bookings" 
    ON bookings FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Users can create bookings" 
    ON bookings FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all bookings" 
    ON bookings FOR ALL 
    USING (EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    ));

-- Create function to handle booking updates
CREATE OR REPLACE FUNCTION handle_booking_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for booking updates
CREATE TRIGGER booking_update
    BEFORE UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION handle_booking_update();

-- Insert initial admin user (replace with your admin email)
INSERT INTO users (id, email, name, role)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'admin@example.com',
    'System Admin',
    'admin'
);

-- Insert sample cleaning packages
INSERT INTO cleaning_packages (name, description, price, duration, services) VALUES
('Basic Cleaning', 'Standard home cleaning service', 99.99, 120, ARRAY['Dusting', 'Vacuuming', 'Bathroom cleaning', 'Kitchen cleaning']),
('Deep Cleaning', 'Thorough deep cleaning service', 199.99, 240, ARRAY['Basic cleaning services', 'Window cleaning', 'Carpet deep cleaning', 'Cabinet organization']),
('Move-in/Move-out', 'Comprehensive cleaning for moving', 299.99, 360, ARRAY['Deep cleaning services', 'Wall cleaning', 'Appliance cleaning', 'Garage cleaning']); 