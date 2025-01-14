-- Requirement 4 – Extracts (5 Marks )

-- Create stage tables to insert the extracted data into, and Write stored procedures that will obtain all the required
-- data from the following source data sets from WideWorldImporters:

-- Customers – Query that joins Customers, CustomerCategories, Cities, StateProvinces, and Countries.
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
TRUNCATE TABLE customers_stage;
EXECUTE Customers_Extract;
SELECT COUNT(*) FROM customers_stage;


-- Products – Query that joins StockItems and Colours
-- Step 1: Create the Stage Tables to insert the extracted data

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
TRUNCATE TABLE Product_Stage;
EXECUTE Product_Extract;
SELECT COUNT(*) FROM Product_Stage;

-- Salespeople – Query of People where IsSalesperson is 1

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
TRUNCATE TABLE SalesPeople_Stage;
EXECUTE SalesPeople_Extract;
SELECT COUNT(*) FROM SalesPeople_Stage;

-- Orders – Query that joins Orders, OrderLines, Customers, and People, and accepts an @OrderDate as a
-- parameter, and only selects records that match that date.
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
    LogonName       NVARCHAR2(50)
);


CREATE OR REPLACE PROCEDURE Orders_Extract
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE wwidmuser.Orders_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO wwidmuser.Orders_Stage 
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

    SELECT o.OrderDate
        ,ol.Quantity
        ,ol.UnitPrice
        ,ol.TaxRate
        ,c.CustomerName
        ,dc.cityname
        ,dc.stateprovincename
        ,dc.countryname
        ,stk.StockItemName
        ,p.LogonName
    FROM wwidbuser.Orders o
        LEFT JOIN wwidbuser.OrderLines ol
            ON o.OrderID = ol.OrderID
        LEFT JOIN wwidbuser.customers c
            ON o.CustomerID = c.CustomerID
        LEFT JOIN CityDetails dc
            ON c.DeliveryCityID = dc.CityID
        LEFT JOIN wwidbuser.stockitems stk
            ON ol.Stockitemid = stk.StockItemID
        LEFT JOIN wwidbuser.People p
            ON o.salespersonpersonid = p.personid AND IsSalesPerson = 1;
    
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found THEN
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

EXECUTE Orders_Extract;
SELECT COUNT(*) FROM orders_stage;

-- Suppliers – Query that joins Suppliers and SupplierCategories (Business Analyst and SME review of the
-- Supplier source tables suggests that SupplierCategory might also influence sales orders, so please add the
-- SupplierCategoryName field to the appropriate table in the dimensional model).
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

TRUNCATE TABLE Supplier_Stage;
EXECUTE Suppliers_Extract;
SELECT COUNT(*) FROM Supplier_Stage;
-- Test each of your Extract stored procedures by executing each one of them. When testing the orders
-- extract, use ‘2013-01-01’ as the date.

