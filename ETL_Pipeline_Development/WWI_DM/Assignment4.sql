-- Requirement 1
CREATE TABLE DimSupplier (
    SupplierKey NUMBER(10) NOT NULL,
    FullName NVARCHAR2(100) NOT NULL,
    PhoneNumber NVARCHAR2(20),
    FaxNumber NVARCHAR2(20),
    WebsiteURL NVARCHAR2(256),
    CONSTRAINT PK_DimSupplier PRIMARY KEY ( SupplierKey )
);

CREATE INDEX IX_FactOrders_SupplierKey 	ON FactOrders(SupplierKey);
ALTER TABLE FactOrders ADD CONSTRAINT FK_FactOrders_DimSupplier FOREIGN KEY (SupplierKey) REFERENCES DimSupplier(SupplierKey);


-- Requirement 2
CREATE OR REPLACE PROCEDURE InsertIntoDimDate (DateValue IN DATE) IS
    v_current_date DATE := DateValue;
    v_end_date DATE;
BEGIN
    -- Calculate end date (5 years from start date)
    v_end_date := ADD_MONTHS(DateValue, 12 * 5);

    WHILE v_current_date < v_end_date LOOP
        INSERT INTO DimDate (
            DateKey,
            DateValue,
            CYear,
            CQtr,
            CMonth,
            DayNo,
            StartOfMonth,
            EndOfMonth,
            MonthName,
            DayOfWeekName
        ) VALUES (
            TO_NUMBER(TO_CHAR(v_current_date, 'YYYYMMDD')),  -- DateKey as number in YYYYMMDD format
            v_current_date,                                  -- DateValue
            TO_NUMBER(TO_CHAR(v_current_date, 'YYYY')),      -- CYear
            TO_NUMBER(TO_CHAR(v_current_date, 'Q')),         -- CQtr
            TO_NUMBER(TO_CHAR(v_current_date, 'MM')),        -- CMonth
            TO_NUMBER(TO_CHAR(v_current_date, 'DD')),        -- DayNo
            TRUNC(v_current_date, 'MM'),                     -- StartOfMonth
            LAST_DAY(v_current_date),                        -- EndOfMonth
            TO_CHAR(v_current_date, 'Month'),                -- MonthName
            TO_CHAR(v_current_date, 'Day')                   -- DayOfWeekName
        );

        -- Increment to the next day
        v_current_date := v_current_date + 1;
    END LOOP;

    COMMIT;
END InsertIntoDimDate;
/

-- Execute the procedure to insert dates starting from CY2012
BEGIN
    InsertIntoDimDate(TO_DATE('2012-01-01','YYYY-MM-DD'));
END;
/
-- Delete the data(if table had)
-- TRUNCATE TABLE dimdate;
SELECT * FROM dimdate;

-- Requirement: 3