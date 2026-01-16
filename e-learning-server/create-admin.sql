-- Create Admin User for E-Learning Platform
-- Password: Admin@123 (hashed with BCrypt workFactor 12)

USE ElearningDB;
GO

-- Check if admin already exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@skvi.vn')
BEGIN
    INSERT INTO Users (
        Id,
        Email,
        PasswordHash,
        FullName,
        Phone,
        Role,
        Status,
        IsEmailVerified,
        IsDeleted,
        CreatedAt,
        UpdatedAt
    )
    VALUES (
        NEWID(),
        'admin@skvi.vn',
        '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeYGPZKjUjTRHjnQO', -- Admin@123
        'System Administrator',
        '+84912345678',
        'ADMIN',
        'ACTIVE',
        1,
        0,
        GETUTCDATE(),
        GETUTCDATE()
    );
    
    PRINT 'Admin user created successfully!';
    PRINT 'Email: admin@skvi.vn';
    PRINT 'Password: Admin@123';
END
ELSE
BEGIN
    PRINT 'Admin user already exists!';
END
GO
