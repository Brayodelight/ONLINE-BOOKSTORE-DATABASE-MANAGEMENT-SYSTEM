-- DATABASE CREATION
-- ===================================================================

-- Drop database if it exists and create a new one
DROP DATABASE IF EXISTS bookstore;
CREATE DATABASE bookstore;
USE bookstore;

-- ===================================================================
-- TABLE CREATION
-- ===================================================================

-- Publishers Table
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    website VARCHAR(100),
    founded_year INT,
    CONSTRAINT chk_founded_year CHECK (founded_year > 1400)
) COMMENT 'Stores information about book publishers';

-- Authors Table
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unq_author_name UNIQUE (first_name, last_name, birth_date)
) COMMENT 'Stores information about book authors';

-- Categories Table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INT,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) COMMENT 'Stores book categories/genres with hierarchical structure';

-- Books Table
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    publisher_id INT,
    publication_date DATE,
    edition VARCHAR(20),
    pages INT,
    language VARCHAR(50) DEFAULT 'English',
    price DECIMAL(10,2) NOT NULL,
    category_id INT,
    description TEXT,
    cover_image VARCHAR(255),
    stock_quantity INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_price CHECK (price >= 0),
    CONSTRAINT chk_pages CHECK (pages > 0),
    CONSTRAINT chk_stock CHECK (stock_quantity >= 0)
) COMMENT 'Stores detailed information about books in inventory';

-- Book-Authors Junction Table (Many-to-Many)
CREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    role VARCHAR(50) DEFAULT 'Author', -- e.g., Author, Editor, Translator
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT 'Junction table for many-to-many relationship between books and authors';

-- Customers Table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
) COMMENT 'Stores customer account information';

-- Reviews Table
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating INT NOT NULL,
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT unq_customer_book_review UNIQUE (customer_id, book_id)
) COMMENT 'Stores customer reviews for books';

-- Orders Table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    shipping_address VARCHAR(255) NOT NULL,
    billing_address VARCHAR(255) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    order_status ENUM('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled') DEFAULT 'Pending',
    tracking_number VARCHAR(100),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_total_amount CHECK (total_amount >= 0)
) COMMENT 'Stores order header information';

-- Order Items Table
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    book_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount DECIMAL(5,2) DEFAULT 0,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_quantity CHECK (quantity > 0),
    CONSTRAINT chk_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_discount CHECK (discount >= 0 AND discount <= 100)
) COMMENT 'Stores individual line items within orders';

-- ===================================================================
-- INDEXES
-- ===================================================================

-- Indexes for books table
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_books_price ON books(price);
CREATE INDEX idx_books_publication_date ON books(publication_date);

-- Indexes for customers table
CREATE INDEX idx_customers_name ON customers(last_name, first_name);
CREATE INDEX idx_customers_location ON customers(country, state, city);

-- Indexes for orders table
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(order_status);

-- Indexes for order items table
CREATE INDEX idx_order_items_book ON order_items(book_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- Indexes for reviews table
CREATE INDEX idx_reviews_book ON reviews(book_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_date ON reviews(review_date);

-- ===================================================================
-- VIEWS
-- ===================================================================

-- Book details view with publisher and category information
CREATE VIEW vw_book_details AS
SELECT 
    b.book_id,
    b.isbn,
    b.title,
    b.edition,
    b.publication_date,
    b.language,
    b.pages,
    b.price,
    b.stock_quantity,
    p.name AS publisher_name,
    c.name AS category_name,
    b.description
FROM books b
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
LEFT JOIN categories c ON b.category_id = c.category_id;

-- Author books view
CREATE VIEW vw_author_books AS
SELECT 
    a.author_id,
    CONCAT(a.first_name, ' ', a.last_name) AS author_name,
    b.book_id,
    b.title,
    b.publication_date,
    b.isbn
FROM authors a
JOIN book_authors ba ON a.author_id = ba.author_id
JOIN books b ON ba.book_id = b.book_id
ORDER BY a.last_name, a.first_name, b.publication_date DESC;

-- Customer order history view
CREATE VIEW vw_customer_orders AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status,
    COUNT(oi.order_item_id) AS total_items
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, o.order_id
ORDER BY o.order_date DESC;

-- Book reviews summary view
CREATE VIEW vw_book_reviews_summary AS
SELECT 
    b.book_id,
    b.title,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.rating), 2) AS average_rating
FROM books b
LEFT JOIN reviews r ON b.book_id = r.book_id
GROUP BY b.book_id
ORDER BY average_rating DESC, total_reviews DESC;

