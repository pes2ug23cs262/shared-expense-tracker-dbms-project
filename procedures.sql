-- =============================================
-- FILE: procedures.sql
-- STORED PROCEDURES FOR EXPENSE SHARING TRACKER
-- =============================================

USE expense_sharing_tracker;

DELIMITER //

-- =============================================
-- PROCEDURE 1: Add new expense with equal split
-- =============================================
CREATE PROCEDURE add_expense_equal_split(
    IN p_group_id INT,
    IN p_description TEXT,
    IN p_amount DECIMAL(10,2),
    IN p_currency VARCHAR(10),
    IN p_created_by INT
)
BEGIN
    DECLARE v_expense_id INT;
    DECLARE v_member_count INT;
    DECLARE v_share_amount DECIMAL(10,2);
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_user_id INT;
    
    DECLARE member_cursor CURSOR FOR
        SELECT user_id FROM members WHERE group_id = p_group_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Insert expense
    INSERT INTO expenses (group_id, description, amount, currency, created_by)
    VALUES (p_group_id, p_description, p_amount, p_currency, p_created_by);
    
    SET v_expense_id = LAST_INSERT_ID();
    
    -- Calculate share per member
    SELECT COUNT(*) INTO v_member_count FROM members WHERE group_id = p_group_id;
    SET v_share_amount = p_amount / v_member_count;
    
    -- Add shares for each member
    OPEN member_cursor;
    read_loop: LOOP
        FETCH member_cursor INTO v_user_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        INSERT INTO expense_shares (expense_id, user_id, amount)
        VALUES (v_expense_id, v_user_id, v_share_amount);
    END LOOP;
    CLOSE member_cursor;
    
    SELECT v_expense_id AS expense_id, 'Expense added successfully' AS message;
END//

-- =============================================
-- PROCEDURE 2: Add expense with custom split
-- =============================================
CREATE PROCEDURE add_expense_custom_split(
    IN p_group_id INT,
    IN p_description TEXT,
    IN p_amount DECIMAL(10,2),
    IN p_currency VARCHAR(10),
    IN p_created_by INT,
    IN p_shares JSON  -- Format: [{"user_id": 1, "amount": 100.00}, ...]
)
BEGIN
    DECLARE v_expense_id INT;
    DECLARE v_index INT DEFAULT 0;
    DECLARE v_user_id INT;
    DECLARE v_share_amount DECIMAL(10,2);
    DECLARE v_total_shares DECIMAL(10,2) DEFAULT 0;
    
    -- Insert expense
    INSERT INTO expenses (group_id, description, amount, currency, created_by)
    VALUES (p_group_id, p_description, p_amount, p_currency, p_created_by);
    
    SET v_expense_id = LAST_INSERT_ID();
    
    -- Add shares from JSON
    WHILE v_index < JSON_LENGTH(p_shares) DO
        SET v_user_id = JSON_EXTRACT(p_shares, CONCAT('$[', v_index, '].user_id'));
        SET v_share_amount = JSON_EXTRACT(p_shares, CONCAT('$[', v_index, '].amount'));
        
        INSERT INTO expense_shares (expense_id, user_id, amount)
        VALUES (v_expense_id, v_user_id, v_share_amount);
        
        SET v_total_shares = v_total_shares + v_share_amount;
        SET v_index = v_index + 1;
    END WHILE;
    
    -- Validate total
    IF v_total_shares != p_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sum of shares must equal expense amount';
    END IF;
    
    SELECT v_expense_id AS expense_id, 'Expense added successfully' AS message;
END//

-- =============================================
-- PROCEDURE 3: Settle balance between two users
-- =============================================
CREATE PROCEDURE settle_balance(
    IN p_group_id INT,
    IN p_from_user_id INT,
    IN p_to_user_id INT,
    IN p_amount DECIMAL(10,2),
    IN p_note TEXT
)
BEGIN
    DECLARE v_current_balance DECIMAL(10,2);
    
    -- Check current balance
    SELECT amount INTO v_current_balance
    FROM balances
    WHERE group_id = p_group_id
    AND debtor_id = p_from_user_id
    AND creditor_id = p_to_user_id;
    
    IF v_current_balance IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No balance found between these users';
    END IF;
    
    IF p_amount > v_current_balance THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment amount exceeds balance';
    END IF;
    
    -- Record payment
    INSERT INTO payments (group_id, from_user_id, to_user_id, amount, note)
    VALUES (p_group_id, p_from_user_id, p_to_user_id, p_amount, p_note);
    
    SELECT 'Payment recorded successfully' AS message;
