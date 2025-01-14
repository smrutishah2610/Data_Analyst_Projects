-- Assignment 4 and 5: ETL
-- Group 16: Joseph, Renjitha And Smruti Shah
-- Section 1


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- Requirement 1 -- -- -- -- -- -- -- -- -- -- -- -- --
CREATE TABLE DimCustomers(   -- Type 2 SCD
	CustomerKey 		NUMBER(10),
	CustomerName 		NVARCHAR2(100) NULL,
	CustomerCategoryName NVARCHAR2(50) NULL,
	DeliveryCityName 	NVARCHAR2(50) NULL,
	DeliveryStateProvCode NVARCHAR2(5) NULL,
	DeliveryCountryName NVARCHAR2(50) NULL,
	PostalCityName 		NVARCHAR2(50) NULL,
	PostalStateProvCode NVARCHAR2(5) NULL,
	PostalCountryName 	NVARCHAR2(50) NULL,
	StartDate 			DATE NOT NULL,
	EndDate 			DATE NULL,
    CONSTRAINT PK_DimCustomers PRIMARY KEY ( CustomerKey )
);

CREATE TABLE DimLocation(  -- Type 1 SCD
	LocationKey 	NUMBER(10),
	CityName 		NVARCHAR2(50) NULL,
	StateProvCode 	NVARCHAR2(5) NULL,
	StateProvName 	NVARCHAR2(50) NULL,
	CountryName 	NVARCHAR2(60) NULL,
	CountryFormalName NVARCHAR2(60) NULL,
    CONSTRAINT PK_DimLocation PRIMARY KEY ( LocationKey )
);

CREATE TABLE DimSalesPeople(    -- Type 1 SCD
	SalespersonKey 	NUMBER(10),
	FullName 		NVARCHAR2(50) NULL,
	PreferredName 	NVARCHAR2(50) NULL,
	LogonName 		NVARCHAR2(50) NULL,
	PhoneNumber 	NVARCHAR2(20) NULL,
	FaxNumber 		NVARCHAR2(20) NULL,
	EmailAddress 	NVARCHAR2(256) NULL,
    CONSTRAINT PK_DimSalesPeople PRIMARY KEY (SalespersonKey )
);

CREATE TABLE DimProducts(   -- Type 2 SCD
	ProductKey 		NUMBER(10),
	ProductName 	NVARCHAR2(100) NULL,
	ProductColour 	NVARCHAR2(20) NULL,
	ProductBrand 	NVARCHAR2(50) NULL,
	ProductSize 	NVARCHAR2(20) NULL,
	StartDate 		DATE NOT NULL,
	EndDate 		DATE NULL,
    CONSTRAINT PK_DimProducts PRIMARY KEY ( ProductKey )
);

CREATE TABLE DimSupplier (
    SupplierKey NUMBER(10) NOT NULL,
    FullName NVARCHAR2(100) NOT NULL,
    PhoneNumber NVARCHAR2(20),
    FaxNumber NVARCHAR2(20),
    WebsiteURL NVARCHAR2(256),
    SupplierCategoryName NVARCHAR2(50),
    CONSTRAINT PK_DimSupplier PRIMARY KEY ( SupplierKey )
);

CREATE TABLE FactOrders (
    -- Should we create a surrogate key?
    CustomerKey      	NUMBER(10) NOT NULL,
    LocationKey      	NUMBER(10) NOT NULL,
    ProductKey       	NUMBER(10) NOT NULL,
    SalespersonKey   	NUMBER(10) NOT NULL,
    DateKey 	      	NUMBER(8) NOT NULL,
    Quantity 	      	NUMBER(4) NOT NULL,
    UnitPrice        	NUMBER(18,2) NOT NULL,
    TaxRate 	      	NUMBER(18,3) NOT NULL,
    TotalBeforeTax   	NUMBER(18,2) NOT NULL,
    TotalAfterTax    	NUMBER(18,2) NOT NULL,
    SupplierKey NUMBER(10) NOT NULL,
    CONSTRAINT FK_FactOrders_DimCustomers FOREIGN KEY (CustomerKey) REFERENCES DimCustomers(CustomerKey)
);