-- Book inventory status view
CREATE VIEW vw_inventory_status AS
SELECT 
    b.book_id,
    b.isbn,
    b.title,
    p.name AS publisher,
    b.stock_quantity,
    CASE
        WHEN b.stock_quantity = 0 THEN 'Out of Stock'
        WHEN b.stock_quantity < 5 THEN 'Low Stock'
        WHEN b.stock_quantity < 20 THEN 'Medium Stock'
        ELSE 'Good Stock'
    END AS stock_status
FROM books b
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
ORDER BY b.stock_quantity;

-- ===================================================================
-- TRIGGERS
-- ===================================================================

-- Update stock quantity when an order is placed
DELIMITER //
CREATE TRIGGER trg_after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    -- Decrease stock quantity
    UPDATE books
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE book_id = NEW.book_id;
END //
DELIMITER ;

-- Update total order amount when an order item is added
DELIMITER //
CREATE TRIGGER trg_after_order_item_insert_update_total
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    -- Update order total
    UPDATE orders
    SET total_amount = total_amount + (NEW.quantity * NEW.unit_price * (1 - NEW.discount/100))
    WHERE order_id = NEW.order_id;
END //
DELIMITER ;

-- Prevent deleting books that are in active orders
DELIMITER //
CREATE TRIGGER trg_before_book_delete
BEFORE DELETE ON books
FOR EACH ROW
BEGIN
    DECLARE active_orders INT;
    
    -- Check if book is in any active orders
    SELECT COUNT(*) INTO active_orders
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE oi.book_id = OLD.book_id
    AND o.order_status IN ('Pending', 'Processing', 'Shipped');
    
    IF active_orders > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete book that is in active orders';
    END IF;
END //
DELIMITER ;

-- ===================================================================
-- STORED PROCEDURES
-- ===================================================================

-- Procedure to place a new order
DELIMITER //
CREATE PROCEDURE sp_place_order(
    IN p_customer_id INT,
    IN p_shipping_address VARCHAR(255),
    IN p_billing_address VARCHAR(255),
    IN p_payment_method VARCHAR(50),
    OUT p_order_id INT
)
BEGIN
    -- Insert the order
    INSERT INTO orders (
        customer_id,
        shipping_address,
        billing_address,
        payment_method
    ) VALUES (
        p_customer_id,
        p_shipping_address,
        p_billing_address,
        p_payment_method
    );
    
    -- Get the order ID
    SET p_order_id = LAST_INSERT_ID();
END //
DELIMITER ;

-- Procedure to add a book to an order
DELIMITER //
CREATE PROCEDURE sp_add_order_item(
    IN p_order_id INT,
    IN p_book_id INT,
    IN p_quantity INT,
    IN p_discount DECIMAL(5,2)
)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock INT;
    
    -- Get the current price and stock quantity
    SELECT price, stock_quantity INTO v_price, v_stock
    FROM books
    WHERE book_id = p_book_id;
    
    -- Check if we have enough stock
    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Not enough items in stock';
    ELSE
        -- Add the order item
        INSERT INTO order_items (
            order_id,
            book_id,
            quantity,
            unit_price,
            discount
        ) VALUES (
            p_order_id,
            p_book_id,
            p_quantity,
            v_price,
            p_discount
        );
    END IF;
END //
DELIMITER ;

-- Procedure to update order status
DELIMITER //
CREATE PROCEDURE sp_update_order_status(
    IN p_order_id INT,
    IN p_new_status VARCHAR(50),
    IN p_tracking_number VARCHAR(100)
)
BEGIN
    UPDATE orders
    SET order_status = p_new_status,
        tracking_number = CASE 
            WHEN p_tracking_number IS NOT NULL THEN p_tracking_number
            ELSE tracking_number
        END
    WHERE order_id = p_order_id;
END //
DELIMITER ;

-- Procedure to search for books by various criteria
DELIMITER //
CREATE PROCEDURE sp_search_books(
    IN p_title VARCHAR(255),
    IN p_author_name VARCHAR(100),
    IN p_category_id INT,
    IN p_min_price DECIMAL(10,2),
    IN p_max_price DECIMAL(10,2)
)
BEGIN
    SELECT DISTINCT 
        b.book_id,
        b.isbn,
        b.title,
        b.publication_date,
        b.price,
        b.stock_quantity,
        p.name AS publisher_name,
        c.name AS category_name
    FROM books b
    LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
    LEFT JOIN categories c ON b.category_id = c.category_id
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    WHERE 
        (p_title IS NULL OR b.title LIKE CONCAT('%', p_title, '%'))
        AND (p_author_name IS NULL OR CONCAT(a.first_name, ' ', a.last_name) LIKE CONCAT('%', p_author_name, '%'))
        AND (p_category_id IS NULL OR b.category_id = p_category_id)
        AND (p_min_price IS NULL OR b.price >= p_min_price)
        AND (p_max_price IS NULL OR b.price <= p_max_price)
    ORDER BY b.title;
