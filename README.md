PROJECT TITLE: Online Bookstore Database Management System

DESCRIPTION:
This database system manages an online bookstore's operations including inventory management,
customer accounts, orders processing, and book categorization. The system tracks books,
authors, publishers, customers, orders, and reviews in a relational structure.

HOW TO RUN/SETUP:
1. Import this SQL file into your MySQL environment:
   - Using MySQL Workbench: Server > Data Import > Import from Self-Contained File
   - Using command line: mysql -u username -p < online_bookstore.sql
2. Connect to the database: USE bookstore;
3. Run queries against the tables

ERD DESCRIPTION:
The database contains these main entities with relationships:
- Books (central entity, connected to Authors, Publishers, Categories)
- Customers (can place Orders and write Reviews)
- Orders (contain OrderItems which reference Books)
- Many-to-many relationship between Books and Authors
- One-to-many relationship between Publishers and Books
- One-to-many relationship between Customers and Orders/Reviews

DATABASE SCHEMA OVERVIEW:
- publishers: Stores book publisher information
- authors: Stores author information
- categories: Stores book categories/genres
- books: Central table storing book information
- book_authors: Junction table for many-to-many relationship between books and authors
- customers: Stores customer account information
- reviews: Stores customer reviews for books
- orders: Stores order header information
- order_items: Stores individual items within orders