CREATE INDEX IX_FactOrders_SupplierKey 	ON FactOrders(SupplierKey);
ALTER TABLE FactOrders ADD CONSTRAINT FK_FactOrders_DimSupplier FOREIGN KEY (SupplierKey) REFERENCES DimSupplier(SupplierKey);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- Requirement 2 -- -- -- -- -- -- -- -- -- -- -- -- --
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

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- Requirement 3 -- -- -- -- -- -- -- -- -- -- -- -- --
SELECT 
    c.CustomerName,
    l.CityName,
    sp.FullName AS SalespersonName,
    p.ProductName,
    s.FullName AS SupplierName,
    f.DateKey AS OrderDate,
    f.Quantity,
    f.TotalAfterTax AS TotalSales,
    (f.Quantity * f.UnitPrice) AS ExpectedRevenue,
    ROUND(AVG(f.Quantity) OVER (PARTITION BY c.CustomerName, p.ProductName ORDER BY f.DateKey ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 2) AS AvgQuantity7Days,
    ROUND(SUM(f.TotalAfterTax) OVER (PARTITION BY c.CustomerName ORDER BY f.DateKey ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 2) AS AvgRevenue7Days
FROM 
    FactOrders f
JOIN 
    DimCustomers c ON f.CustomerKey = c.CustomerKey
JOIN 
    DimLocation l ON f.LocationKey = l.LocationKey
JOIN 
    DimSalesPeople sp ON f.SalespersonKey = sp.SalespersonKey
JOIN 
    DimProducts p ON f.ProductKey = p.ProductKey
JOIN 
    DimSupplier s ON f.SupplierKey = s.SupplierKey
WHERE
    f.DateKey BETWEEN '20130101' AND '20130104'
ORDER BY
    f.DateKey, c.CustomerName, p.ProductName;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- Requirement 4 -- -- -- -- -- -- -- -- -- -- -- -- --

-- Customer Stage and Extract
CREATE TABLE Customers_Stage (
    CustomerName NVARCHAR2(100),
    CustomerCategoryName NVARCHAR2(50),
    DeliveryCityName NVARCHAR2(50),
    DeliveryStateProvinceCode NVARCHAR2(5),
    DeliveryStateProvinceName NVARCHAR2(50),
    DeliveryCountryName NVARCHAR2(50),
    DeliveryFormalName NVARCHAR2(60),
    PostalCityName NVARCHAR2(50),
    PostalStateProvinceCode NVARCHAR2(5),
    PostalStateProvinceName NVARCHAR2(50),
    PostalCountryName NVARCHAR2(50),
    PostalFormalName NVARCHAR2(60)
);

CREATE OR REPLACE PROCEDURE Customers_Extract 
IS
    RowCt NUMBER(10):=0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE wwidmuser.Customers_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO wwidmuser.Customers_Stage
    WITH CityDetails AS (
        SELECT ci.CityID,
               ci.CityName,
               sp.StateProvinceCode,
               sp.StateProvinceName,
               co.CountryName,
               co.FormalName
        FROM wwidbuser.Cities ci
        LEFT JOIN wwidbuser.StateProvinces sp
            ON ci.StateProvinceID = sp.StateProvinceID
        LEFT JOIN wwidbuser.Countries co
            ON sp.CountryID = co.CountryID 
    )
    
    SELECT cust.CustomerName,
           cat.CustomerCategoryName,
           dc.CityName,
           dc.StateProvinceCode,
           dc.StateProvinceName,
           dc.CountryName,
           dc.FormalName,
           pc.CityName,
           pc.StateProvinceCode,
           pc.StateProvinceName,
           pc.CountryName,
           pc.FormalName
    FROM wwidbuser.Customers cust
    LEFT JOIN wwidbuser.CustomerCategories cat
        ON cust.CustomerCategoryID = cat.CustomerCategoryID
    LEFT JOIN CityDetails dc
        ON cust.DeliveryCityID = dc.CityID
    LEFT JOIN CityDetails pc
        ON cust.PostalCityID = pc.CityID;

    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of customers added: ' || TO_CHAR(SQL%ROWCOUNT));
END;


SET SERVEROUT ON;
-- TRUNCATE TABLE customers_stage;
EXECUTE Customers_Extract;
SELECT COUNT(*) FROM customers_stage;

-- Sales People
-- Step 1: Create the Stage Tables to insert the extracted data
CREATE TABLE SalesPeople_Stage (
    SalespersonKey  NUMBER(10),
    FullName        NVARCHAR2(50) NULL,
    PreferredName   NVARCHAR2(50) NULL,
    LogonName       NVARCHAR2(50) NULL,
    PhoneNumber     NVARCHAR2(20) NULL,
    FaxNumber       NVARCHAR2(20) NULL,
    EmailAddress    NVARCHAR2(256) NULL
);

-- Step 2: Create a stored procedure to extract the required data
CREATE OR REPLACE PROCEDURE SalesPeople_Extract
IS
    RowCt NUMBER(10):=0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE SalesPeople_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    -- Insert data into SalesPeople_Stage from PEOPLE table where IsSalesperson is 1
    INSERT INTO SalesPeople_Stage (SalespersonKey, FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress)
    SELECT
        p.PERSONID AS SalespersonKey,
        p.FULLNAME AS FullName,
        p.PREFERREDNAME AS PreferredName,
        p.LOGONNAME AS LogonName,
        p.PHONENUMBER AS PhoneNumber,
        p.FAXNUMBER AS FaxNumber,
        p.EMAILADDRESS AS EmailAddress
    FROM
        wwidbuser."PEOPLE" p
    WHERE
        p.ISSALESPERSON = 1;
    
    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of product added: ' || TO_CHAR(SQL%ROWCOUNT));
END;
/

SET SERVEROUT ON;
-- TRUNCATE TABLE SalesPeople_Stage;
EXECUTE SalesPeople_Extract;
SELECT COUNT(*) FROM SalesPeople_Stage;

-- Product
CREATE TABLE Product_Stage (
    ProductKey       NUMBER(10),
    ProductName      NVARCHAR2(100) NULL,
    ProductColour    NVARCHAR2(20) NULL,
    ProductBrand     NVARCHAR2(50) NULL,
    ProductSize      NVARCHAR2(20) NULL
);

-- Step 2: Create a stored procedure to extract the required data
CREATE OR REPLACE PROCEDURE Product_Extract
IS
    RowCt NUMBER(10):=0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE Product_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    -- Insert data into StageProductsExtract from StockItems and Colors
    INSERT INTO Product_Stage (ProductKey, ProductName, ProductColour, ProductBrand, ProductSize)
    SELECT
        si.StockItemID AS ProductKey,
        si.StockItemName AS ProductName,
        c.ColorName AS ProductColour,
        si.Brand AS ProductBrand,
        si.ItemSize AS ProductSize
    FROM
        wwidbuser.StockItems si
    LEFT JOIN
        wwidbuser.Colors c ON si.ColorID = c.ColorID;
    
    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of product added: ' || TO_CHAR(SQL%ROWCOUNT));
END;

SET SERVEROUT ON;
-- TRUNCATE TABLE Product_Stage;
EXECUTE Product_Extract;
SELECT COUNT(*) FROM Product_Stage;

-- Supplier 
CREATE TABLE Supplier_Stage (
    SupplierID           NUMBER(10),
    FullName             NVARCHAR2(100),
    PhoneNumber          NVARCHAR2(20),
    FaxNumber            NVARCHAR2(20),
    WebsiteURL           NVARCHAR2(256),
    SupplierCategoryName NVARCHAR2(50)
);

CREATE OR REPLACE PROCEDURE Suppliers_Extract AS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE Supplier_Stage DROP STORAGE';
BEGIN
    -- Clear the staging table
    EXECUTE IMMEDIATE v_sql;

    -- Insert data into the staging table
    INSERT INTO Supplier_Stage (
        SupplierID,
        FullName,
        PhoneNumber,
        FaxNumber,
        WebsiteURL,
        SupplierCategoryName
    )
    SELECT 
        s.SupplierID,
        s.SupplierName AS FullName,
        s.PhoneNumber,
        s.FaxNumber,
        s.WebsiteURL,
        sc.SupplierCategoryName
    FROM 
        wwidbuser.Suppliers s
    JOIN 
        wwidbuser.SupplierCategories sc ON s.SupplierCategoryID = sc.SupplierCategoryID;

    -- Log the number of rows inserted
    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of suppliers added: ' || TO_CHAR(RowCt));
END;

-- TRUNCATE TABLE Supplier_Stage;
EXECUTE Suppliers_Extract;
SELECT COUNT(*) FROM Supplier_Stage;

-- Order
CREATE TABLE Orders_Stage (
    OrderDate       DATE,
    Quantity        NUMBER(3),
    UnitPrice       NUMBER(18,2),
    TaxRate         NUMBER(18,3),
    CustomerName    NVARCHAR2(100),
    CityName        NVARCHAR2(50),
    StateProvinceName   NVARCHAR2(50),
    CountryName     NVARCHAR2(60),
    StockItemName   NVARCHAR2(100),
    LogonName       NVARCHAR2(50),
    SupplierName nvarchar2(100)
);


CREATE OR REPLACE PROCEDURE Orders_Extract
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE wwidmuser.Orders_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO wwidmuser.Orders_Stage (
        OrderDate,
        Quantity,
        UnitPrice,
        TaxRate,
        CustomerName,
        CityName,
        StateProvinceName,
        CountryName,
        StockItemName,
        LogonName,
        SupplierName
    )
    WITH CityDetails AS (
        SELECT ci.CityID,
               ci.CityName,
               sp.StateProvinceCode,
               sp.StateProvinceName,
               co.CountryName,
               co.FormalName
        FROM wwidbuser.Cities ci
        LEFT JOIN wwidbuser.StateProvinces sp
            ON ci.StateProvinceID = sp.StateProvinceID
        LEFT JOIN wwidbuser.Countries co
            ON sp.CountryID = co.CountryID 
    )
    SELECT o.OrderDate,
           ol.Quantity,
           ol.UnitPrice,
           ol.TaxRate,
           c.CustomerName,
           dc.CityName,
           dc.StateProvinceName,
           dc.CountryName,
           stk.StockItemName,
           p.LogonName,
           s.SupplierName
    FROM wwidbuser.Orders o
        LEFT JOIN wwidbuser.OrderLines ol
            ON o.OrderID = ol.OrderID
        LEFT JOIN wwidbuser.Customers c
            ON o.CustomerID = c.CustomerID
        LEFT JOIN CityDetails dc
            ON c.DeliveryCityID = dc.CityID
        LEFT JOIN wwidbuser.StockItems stk
            ON ol.StockItemID = stk.StockItemID
        LEFT JOIN wwidbuser.People p
            ON o.SalespersonPersonID = p.PersonID AND IsSalesPerson = 1
        LEFT JOIN wwidbuser.Suppliers s
            ON stk.SupplierID = s.SupplierID;
    
    RowCt := SQL%ROWCOUNT;
    IF RowCt = 0 THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSE
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

Set serverout on;
EXECUTE Orders_Extract;
SELECT COUNT(*) FROM orders_stage;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- Requirement 5 -- -- -- -- -- -- -- -- -- -- -- -- --

-- Customer
CREATE SEQUENCE CustomerKey START WITH 1 CACHE 20;

CREATE TABLE Customers_Preload (
   CustomerKey NUMBER(10) NOT NULL,
   CustomerName NVARCHAR2(100) NULL,
   CustomerCategoryName NVARCHAR2(50) NULL,
   DeliveryCityName NVARCHAR2(50) NULL,
   DeliveryStateProvCode NVARCHAR2(5) NULL,
   DeliveryCountryName NVARCHAR2(50) NULL,
   PostalCityName NVARCHAR2(50) NULL,
   PostalStateProvCode NVARCHAR2(5) NULL,
   PostalCountryName NVARCHAR2(50) NULL,
   StartDate DATE NOT NULL,
   EndDate DATE NULL,
   CONSTRAINT PK_Customers_Preload PRIMARY KEY ( CustomerKey )
);

CREATE OR REPLACE PROCEDURE Customers_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Customers_Preload DROP STORAGE';
  StartDate DATE := SYSDATE; EndDate DATE := SYSDATE - 1;
BEGIN
    EXECUTE IMMEDIATE v_sql;
 --BEGIN TRANSACTION;
 -- Add updated records
    INSERT INTO Customers_Preload /* Column list excluded for brevity */
    SELECT CustomerKey.NEXTVAL AS CustomerKey,
           stg.CustomerName,
           stg.CustomerCategoryName,
           stg.DeliveryCityName,
           stg.DeliveryStateProvinceCode,
           stg.DeliveryCountryName,
           stg.PostalCityName,
           stg.PostalStateProvinceCode,
           stg.PostalCountryName,
           StartDate,
           NULL
    FROM Customers_Stage stg
    JOIN DimCustomers cu
        ON stg.CustomerName = cu.CustomerName AND cu.EndDate IS NULL
    WHERE stg.CustomerCategoryName <> cu.CustomerCategoryName
          OR stg.DeliveryCityName <> cu.DeliveryCityName
          OR stg.DeliveryStateProvinceCode <> cu.DeliveryStateProvCode
          OR stg.DeliveryCountryName <> cu.DeliveryCountryName
          OR stg.PostalCityName <> cu.PostalCityName
          OR stg.PostalStateProvinceCode <> cu.PostalStateProvCode
          OR stg.PostalCountryName <> cu.PostalCountryName;

    -- Add existing records, and expire as necessary
    INSERT INTO Customers_Preload /* Column list excluded for brevity */
    SELECT cu.CustomerKey,
           cu.CustomerName,
           cu.CustomerCategoryName,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryCountryName,
           cu.PostalCityName,
           cu.PostalStateProvCode,
           cu.PostalCountryName,
           cu.StartDate,
           CASE 
               WHEN pl.CustomerName IS NULL THEN NULL
               ELSE cu.EndDate
           END AS EndDate
    FROM DimCustomers cu
    LEFT JOIN Customers_Preload pl    
        ON pl.CustomerName = cu.CustomerName
        AND cu.EndDate IS NULL;
 -- Create new records
    INSERT INTO Customers_Preload /* Column list excluded for brevity */
    SELECT CustomerKey.NEXTVAL AS CustomerKey,
           stg.CustomerName,
           stg.CustomerCategoryName,
           stg.DeliveryCityName,
           stg.DeliveryStateProvinceCode,
           stg.DeliveryCountryName,
           stg.PostalCityName,
           stg.PostalStateProvinceCode,
           stg.PostalCountryName,
           StartDate,
           NULL
    FROM Customers_Stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM DimCustomers cu WHERE stg.CustomerName = cu.CustomerName );
    -- Expire missing records
    INSERT INTO Customers_Preload /* Column list excluded for brevity */
    SELECT cu.CustomerKey,
           cu.CustomerName,
           cu.CustomerCategoryName,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryCountryName,
           cu.PostalCityName,
           cu.PostalStateProvCode,
           cu.PostalCountryName,
           cu.StartDate,
           EndDate
    FROM DimCustomers cu
    WHERE NOT EXISTS ( SELECT 1 FROM Customers_Stage stg WHERE stg.CustomerName = cu.CustomerName )
          AND cu.EndDate IS NULL;

    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
--COMMIT TRANSACTION;
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

-- TRUNCATE TABLE customers_preload;
Set Serverout ON;
EXECUTE customers_transform;
SELECT COUNT(*) FROM customers_preload;

-- Location
CREATE SEQUENCE LocationKey START WITH 1 CACHE 20;

CREATE TABLE Locations_Preload (
    LocationKey NUMBER(10) NOT NULL,	
    CityName NVARCHAR2(50) NULL,
    StateProvCode NVARCHAR2(5) NULL,
    StateProvName NVARCHAR2(50) NULL,
    CountryName NVARCHAR2(60) NULL,
    CountryFormalName NVARCHAR2(60) NULL,
    CONSTRAINT PK_Location_Preload PRIMARY KEY (LocationKey)
);

CREATE OR REPLACE PROCEDURE Locations_Transform --Type 1 SCD
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Locations_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
--BEGIN TRANSACTION;
    INSERT INTO Locations_Preload /* Column list excluded for brevity */
    SELECT LocationKey.NEXTVAL AS LocationKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvinceCode,
           cu.DeliveryStateProvinceName,
           cu.DeliveryCountryName,
           cu.DeliveryFormalName
    FROM Customers_Stage cu
    WHERE NOT EXISTS 
	( SELECT 1 
              FROM DimLocation loc
              WHERE cu.DeliveryCityName = loc.CityName
                AND cu.DeliveryStateProvinceName = loc.StateProvName
                AND cu.DeliveryCountryName = loc.CountryName 
        );
        
    INSERT INTO Locations_Preload /* Column list excluded for brevity */
    SELECT loc.LocationKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvinceCode,
           cu.DeliveryStateProvinceName,
           cu.DeliveryCountryName,
           cu.DeliveryFormalName
    FROM Customers_Stage cu
    JOIN DimLocation loc
        ON cu.DeliveryCityName = loc.CityName
        AND cu.DeliveryStateProvinceName = loc.StateProvName
        AND cu.DeliveryCountryName = loc.CountryName;
--COMMIT TRANSACTION;
    RowCt := SQL%ROWCOUNT;
    IF SQL%ROWCOUNT = 0 THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSIF SQL%ROWCOUNT > 0 THEN
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

SET SERVEROUT ON;
-- TRUNCATE TABLE Locations_Preload;
EXECUTE Locations_Transform;
SELECT COUNT(*) FROM locations_preload;

-- Sales People
CREATE SEQUENCE SalespersonKey START WITH 1 CACHE 20;

CREATE TABLE SalesPeople_Preload (
    SalespersonKey 	NUMBER(10),
	FullName 		NVARCHAR2(50) NULL,
	PreferredName 	NVARCHAR2(50) NULL,
	LogonName 		NVARCHAR2(50) NULL,
	PhoneNumber 	NVARCHAR2(20) NULL,
	FaxNumber 		NVARCHAR2(20) NULL,
	EmailAddress 	NVARCHAR2(256) NULL,
    CONSTRAINT PK_PreloadSalesPeople PRIMARY KEY (SalespersonKey )
)

CREATE OR REPLACE PROCEDURE SalesPeople_Transform
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE SalesPeople_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    -- Add new records from SalesPeople_Stage to SalesPeople_Preload
    INSERT INTO SalesPeople_Preload (SalespersonKey, FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress)
    SELECT
        stg.SalespersonKey,
        stg.FullName,
        stg.PreferredName,
        stg.LogonName,
        stg.PhoneNumber,
        stg.FaxNumber,
        stg.EmailAddress
    FROM
        SalesPeople_Stage stg
    WHERE
        NOT EXISTS (
            SELECT 1 FROM DimSalesPeople dim
            WHERE dim.SalespersonKey = stg.SalespersonKey
        );

    -- Update existing records in SalesPeople_Preload
    INSERT INTO SalesPeople_Preload (SalespersonKey, FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress)
    SELECT
        stg.SalespersonKey,
        stg.FullName,
        stg.PreferredName,
        stg.LogonName,
        stg.PhoneNumber,
        stg.FaxNumber,
        stg.EmailAddress
    FROM
        SalesPeople_Stage stg
    JOIN
        DimSalesPeople dim ON stg.SalespersonKey = dim.SalespersonKey
    WHERE
        stg.FullName <> dim.FullName
        OR stg.PreferredName <> dim.PreferredName
        OR stg.LogonName <> dim.LogonName
        OR stg.PhoneNumber <> dim.PhoneNumber
        OR stg.FaxNumber <> dim.FaxNumber
        OR stg.EmailAddress <> dim.EmailAddress;

    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' Rows have been inserted or updated in SalesPeople_Preload.');