END //
DELIMITER ;

-- ===================================================================
-- SAMPLE DATA INSERTION
-- ===================================================================

-- Insert sample data for publishers
INSERT INTO publishers (name, address, phone, email, website, founded_year) VALUES
('Penguin Random House', '1745 Broadway, New York, NY 10019', '212-782-9000', 'info@penguinrandomhouse.com', 'www.penguinrandomhouse.com', 1925),
('HarperCollins', '195 Broadway, New York, NY 10007', '212-207-7000', 'info@harpercollins.com', 'www.harpercollins.com', 1817),
('Simon & Schuster', '1230 Avenue of the Americas, New York, NY 10020', '212-698-7000', 'info@simonandschuster.com', 'www.simonandschuster.com', 1924),
('Macmillan Publishers', '120 Broadway, New York, NY 10271', '646-307-5151', 'info@macmillan.com', 'www.macmillan.com', 1843),
('Hachette Book Group', '1290 Avenue of the Americas, New York, NY 10104', '212-364-1100', 'info@hbgusa.com', 'www.hachettebookgroup.com', 1837);

-- Insert sample data for categories
INSERT INTO categories (name, description) VALUES
('Fiction', 'Novels, short stories and other fictional works'),
('Non-Fiction', 'Factual content including biography, history, and essays'),
('Mystery', 'Mystery novels and detective fiction'),
('Science Fiction', 'Fiction dealing with imaginative content such as futuristic settings'),
('Fantasy', 'Fiction involving magical elements and imaginary worlds'),
('Biography', 'Accounts of people\'s lives written by another person'),
('History', 'Books about past events'),
('Technology', 'Books about computers, software, and related topics'),
('Self-Help', 'Books aimed at helping readers solve personal problems'),
('Business', 'Books about commerce, management, and economics');

-- Create subcategories by setting parent_category_id
UPDATE categories SET parent_category_id = 1 WHERE name IN ('Mystery', 'Science Fiction', 'Fantasy');
UPDATE categories SET parent_category_id = 2 WHERE name IN ('Biography', 'History', 'Technology', 'Self-Help', 'Business');

-- Insert sample data for authors
INSERT INTO authors (first_name, last_name, birth_date, nationality, biography) VALUES
('J.K.', 'Rowling', '1965-07-31', 'British', 'British author best known for the Harry Potter series'),
('Stephen', 'King', '1947-09-21', 'American', 'American author of horror, supernatural fiction, suspense, and fantasy novels'),
('Agatha', 'Christie', '1890-09-15', 'British', 'British writer known for her 66 detective novels and 14 short story collections'),
('Michelle', 'Obama', '1964-01-17', 'American', 'American attorney and author who was the First Lady of the United States from 2009 to 2017'),
('Yuval Noah', 'Harari', '1976-02-24', 'Israeli', 'Israeli historian and professor, author of Sapiens and Homo Deus'),
('George R.R.', 'Martin', '1948-09-20', 'American', 'American novelist and short story writer, screenwriter, and television producer'),
('J.R.R.', 'Tolkien', '1892-01-03', 'British', 'English writer, poet, philologist, and academic, author of The Lord of the Rings'),
('Jane', 'Austen', '1775-12-16', 'British', 'English novelist known primarily for her six major novels'),
('Malcolm', 'Gladwell', '1963-09-03', 'Canadian', 'Canadian journalist, author, and public speaker'),
('Margaret', 'Atwood', '1939-11-18', 'Canadian', 'Canadian poet, novelist, literary critic, essayist, and environmental activist');

-- Insert sample data for books
INSERT INTO books (isbn, title, publisher_id, publication_date, edition, pages, language, price, category_id, description, stock_quantity) VALUES
('9780545010221', 'Harry Potter and the Deathly Hallows', 1, '2007-07-21', '1st', 607, 'English', 24.99, 5, 'The seventh and final novel of the Harry Potter series.', 150),
('9781501175466', 'The Outsider', 2, '2018-05-22', '1st', 576, 'English', 19.99, 3, 'A horror novel about an investigation into the gruesome murder of a young boy.', 85),
('9780062073488', 'Murder on the Orient Express', 2, '1934-01-01', 'Reprint', 256, 'English', 14.99, 3, 'Hercule Poirot solves a murder on a snowbound train.', 70),
('9781524763138', 'Becoming', 3, '2018-11-13', '1st', 448, 'English', 32.50, 6, 'Memoir of former First Lady of the United States Michelle Obama.', 120),
('9780062316110', 'Sapiens: A Brief History of Humankind', 2, '2015-02-10', '1st', 464, 'English', 24.99, 7, 'A history of humankind from the Stone Age to the present day.', 90),
('9780553103540', 'A Game of Thrones', 1, '1996-08-01', '1st', 694, 'English', 18.99, 5, 'The first novel in the A Song of Ice and Fire fantasy series.', 110),
('9780618640157', 'The Lord of the Rings', 4, '1954-07-29', 'Anniversary', 1178, 'English', 29.99, 5, 'Epic fantasy novel in three volumes.', 65),
('9780141439518', 'Pride and Prejudice', 1, '1813-01-28', 'Reprint', 432, 'English', 9.99, 1, 'Novel of manners by Jane Austen.', 40),
('9780316017923', 'Outliers: The Story of Success', 5, '2008-11-18', '1st', 336, 'English', 16.99, 9, 'Examination of factors that contribute to high levels of success.', 55),
('9780385543781', 'The Handmaid\'s Tale', 3, '1985-06-01', 'Reprint', 311, 'English', 15.99, 4, 'Dystopian novel set in a near-future patriarchal society.', 78);

