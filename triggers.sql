-- =============================================
-- FILE: triggers.sql
-- TRIGGERS FOR EXPENSE SHARING TRACKER
-- =============================================

USE expense_sharing_tracker;

DELIMITER //

-- =============================================
-- TRIGGER 1: Auto-add creator as member when group is created
-- =============================================
CREATE TRIGGER after_group_insert
AFTER INSERT ON expense_groups
FOR EACH ROW
BEGIN
    INSERT INTO members (group_id, user_id)
    VALUES (NEW.id, NEW.created_by);
END//

-- =============================================
-- TRIGGER 2: Validate expense shares don't exceed total
-- =============================================
CREATE TRIGGER after_expense_share_insert
AFTER INSERT ON expense_shares
FOR EACH ROW
BEGIN
    DECLARE total_shares DECIMAL(10, 2);
    DECLARE expense_total DECIMAL(10, 2);
    
    SELECT SUM(amount) INTO total_shares
    FROM expense_shares
    WHERE expense_id = NEW.expense_id;
    
    SELECT amount INTO expense_total
    FROM expenses
    WHERE id = NEW.expense_id;
    
    IF total_shares > expense_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total shares exceed expense amount';
    END IF;
END//

CREATE TRIGGER after_expense_share_update
AFTER UPDATE ON expense_shares
FOR EACH ROW
BEGIN
    DECLARE total_shares DECIMAL(10, 2);
    DECLARE expense_total DECIMAL(10, 2);
    
    SELECT SUM(amount) INTO total_shares
    FROM expense_shares
    WHERE expense_id = NEW.expense_id;
    
    SELECT amount INTO expense_total
    FROM expenses
    WHERE id = NEW.expense_id;
    
    IF total_shares > expense_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total shares exceed expense amount';
    END IF;
END//

-- =============================================
-- TRIGGER 3: Update balances when expense share is added
-- =============================================
CREATE TRIGGER after_expense_share_insert_update_balance
AFTER INSERT ON expense_shares
FOR EACH ROW
BEGIN
    DECLARE payer_id INT;
    DECLARE group_id_var INT;
    
    -- Get who paid for this expense
    SELECT created_by, group_id INTO payer_id, group_id_var
    FROM expenses
    WHERE id = NEW.expense_id;
    
    -- If the share owner is not the payer, update balance
    IF NEW.user_id != payer_id THEN
        -- Check if balance record exists
        IF EXISTS (
            SELECT 1 FROM balances
            WHERE group_id = group_id_var
            AND debtor_id = NEW.user_id
            AND creditor_id = payer_id
        ) THEN
            -- Update existing balance
            UPDATE balances
            SET amount = amount + NEW.amount
            WHERE group_id = group_id_var
            AND debtor_id = NEW.user_id
            AND creditor_id = payer_id;
        ELSE
            -- Insert new balance
            INSERT INTO balances (group_id, debtor_id, creditor_id, amount)
            VALUES (group_id_var, NEW.user_id, payer_id, NEW.amount);
        END IF;
    END IF;
END//

-- =============================================
-- TRIGGER 4: Update balances when payment is made
-- =============================================
CREATE TRIGGER after_payment_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    -- Reduce the balance when payment is made
    UPDATE balances
    SET amount = amount - NEW.amount
    WHERE group_id = NEW.group_id
    AND debtor_id = NEW.from_user_id
    AND creditor_id = NEW.to_user_id
    AND amount > 0;
    
    -- Delete balance if it becomes zero or negative
    DELETE FROM balances
    WHERE group_id = NEW.group_id
    AND debtor_id = NEW.from_user_id
    AND creditor_id = NEW.to_user_id
    AND amount <= 0;
END//

-- =============================================
-- TRIGGER 5: Validate user is member of group before adding expense
-- =============================================
CREATE TRIGGER before_expense_insert
BEFORE INSERT ON expenses
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM members
        WHERE group_id = NEW.group_id
        AND user_id = NEW.created_by
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User must be a member of the group to add expenses';
    END IF;
END//

-- =============================================
-- TRIGGER 6: Validate user is member before adding expense share
-- =============================================
CREATE TRIGGER before_expense_share_insert
BEFORE INSERT ON expense_shares
FOR EACH ROW
BEGIN
    DECLARE expense_group_id INT;
    
    SELECT group_id INTO expense_group_id
    FROM expenses
    WHERE id = NEW.expense_id;
    
    IF NOT EXISTS (
        SELECT 1 FROM members
        WHERE group_id = expense_group_id
        AND user_id = NEW.user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User must be a member of the group to have expense share';
    END IF;
END//

-- =============================================
-- TRIGGER 7: Validate payment users are members of group
-- =============================================
CREATE TRIGGER before_payment_insert
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM members
        WHERE group_id = NEW.group_id
        AND user_id = NEW.from_user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payer must be a member of the group';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM members
        WHERE group_id = NEW.group_id
        AND user_id = NEW.to_user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payee must be a member of the group';
    END IF;
END//

DELIMITER ;