END;
/

-- TRUNCATE Table SalesPeople_Preload;
SET SERVEROUT ON;
EXECUTE SalesPeople_Transform;
SELECT COUNT(*) FROM SalesPeople_Preload;

-- Product
CREATE SEQUENCE ProductKey START WITH 1 CACHE 20;

CREATE TABLE Products_Preload(
    ProductKey 		NUMBER(10),
	ProductName 	NVARCHAR2(100) NULL,
	ProductColour 	NVARCHAR2(20) NULL,
	ProductBrand 	NVARCHAR2(50) NULL,
	ProductSize 	NVARCHAR2(20) NULL,
	StartDate 		DATE NOT NULL,
	EndDate 		DATE NULL,
    CONSTRAINT Products_Preload PRIMARY KEY ( ProductKey )
);

CREATE OR REPLACE PROCEDURE Product_Transform
AS
    RowCt NUMBER(10);
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE Products_Preload DROP STORAGE';
    StartDate DATE := SYSDATE;
    EndDate DATE := SYSDATE - 1;
BEGIN
    EXECUTE IMMEDIATE v_sql;

    -- Add updated records
    INSERT INTO Products_Preload
    SELECT ProductKey.NEXTVAL AS ProductKey,
           stg.ProductName,
           stg.ProductColour,
           stg.ProductBrand,
           stg.ProductSize,
           StartDate,
           NULL
    FROM Product_Stage stg
    JOIN DimProducts dp
        ON stg.ProductName = dp.ProductName AND dp.EndDate IS NULL
    WHERE stg.ProductColour <> dp.ProductColour
          OR stg.ProductBrand <> dp.ProductBrand
          OR stg.ProductSize <> dp.ProductSize;

    -- Add existing records, and expire as necessary
    INSERT INTO Products_Preload
    SELECT dp.ProductKey,
           dp.ProductName,
           dp.ProductColour,
           dp.ProductBrand,
           dp.ProductSize,
           dp.StartDate,
           CASE 
               WHEN pl.ProductName IS NULL THEN NULL
               ELSE dp.EndDate
           END AS EndDate
    FROM DimProducts dp
    LEFT JOIN Products_Preload pl    
        ON pl.ProductName = dp.ProductName
        AND dp.EndDate IS NULL;

    -- Create new records
    INSERT INTO Products_Preload
    SELECT ProductKey.NEXTVAL AS ProductKey,
           stg.ProductName,
           stg.ProductColour,
           stg.ProductBrand,
           stg.ProductSize,
           StartDate,
           NULL
    FROM Product_Stage stg
    WHERE NOT EXISTS (SELECT 1 FROM DimProducts dp WHERE stg.ProductName = dp.ProductName);

    -- Expire missing records
    INSERT INTO Products_Preload
    SELECT dp.ProductKey,
           dp.ProductName,
           dp.ProductColour,
           dp.ProductBrand,
           dp.ProductSize,
           dp.StartDate,
           EndDate
    FROM DimProducts dp
    WHERE NOT EXISTS (SELECT 1 FROM Product_Stage stg WHERE stg.ProductName = dp.ProductName)
          AND dp.EndDate IS NULL;

    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