END//

-- =============================================
-- PROCEDURE 4: Get user's balance summary in a group
-- =============================================
CREATE PROCEDURE get_user_balance_summary(
    IN p_user_id INT,
    IN p_group_id INT
)
BEGIN
    -- Amount user owes to others
    SELECT 
        'You owe' AS type,
        u.name AS person,
        b.amount
    FROM balances b
    JOIN users u ON b.creditor_id = u.id
    WHERE b.debtor_id = p_user_id
    AND b.group_id = p_group_id
    AND b.amount > 0
    
    UNION ALL
    
    -- Amount others owe to user
    SELECT 
        'Owes you' AS type,
        u.name AS person,
        b.amount
    FROM balances b
    JOIN users u ON b.debtor_id = u.id
    WHERE b.creditor_id = p_user_id
    AND b.group_id = p_group_id
    AND b.amount > 0;
END//

-- =============================================
-- PROCEDURE 5: Get group expense summary
-- =============================================
CREATE PROCEDURE get_group_summary(
    IN p_group_id INT
)
BEGIN
    SELECT 
        g.name AS group_name,
        g.description,
        COUNT(DISTINCT m.user_id) AS member_count,
        COUNT(DISTINCT e.id) AS expense_count,
        COALESCE(SUM(e.amount), 0) AS total_spent,
        g.created_at
    FROM expense_groups g
    LEFT JOIN members m ON g.id = m.group_id
    LEFT JOIN expenses e ON g.id = e.group_id
    WHERE g.id = p_group_id
    GROUP BY g.id;
END//

-- =============================================
-- PROCEDURE 6: Get user's expense history in group
-- =============================================
CREATE PROCEDURE get_user_expenses_in_group(
    IN p_user_id INT,
    IN p_group_id INT
)
BEGIN
    SELECT 
        e.id,
        e.description,
        e.amount AS total_amount,
        es.amount AS your_share,
        u.name AS paid_by,
        e.created_at
    FROM expenses e
    JOIN expense_shares es ON e.id = es.expense_id
    JOIN users u ON e.created_by = u.id
    WHERE es.user_id = p_user_id
    AND e.group_id = p_group_id
    ORDER BY e.created_at DESC;
END//

-- =============================================
-- PROCEDURE 7: Simplify debts in a group
-- (Minimize number of transactions needed)
-- =============================================
CREATE PROCEDURE simplify_group_debts(
    IN p_group_id INT
)
BEGIN
    -- Calculate net balance for each user
    SELECT 
        COALESCE(creditor.user_id, debtor.user_id) AS user_id,
        u.name,
        COALESCE(creditor.total_credit, 0) - COALESCE(debtor.total_debt, 0) AS net_balance
    FROM users u
    LEFT JOIN (
        SELECT creditor_id AS user_id, SUM(amount) AS total_credit
        FROM balances
        WHERE group_id = p_group_id
        GROUP BY creditor_id
    ) creditor ON u.id = creditor.user_id
    LEFT JOIN (
        SELECT debtor_id AS user_id, SUM(amount) AS total_debt
        FROM balances
        WHERE group_id = p_group_id
        GROUP BY debtor_id
    ) debtor ON u.id = debtor.user_id
    WHERE COALESCE(creditor.total_credit, 0) - COALESCE(debtor.total_debt, 0) != 0
    ORDER BY net_balance DESC;
END//

-- =============================================
-- PROCEDURE 8: Delete expense and update balances
-- =============================================
CREATE PROCEDURE delete_expense(
    IN p_expense_id INT
)
BEGIN
    DECLARE v_group_id INT;
    DECLARE v_created_by INT;
    
    -- Get expense details
    SELECT group_id, created_by INTO v_group_id, v_created_by
    FROM expenses
    WHERE id = p_expense_id;
    
    -- Reverse balances for each share
    UPDATE balances b
    INNER JOIN expense_shares es ON es.user_id = b.debtor_id
    SET b.amount = b.amount - es.amount
    WHERE es.expense_id = p_expense_id
    AND b.group_id = v_group_id
    AND b.creditor_id = v_created_by
    AND es.user_id != v_created_by;
    
    -- Delete zero balances
    DELETE FROM balances
    WHERE group_id = v_group_id AND amount <= 0;
    
    -- Delete expense (cascade will delete shares)
    DELETE FROM expenses WHERE id = p_expense_id;
    
    SELECT 'Expense deleted successfully' AS message;
END//

DELIMITER ;