CREATE DATABASE IF NOT EXISTS hotel_bookings_db;
USE hotel_bookings_db;

-- room_types table
CREATE TABLE room_types (
    room_type_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- buildings table
CREATE TABLE buildings (
    building_id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(50),
	floors INT NOT NULL,
    wing VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- rates table
CREATE TABLE rates (
    rate_id INT AUTO_INCREMENT PRIMARY KEY,
    rate_per_night DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    room_type_id INT NOT NULL,
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id)
);

-- room statuses table
CREATE TABLE room_statuses (
    room_status_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);


-- rooms table
CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(10) NOT NULL UNIQUE,
    floor INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	room_type_id INT NOT NULL,
    building_id INT NOT NULL,
    room_status_id INT NOT NULL,
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id),
    FOREIGN KEY (building_id) REFERENCES buildings(building_id),
    FOREIGN KEY (room_status_id) REFERENCES room_statuses(room_status_id)
);

-- customer_types table
CREATE TABLE customer_types (
    customer_type_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE genders (
    gender_id TINYINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20) UNIQUE NOT NULL
);

-- customers table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    customer_type_id INT,
	gender_id TINYINT NOT NULL,
    FOREIGN KEY (gender_id) REFERENCES genders(gender_id),
    FOREIGN KEY (customer_type_id) REFERENCES customer_types(customer_type_id),
    CONSTRAINT check_email CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$')
);

-- booking statuses table
CREATE TABLE booking_statuses (
    booking_status_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- rooms_bookings table junction table 
CREATE TABLE rooms_bookings (
    rooms_booking_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(20) NOT NULL,
    expected_check_in DATETIME NOT NULL,
    expected_check_out DATETIME NOT NULL,
    actual_check_in DATETIME NULL,
    actual_check_out DATETIME NULL,
    special_requests VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	room_id INT NOT NULL,
	customer_id INT NOT NULL,
    booking_status_id INT NOT NULL,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (booking_status_id) REFERENCES booking_statuses(booking_status_id),
    -- CONSTRAINT check_dates CHECK (expected_check_out >= expected_check_in AND expected_check_in >= NOW()) 
    CONSTRAINT check_dates CHECK (
        expected_check_out >= expected_check_in AND 
        (actual_check_out IS NULL OR actual_check_out >= actual_check_in)
    )
);

-- payment statuses table
CREATE TABLE payment_statuses (
    payment_status_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- payments table
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    payment_date DATETIME NOT NULL,
	transaction_id VARCHAR(100) UNIQUE,
    total_amount DECIMAL(10, 2) NOT NULL,
    total_discount DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	rooms_booking_id INT NOT NULL,
    payment_status_id INT NOT NULL,
    FOREIGN KEY (payment_status_id) REFERENCES payment_statuses(payment_status_id),
    FOREIGN KEY (rooms_booking_id) REFERENCES rooms_bookings(rooms_booking_id),
    CONSTRAINT check_amount CHECK (total_amount > 0),
    CONSTRAINT check_discount CHECK (total_discount >= 0 AND total_discount < total_amount)
);