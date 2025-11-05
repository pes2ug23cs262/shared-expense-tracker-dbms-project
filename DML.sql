USE expense_sharing_tracker;

-- =============================================
-- 1️⃣ INSERT SAMPLE USERS
-- =============================================
INSERT INTO users (name, email, password_hash)
VALUES
('Hema', 'hema@example.com', 'hash1'),
('Kashvi', 'ravi@example.com', 'hash2'),
('Priya', 'priya@example.com', 'hash3'),
('Arun', 'arun@example.com', 'hash4');

-- =============================================
-- 2️⃣ INSERT EXPENSE GROUPS
-- =============================================
INSERT INTO expense_groups (name, description, created_by)
VALUES
('Goa Trip', 'Trip to Goa with friends', 1),
('Flat Rent', 'Monthly apartment rent', 2);

-- =============================================
-- 3️⃣ INSERT MEMBERS (who belongs to which group)
-- =============================================
INSERT INTO members (group_id, user_id)
VALUES
(1, 1),  -- Hema created Goa Trip
(1, 2),  -- Ravi
(1, 3),  -- Priya
(2, 2),  -- Ravi created Flat Rent
(2, 4);  -- Arun

-- =============================================
-- 4️⃣ INSERT EXPENSES
-- =============================================
INSERT INTO expenses (group_id, description, amount, currency, created_by)
VALUES
(1, 'Hotel Booking', 6000.00, 'INR', 1),
(1, 'Dinner', 2000.00, 'INR', 2),
(2, 'Flat Rent - March', 10000.00, 'INR', 2);

-- =============================================
-- 5️⃣ INSERT EXPENSE SHARES (who owes how much for each expense)
-- =============================================
-- Expense 1: Hotel Booking (6000 split equally among 3 members)
INSERT INTO expense_shares (expense_id, user_id, amount)
VALUES
(1, 1, 2000.00),
(1, 2, 2000.00),
(1, 3, 2000.00);

-- Expense 2: Dinner (2000 split among 3)
INSERT INTO expense_shares (expense_id, user_id, amount)
VALUES
(2, 1, 666.67),
(2, 2, 666.67),
(2, 3, 666.66);

-- Expense 3: Rent (10000 split between 2)
INSERT INTO expense_shares (expense_id, user_id, amount)
VALUES
(3, 2, 5000.00),
(3, 4, 5000.00);

-- =============================================
-- 6️⃣ INSERT BALANCES
-- =============================================
INSERT INTO balances (group_id, debtor_id, creditor_id, amount)
VALUES
(1, 2, 1, 1333.33),   -- Ravi owes Hema
(1, 3, 1, 1333.33),   -- Priya owes Hema
(2, 4, 2, 5000.00);   -- Arun owes Ravi

-- =============================================
-- 7️⃣ INSERT PAYMENTS
-- =============================================
INSERT INTO payments (group_id, from_user_id, to_user_id, amount, currency, note)
VALUES
(1, 2, 1, 1000.00, 'INR', 'Partial payment for hotel'),
(2, 4, 2, 5000.00, 'INR', 'Rent paid');

-- =============================================
-- ✅ SAMPLE CRUD OPERATIONS
-- =============================================

-- READ all expenses with creator and group info (JOIN example)
SELECT e.id, e.description, e.amount, g.name AS group_name, u.name AS created_by
FROM expenses e
JOIN expense_groups g ON e.group_id = g.id
JOIN users u ON e.created_by = u.id;

-- UPDATE example — change group name
UPDATE expense_groups
SET name = 'Goa Adventure Trip'
WHERE id = 1;

-- DELETE example — delete a payment
DELETE FROM payments
WHERE id = 1;

-- AGGREGATE example — total expenses per group
SELECT g.name AS group_name, SUM(e.amount) AS total_spent
FROM expenses e
JOIN expense_groups g ON e.group_id = g.id
GROUP BY g.id;




