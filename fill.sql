-- Dodawanie podmiotów
DECLARE @i INT = 1;
WHILE @i <= 10
BEGIN
    INSERT INTO Tenants (TenantName)
    VALUES ( CONCAT('Tenant_', @i) );
    SET @i += 1;
END

GO

-- Dodawanie u¿ytkowników
DECLARE @TenantID INT = 1;
WHILE @TenantID <= 10
BEGIN
    DECLARE @i INT = 1;
    WHILE @i <= 100
    BEGIN
        INSERT INTO Users (TenantID, UserName, UserRole, SupervisorID)
        VALUES (
			@TenantID,
			CONCAT('User_', @TenantID, '_', @i),
			CASE WHEN (@i-1) % 15 = 0 THEN 'manager' ELSE 'employee' END,
			CASE WHEN (@i-1) % 15 != 0 THEN (SELECT MAX(UserId) FROM Users WHERE UserRole = 'manager') ELSE NULL END
		);
        SET @i += 1;
    END
    SET @TenantID += 1;
END

GO

-- Przygotuj wzór zestawu zadañ
DROP TABLE IF EXISTS #temp_tasks;
CREATE TABLE #temp_tasks (
    Header NVARCHAR(255),
    Priority INT,
    Status INT,
    Description NVARCHAR(MAX),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NULL,
);

DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO #temp_tasks (Header, Priority, Status, Description, CreatedAt)
    VALUES (CONCAT('Task ', @i), RAND()*(5-1)+1, RAND()*(3-1)+1, 'Opis zadania', GETDATE());
	SET @i += 1;
END

GO

-- Dodaj zadania
DECLARE @UserId int;
DECLARE @TenantId int;

DECLARE db_cursor CURSOR FOR
SELECT UserId, TenantId FROM Users WHERE UserRole = 'employee';

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @UserId, @TenantId

WHILE @@FETCH_STATUS = 0  
BEGIN  
	INSERT INTO Tasks (OwnerId, TenantId, Header, Priority, Status, Description, CreatedAt)
	SELECT @UserId as OwnerId, @TenantId as TenantId, Header, Priority, Status, Description, CreatedAt
	FROM #temp_tasks;


	FETCH NEXT FROM db_cursor INTO @UserId, @TenantId
END

CLOSE db_cursor  
DEALLOCATE db_cursor;