END;

SET SERVEROUT ON;
-- TRUNCATE TABLE Products_Preload;
EXECUTE Product_Transform;
SELECT COUNT(*) FROM Products_Preload;

-- Supplier
CREATE SEQUENCE SupplierKey START WITH 1 CACHE 20;


CREATE TABLE Supplier_Preload (
    SupplierKey NUMBER(10) NOT NULL,
    FullName NVARCHAR2(100) NOT NULL,
    PhoneNumber NVARCHAR2(20),
    FaxNumber NVARCHAR2(20),
    WebsiteURL NVARCHAR2(256),
    SupplierCategoryName NVARCHAR2(50),
    CONSTRAINT PK_PreloadSupplier PRIMARY KEY (SupplierKey)
);

CREATE OR REPLACE PROCEDURE Supplier_Transform AS
    RowCt INTEGER;
    SupplierStageCount INTEGER;
BEGIN
    -- Insert new records into Suppliers_Preload table
    INSERT INTO Supplier_Preload
    SELECT SupplierKey.NEXTVAL AS SupplierKey,
           stg.FullName,
           stg.PhoneNumber,
           stg.FaxNumber,
           stg.WebsiteURL,
           stg.SupplierCategoryName
    FROM Supplier_Stage stg
    LEFT JOIN Supplier_Preload pl
        ON stg.FullName = pl.FullName
    WHERE pl.FullName IS NULL;

    -- Update existing records with new details, if necessary
    MERGE INTO Supplier_Preload pl
    USING Supplier_Stage stg
    ON (pl.FullName = stg.FullName)
    WHEN MATCHED THEN
        UPDATE SET pl.PhoneNumber = stg.PhoneNumber,
                   pl.FaxNumber = stg.FaxNumber,
                   pl.WebsiteURL = stg.WebsiteURL,
                   pl.SupplierCategoryName = stg.SupplierCategoryName;

    -- Simple validation error if no records found in stage table
    SELECT COUNT(*) INTO SupplierStageCount FROM Supplier_Stage;
    IF SupplierStageCount = 0 THEN
        dbms_output.put_line('Validation Error: No records found in Supplier_Stage table.');
    END IF;

    -- Output the number of rows affected
    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) || ' Rows have been processed!');