-- Insert book-author relationships
INSERT INTO book_authors (book_id, author_id, role) VALUES
(1, 1, 'Author'),
(2, 2, 'Author'),
(3, 3, 'Author'),
(4, 4, 'Author'),
(5, 5, 'Author'),
(6, 6, 'Author'),
(7, 7, 'Author'),
(8, 8, 'Author'),
(9, 9, 'Author'),
(10, 10, 'Author');

-- Insert sample data for customers
INSERT INTO customers (first_name, last_name, email, password_hash, phone, address_line1, city, state, postal_code, country) VALUES
('John', 'Smith', 'john.smith@example.com', 'hashed_password_1', '555-123-4567', '123 Main St', 'New York', 'NY', '10001', 'USA'),
('Sarah', 'Johnson', 'sarah.j@example.com', 'hashed_password_2', '555-234-5678', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA'),
('David', 'Williams', 'davidw@example.com', 'hashed_password_3', '555-345-6789', '789 Pine St', 'Chicago', 'IL', '60007', 'USA'),
('Emily', 'Brown', 'emily.brown@example.com', 'hashed_password_4', '555-456-7890', '101 Maple Dr', 'Houston', 'TX', '77001', 'USA'),
('Michael', 'Jones', 'mjones@example.com', 'hashed_password_5', '555-567-8901', '202 Cedar Ln', 'Philadelphia', 'PA', '19019', 'USA');

-- Insert sample data for orders
INSERT INTO orders (customer_id, order_date, shipping_address, billing_address, payment_method, order_status) VALUES
(1, '2023-01-15 10:30:00', '123 Main St, New York, NY 10001', '123 Main St, New York, NY 10001', 'Credit Card', 'Delivered'),
(2, '2023-02-20 14:45:00', '456 Oak Ave, Los Angeles, CA 90001', '456 Oak Ave, Los Angeles, CA 90001', 'PayPal', 'Shipped'),
(3, '2023-03-10 09:15:00', '789 Pine St, Chicago, IL 60007', '789 Pine St, Chicago, IL 60007', 'Credit Card', 'Processing'),
(4, '2023-04-05 16:20:00', '101 Maple Dr, Houston, TX 77001', '101 Maple Dr, Houston, TX 77001', 'Credit Card', 'Delivered'),
(5, '2023-05-12 11:00:00', '202 Cedar Ln, Philadelphia, PA 19019', '202 Cedar Ln, Philadelphia, PA 19019', 'PayPal', 'Pending');

-- Insert sample data for order items
INSERT INTO order_items (order_id, book_id, quantity, unit_price, discount) VALUES
(1, 1, 1, 24.99, 0),
(1, 3, 1, 14.99, 0),
(2, 4, 1, 32.50, 5),
(2, 5, 2, 24.99, 10),
(3, 7, 1, 29.99, 0),
(3, 8, 1, 9.99, 0),
(4, 2, 1, 19.99, 0),
(4, 6, 1, 18.99, 5),
(5, 9, 1, 16.99, 0),
(5, 10, 1, 15.99, 0);

-- Insert sample data for reviews
INSERT INTO reviews (book_id, customer_id, rating, review_text) VALUES
(1, 1, 5, 'A perfect ending to an amazing series!'),
(3, 1, 4, 'Classic mystery that still holds up today.'),
(4, 2, 5, 'Inspirational and beautifully written memoir.'),
(5, 2, 5, 'Fascinating overview of human history.'),
(7, 3, 5, 'The definitive fantasy epic.'),
(2, 4, 4, 'Gripping thriller with unexpected twists.'),
(6, 4, 5, 'Complex characters and intricate plot.'),
(9, 5, 4, 'Thought-provoking analysis of success.'),
(10, 5, 5, 'Chilling and prophetic.');
