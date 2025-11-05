-- =============================================
-- FILE: functions.sql
-- FUNCTIONS FOR EXPENSE SHARING TRACKER
-- =============================================

USE expense_sharing_tracker;

DELIMITER //

-- =============================================
-- FUNCTION 1: Calculate total amount user owes in a group
-- =============================================
CREATE FUNCTION get_total_user_owes(
    p_user_id INT,
    p_group_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(amount), 0) INTO total
    FROM balances
    WHERE debtor_id = p_user_id
    AND group_id = p_group_id;
    
    RETURN total;
END//

-- =============================================
-- FUNCTION 2: Calculate total amount owed to user in a group
-- =============================================
CREATE FUNCTION get_total_owed_to_user(
    p_user_id INT,
    p_group_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(amount), 0) INTO total
    FROM balances
    WHERE creditor_id = p_user_id
    AND group_id = p_group_id;
    
    RETURN total;
END//

-- =============================================
-- FUNCTION 3: Get net balance for user in group
-- (Positive = others owe you, Negative = you owe others)
-- =============================================
CREATE FUNCTION get_user_net_balance(
    p_user_id INT,
    p_group_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE owed_to_user DECIMAL(10,2);
    DECLARE user_owes DECIMAL(10,2);
    
    SET owed_to_user = get_total_owed_to_user(p_user_id, p_group_id);
    SET user_owes = get_total_user_owes(p_user_id, p_group_id);
    
    RETURN owed_to_user - user_owes;
END//

-- =============================================
-- FUNCTION 4: Calculate user's total spending in group
-- =============================================
CREATE FUNCTION get_user_total_spending(
    p_user_id INT,
    p_group_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(amount), 0) INTO total
    FROM expenses
    WHERE created_by = p_user_id
    AND group_id = p_group_id;
    
    RETURN total;
END//

-- =============================================
-- FUNCTION 5: Calculate user's total share in group expenses
-- =============================================
CREATE FUNCTION get_user_total_share(
    p_user_id INT,
    p_group_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(es.amount), 0) INTO total
    FROM expense_shares es
    JOIN expenses e ON es.expense_id = e.id
    WHERE es.user_id = p_user_id
    AND e.group_id = p_group_id;
    
    RETURN total;
END//

-- =============================================
-- FUNCTION 6: Check if user is member of group
-- =============================================
CREATE FUNCTION is_group_member(
    p_user_id INT,
    p_group_id INT
)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE is_member BOOLEAN;
    
    SELECT EXISTS(
        SELECT 1 FROM members
        WHERE user_id = p_user_id
        AND group_id = p_group_id
    ) INTO is_member;
    
    RETURN is_member;
END//

-- =============================================
-- FUNCTION 7: Get group total expenses
-- =============================================
CREATE FUNCTION get_group_total_expenses(
    p_group_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(amount), 0) INTO total
    FROM expenses
    WHERE group_id = p_group_id;
    
    RETURN total;
END//

-- =============================================
-- FUNCTION 8: Get number of group members
-- =============================================
CREATE FUNCTION get_group_member_count(
    p_group_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE member_count INT;
    
    SELECT COUNT(*) INTO member_count
    FROM members
    WHERE group_id = p_group_id;
    
    RETURN member_count;
END//

-- =============================================
-- FUNCTION 9: Get balance between two users
-- =============================================
CREATE FUNCTION get_balance_between_users(
    p_debtor_id INT,
    p_creditor_id INT,
    p_group_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE balance DECIMAL(10,2);
    
    SELECT COALESCE(amount, 0) INTO balance
    FROM balances
    WHERE debtor_id = p_debtor_id
    AND creditor_id = p_creditor_id
    AND group_id = p_group_id;
    
    RETURN balance;
END//

-- =============================================
-- FUNCTION 10: Calculate user's expense count in group
-- =============================================
CREATE FUNCTION get_user_expense_count(
    p_user_id INT,
    p_group_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE expense_count INT;
    
    SELECT COUNT(*) INTO expense_count
    FROM expenses
    WHERE created_by = p_user_id
    AND group_id = p_group_id;
    
    RETURN expense_count;
END//

-- =============================================
-- FUNCTION 11: Check if expense belongs to group
-- =============================================
CREATE FUNCTION is_expense_in_group(
    p_expense_id INT,
    p_group_id INT
)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE is_in_group BOOLEAN;
    
    SELECT EXISTS(
        SELECT 1 FROM expenses
        WHERE id = p_expense_id
        AND group_id = p_group_id
    ) INTO is_in_group;
    
    RETURN is_in_group;
END//

-- =============================================
-- FUNCTION 12: Get user's share for specific expense
-- =============================================
CREATE FUNCTION get_user_share_in_expense(
    p_user_id INT,
    p_expense_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE share_amount DECIMAL(10,2);
    
    SELECT COALESCE(amount, 0) INTO share_amount
    FROM expense_shares
    WHERE user_id = p_user_id
    AND expense_id = p_expense_id;
    
    RETURN share_amount;
END//

DELIMITER ;