END;
/

-- Execute the Supplier_Transform procedure
SET SERVEROUT ON;
-- TRUNCATE TABLE Supplier_Preload;
EXECUTE Supplier_Transform;
SELECT COUNT(*) FROM Supplier_Preload;

-- Order

CREATE TABLE Orders_Preload (
    CustomerKey NUMBER(10) NOT NULL,
    CityKey NUMBER(10) NOT NULL,
    ProductKey NUMBER(10) NOT NULL,
    SalespersonKey NUMBER(10) NOT NULL,
    SupplierKey NUMBER(10) NOT NULL,
    DateKey NUMBER(8) NOT NULL,
    Quantity NUMBER(3) NOT NULL,
    UnitPrice NUMBER(18, 2) NOT NULL,
    TaxRate NUMBER(18, 3) NOT NULL,
    TotalBeforeTax NUMBER(18, 2) NOT NULL,
    TotalAfterTax NUMBER(18, 2) NOT NULL
);

CREATE OR REPLACE PROCEDURE Orders_Transform
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Orders_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    INSERT INTO Orders_Preload /* Columns excluded for brevity */
    SELECT cu.CustomerKey,
        ci.LocationKey,
        pr.ProductKey,
        sp.SalespersonKey,
        su.SupplierKey,
        EXTRACT(YEAR FROM ord.OrderDate)*10000 + EXTRACT(Month FROM ord.OrderDate)*100 + EXTRACT(Day FROM ord.OrderDate),
        SUM(ord.Quantity) AS Quantity,
        AVG(ord.UnitPrice) AS UnitPrice,
        AVG(ord.TaxRate) AS TaxRate,
        SUM(ord.Quantity * ord.UnitPrice) AS TotalBeforeTax,
        SUM(ord.Quantity * ord.UnitPrice * (1 + ord.TaxRate/100)) AS TotalAfterTax
    FROM Orders_Stage ord
    JOIN Customers_Preload cu
        ON ord.CustomerName = cu.CustomerName
    JOIN Locations_Preload ci
        ON ord.CityName = ci.CityName AND ord.StateProvinceName = ci.StateProvName
        AND ord.CountryName = ci.CountryName
    JOIN Products_Preload pr
        ON ord.StockItemName = pr.ProductName
    JOIN SalesPeople_Preload sp
        ON ord.LogonName = sp.LogonName
    JOIN Supplier_Preload su
        ON ord.SupplierName = su.FullName
    GROUP BY cu.CustomerKey, ci.LocationKey, pr.ProductKey, sp.SalespersonKey, su.SupplierKey, ord.OrderDate;

    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) || ' Rows have been processed!');
