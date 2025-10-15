-- Check existing users
SELECT id, name, email, role, is_active, created_at FROM users ORDER BY created_at DESC;

-- Find the specific user causing conflict
SELECT * FROM users WHERE email = 'anna@gmail.com';

-- Option 1: Delete the conflicting user (if safe to do so)
-- DELETE FROM users WHERE email = 'anna@gmail.com';

-- Option 2: Update the existing user's email
-- UPDATE users SET email = 'anna.old@gmail.com' WHERE email = 'anna@gmail.com';

-- Check total user count
SELECT COUNT(*) as total_users FROM users;