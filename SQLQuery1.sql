
  -- 1. фио всех барберов

CREATE PROCEDURE GetAllBarbers
AS
BEGIN
    SELECT FullName
    FROM Barbers;
END;
GO



   -- 2. все синьоры-барберы

CREATE PROCEDURE GetSeniorBarbers
AS
BEGIN
    SELECT *
    FROM Barbers
    WHERE Position = N'синьор-барбер';
END;
GO


   -- 3. традиционное бритье бороды


CREATE PROCEDURE GetShavingBarbers
AS
BEGIN
    SELECT b.*
    FROM Barbers b
    JOIN BarberServices bs
        ON b.BarberID = bs.BarberID
    JOIN Services s
        ON bs.ServiceID = s.ServiceID
    WHERE s.ServiceName =
          N'Традиционное бритье бороды';
END;
GO


   -- 4. барберы по конкретной услуге


CREATE PROCEDURE GetBarbersByService
    @ServiceName NVARCHAR(100)
AS
BEGIN
    SELECT b.*
    FROM Barbers b
    JOIN BarberServices bs
        ON b.BarberID = bs.BarberID
    JOIN Services s
        ON bs.ServiceID = s.ServiceID
    WHERE s.ServiceName = @ServiceName;
END;
GO



   -- 5. барбера работающие стольки то лет


CREATE PROCEDURE GetExperiencedBarbers
    @Years INT
AS
BEGIN
    SELECT *
    FROM Barbers
    WHERE DATEDIFF(YEAR, HireDate, GETDATE()) > @Years;
END;
GO



  -- 6. кол-во синьоров и джуниоров

CREATE PROCEDURE GetBarberCounts
AS
BEGIN
    SELECT
        SUM(
            CASE
                WHEN Position = N'синьор-барбер'
                THEN 1
                ELSE 0
            END
        ) AS SeniorBarbers,

        SUM(
            CASE
                WHEN Position = N'джуниор-барбер'
                THEN 1
                ELSE 0
            END
        ) AS JuniorBarbers

    FROM Barbers;
END;
GO



  -- 7. постоянные клиенты

CREATE PROCEDURE GetRegularClients
    @Visits INT
AS
BEGIN
    SELECT
        c.ClientID,
        c.FullName,
        c.Phone,
        c.Email,
        COUNT(v.VisitID) AS VisitCount

    FROM Clients c

    JOIN VisitArchive v
        ON c.ClientID = v.ClientID

    GROUP BY
        c.ClientID,
        c.FullName,
        c.Phone,
        c.Email

    HAVING COUNT(v.VisitID) >= @Visits;
END;
GO


   -- 8. триггер незя удалить чиф-барбера


CREATE TRIGGER PreventChiefBarberDelete
ON Barbers
AFTER DELETE
AS
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM deleted
        WHERE Position = N'чиф-барбер'
    )
    AND NOT EXISTS
    (
        SELECT 1
        FROM Barbers
        WHERE Position = N'чиф-барбер'
    )

    BEGIN

        ROLLBACK TRANSACTION;

        RAISERROR
        (
            N'Нельзя удалить последнего чиф-барбера.',
            16,
            1
        );

    END

END;
GO


 --  9. триггер нельзя барбера младше 21 года

CREATE TRIGGER PreventYoungBarber
ON Barbers
AFTER INSERT
AS
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM inserted
        WHERE DATEADD
        (
            YEAR,
            21,
            BirthDate
        ) > CAST(GETDATE() AS DATE)
    )

    BEGIN

        ROLLBACK TRANSACTION;

        RAISERROR
        (
            N'Нельзя добавить барбера младше 21 года.',
            16,
            1
        );

    END

END;
GO



  -- проверка всех таблиц

SELECT * FROM Barbers;
SELECT * FROM Clients;
SELECT * FROM Services;
SELECT * FROM BarberServices;
SELECT * FROM Feedback;
SELECT * FROM Schedule;
SELECT * FROM Appointments;
SELECT * FROM VisitArchive;
GO


-- проверка заданий


-- 1
EXEC GetAllBarbers;
GO


-- 2
EXEC GetSeniorBarbers;
GO


-- 3
EXEC GetShavingBarbers;
GO


-- 4
EXEC GetBarbersByService
    N'Традиционное бритье бороды';
GO


-- 5
EXEC GetExperiencedBarbers 5;
GO


-- 6
EXEC GetBarberCounts;
GO

-- 7
EXEC GetRegularClients 2;
GO


-- 8
-- DELETE FROM Barbers
-- WHERE Position = N'чиф-барбер';


-- 9
--
-- INSERT INTO Barbers
-- (
--     FullName,
--     Gender,
--     Phone,
--     Email,
--     BirthDate,
--     HireDate,
--     Position
-- )
-- VALUES
-- (
--     N'Молодой Барбер',
--     N'М',
--     N'79999999999',
--     N'test@mail.ru',
--     '2007-01-01',
--     '2026-01-01',
--     N'джуниор-барбер'
-- );