END;
/

-- Execute the Orders_Transform procedure
-- TRUNCATE TABLE Orders_Preload;
SET SERVEROUT ON;
EXECUTE Orders_Transform;
Select COUNT(*) from Orders_Preload;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- Requirement 6 -- -- -- -- -- -- -- -- -- -- -- -- --

-- Customer
CREATE OR REPLACE PROCEDURE Customers_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimCustomers cu
    WHERE EXISTS (SELECT null FROM Customers_Preload pl
                    WHERE cu.CustomerKey = pl.CustomerKey);

    INSERT INTO DimCustomers /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Customers_Preload;

    COMMIT;
END;

EXEC customers_load;

SELECT COUNT(*) FROM customers_preload;
SELECT COUNT(*) FROM dimcustomers ORDER BY customerkey;

-- Location
CREATE OR REPLACE PROCEDURE Location_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimLocation dl
    WHERE EXISTS (SELECT null FROM locations_preload pl
                    WHERE dl.LocationKey = pl.LocationKey);

    INSERT INTO DimLocation /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM locations_preload;

    COMMIT;
END;

EXEC Location_Load;

SELECT COUNT(*) FROM locations_preload;
SELECT COUNT(*) FROM DimLocation ORDER BY LocationKey;

-- Sales People

CREATE OR REPLACE PROCEDURE SalesPeople_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimSalesPeople cu
    WHERE EXISTS (SELECT null FROM SalesPeople_Preload sp
                    WHERE cu.SalespersonKey = sp.SalespersonKey);

    INSERT INTO DimSalesPeople /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM SalesPeople_Preload;

    COMMIT;
