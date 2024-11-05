DROP PROCEDURE IF EXISTS sp_GetTaskStatistics;
DROP PROCEDURE IF EXISTS sp_AddTask;
DROP PROCEDURE IF EXISTS sp_UpdateTask;

DROP TABLE IF EXISTS TaskHistory;
DROP TABLE IF EXISTS Tasks;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Tenants;

CREATE TABLE Tenants (
    TenantID INT IDENTITY(1,1) PRIMARY KEY,
    TenantName NVARCHAR(255) NOT NULL
);

CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    TenantID INT FOREIGN KEY REFERENCES Tenants(TenantID),
    UserName NVARCHAR(255) NOT NULL,
    UserRole NVARCHAR(50) NOT NULL CHECK (UserRole IN ('employee', 'manager')),  -- mo¿na zmieniæ na klucz obcy do tabeli z rolami
    SupervisorID INT NULL,
);

CREATE TABLE Tasks (
    TaskID BIGINT IDENTITY(1,1) PRIMARY KEY,
    TenantID INT FOREIGN KEY REFERENCES Tenants(TenantID),
    OwnerID INT FOREIGN KEY REFERENCES Users(UserID),
    Header NVARCHAR(255) NOT NULL,
    Priority INT NOT NULL CHECK (Priority BETWEEN 1 AND 5), -- mo¿na zmieniæ na klucz obcy do tabeli z priorytetami
    Status INT NOT NULL CHECK (Status BETWEEN 1 AND 3),  -- mo¿na zmieniæ na klucz obcy do tabeli ze statusami
    Description NVARCHAR(MAX),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NULL,
);

CREATE NONCLUSTERED INDEX NI_Tasks_CreatedAt ON Tasks(CreatedAt);
CREATE NONCLUSTERED INDEX NI_Tasks_Status ON Tasks(Status);
CREATE NONCLUSTERED INDEX NI_Tasks_Priority ON Tasks(Priority);

CREATE TABLE TaskHistory (
    HistoryID BIGINT IDENTITY(1,1) PRIMARY KEY,
    TaskID BIGINT FOREIGN KEY REFERENCES Tasks(TaskID),
    ChangedBy INT FOREIGN KEY REFERENCES Users(UserID),
    ChangeTimestamp DATETIME NOT NULL DEFAULT GETDATE(),
    OldStatus INT,
    OldPriority INT,
	OldHeader INT,
	OldDescription NVARCHAR(MAX),

);

CREATE NONCLUSTERED INDEX NI_Tasks_HIstory_TaskID ON TaskHistory(TaskID);

GO

CREATE PROCEDURE sp_GetTaskStatistics
    @ManagerID INT
AS
BEGIN
    SELECT 
        U.UserID,
        MONTH(T.CreatedAt) AS TaskMonth,
        T.Status,
        COUNT(*) AS TaskCount
    FROM Tasks T
    INNER JOIN Users U ON T.OwnerID = U.UserID
    WHERE U.SupervisorID = @ManagerID
    GROUP BY U.UserID, MONTH(T.CreatedAt), T.Status
	ORDER BY UserId, Status
END;

GO

CREATE PROCEDURE sp_AddTask
    @TenantID INT,
    @OwnerID INT,
    @Header NVARCHAR(255),
    @Priority INT,
    @Status INT,
    @Description NVARCHAR(MAX)
AS
BEGIN
    -- Weryfikacja czy u¿ytkownik istnieje w organizacji
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @OwnerID AND TenantID = @TenantID)
    BEGIN
        THROW 50001, 'Owner not found or does not belong to Tenant.', 1;
    END
	-- Dodanie zadania
    INSERT INTO Tasks (TenantID, OwnerID, Header, Priority, Status, Description, CreatedAt)
    VALUES (@TenantID, @OwnerID, @Header, @Priority, @Status, @Description, GETDATE());
END

GO

CREATE PROCEDURE sp_UpdateTask
    @TaskID BIGINT,
    @Header NVARCHAR(255),
    @Priority INT,
    @Status INT,
    @Description NVARCHAR(MAX),
    @ChangedBy INT
AS
BEGIN
    DECLARE @OldStatus INT;
	DECLARE @OldPriority INT;
	DECLARE @OldHeader NVARCHAR(255);
    DECLARE @OldDescription NVARCHAR(MAX);

	-- Weryfikacja czy zadanie istnieje
	IF NOT EXISTS (SELECT 1 FROM Tasks WHERE TaskID = @TaskID)
    BEGIN
        THROW 50002, 'Task not found', 1;
    END

	-- Weryfikacja czy u¿ytkownik edytuj¹cy jest w³aœcicielem zadania
	IF NOT EXISTS (SELECT 1 FROM Tasks WHERE TaskID = @TaskID and OwnerId = @ChangedBy)
    BEGIN
        THROW 50003, 'Changing user does not own this task', 1;
    END
    
    -- Pobranie poprzednich wartoœci dla historii zmian
    SELECT @OldStatus = Status, @OldPriority = Priority, @OldHeader = Header,  @OldDescription = Description
    FROM Tasks
    WHERE TaskID = @TaskID;

    -- Zapisanie zmian w tabeli TaskHistory
    INSERT INTO TaskHistory (TaskID, ChangedBy, ChangeTimestamp, OldStatus, OldPriority, OldHeader, OldDescription)
    VALUES (@TaskID, @ChangedBy, GETDATE(), @OldStatus, @OldPriority, @OldHeader, @OldDescription);

    -- Aktualizacja zadania
    UPDATE Tasks
    SET Priority = @Priority,
        Status = @Status,
		Header = @Header,
		Description = @Description,
        UpdatedAt = GETDATE()
    WHERE TaskID = @TaskID;
END