END;

EXEC SalesPeople_Load;

SELECT COUNT(*) FROM SalesPeople_Preload;
SELECT COUNT(*) FROM DimSalesPeople ORDER BY SalespersonKey;

-- Product
CREATE OR REPLACE PROCEDURE Products_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimProducts dp
    WHERE EXISTS (SELECT null FROM Products_Preload pp
                    WHERE dp.ProductKey = pp.ProductKey);

    INSERT INTO DimProducts /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Products_Preload;

    COMMIT;
END;

EXEC Products_Load;

SELECT COUNT(*) FROM Products_Preload;
SELECT COUNT(*) FROM DimProducts ORDER BY ProductKey;

-- Suppliers
CREATE OR REPLACE PROCEDURE Supplier_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimSupplier ds
    WHERE EXISTS (SELECT null FROM Supplier_Preload su
                    WHERE ds.SupplierKey = su.SupplierKey);

    INSERT INTO DimSupplier /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Supplier_Preload;

    COMMIT;
END;

EXECUTE Supplier_Load;

Select COUNT(*) FROM Supplier_Preload;
Select COUNT(*) FROM DimSupplier ORDER BY SupplierKey;

-- Order
CREATE OR REPLACE PROCEDURE Orders_Load
AS
BEGIN
    INSERT INTO FactOrders (
        CustomerKey,
        LocationKey,
        ProductKey,
        SalespersonKey,
        DateKey,
        Quantity,
        UnitPrice,
        TaxRate,
        TotalBeforeTax,
        TotalAfterTax,
        SupplierKey
    )
    SELECT CustomerKey,
           CityKey,
           ProductKey,
           SalespersonKey,
           DateKey,
           Quantity,
           ROUND(UnitPrice, 2),        -- Round to fit the defined precision
           ROUND(TaxRate, 3),          -- Round to fit the defined precision
           ROUND(TotalBeforeTax, 2),   -- Round to fit the defined precision
           ROUND(TotalAfterTax, 2),     -- Round to fit the defined precision
           SupplierKey
    FROM Orders_Preload;

    COMMIT;
END;
/

SET SERVEROUT ON;
EXECUTE ORDERS_LOAD;
SELECT COUNT(*) FROM FACTORDERS;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- Requirement 7 -- -- -- -- -- -- -- -- -- -- -- -- --
SET SERVEROUT ON;

-- Truncate and execute Orders_Transform for 4 days worth of data (2013-01-01 to 2013-01-04)
TRUNCATE TABLE FACTORDERS;
EXECUTE Orders_Transform;

-- Load the transformed data to FactOrders
EXECUTE Orders_Load;

SELECT 
    c.CustomerName,
    l.CityName,
    sp.FullName AS SalespersonName,
    p.ProductName,
    s.FullName AS SupplierName,
    f.DateKey AS OrderDate,
    f.Quantity,
    f.TotalAfterTax AS TotalSales,
    (f.Quantity * f.UnitPrice) AS ExpectedRevenue,
    ROUND(AVG(f.Quantity) OVER (PARTITION BY c.CustomerName, p.ProductName ORDER BY f.DateKey ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 2) AS AvgQuantity7Days,
    ROUND(SUM(f.TotalAfterTax) OVER (PARTITION BY c.CustomerName ORDER BY f.DateKey ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 2) AS AvgRevenue7Days
FROM 
    FactOrders f
JOIN 
    DimCustomers c ON f.CustomerKey = c.CustomerKey
JOIN 
    DimLocation l ON f.LocationKey = l.LocationKey
JOIN 
    DimSalesPeople sp ON f.SalespersonKey = sp.SalespersonKey
JOIN 
    DimProducts p ON f.ProductKey = p.ProductKey
JOIN 
    DimSupplier s ON f.SupplierKey = s.SupplierKey
WHERE
    f.DateKey BETWEEN '20130101' AND '20130104'
ORDER BY
    f.DateKey, c.CustomerName, p.ProductName;
