-- Location Preload and Transform Procedure

CREATE TABLE Locations_Preload (
    LocationKey NUMBER(10) NOT NULL,	
    CityName NVARCHAR2(50) NULL,
    StateProvCode NVARCHAR2(5) NULL,
    StateProvName NVARCHAR2(50) NULL,
    CountryName NVARCHAR2(60) NULL,
    CountryFormalName NVARCHAR2(60) NULL,
    CONSTRAINT PK_Location_Preload PRIMARY KEY (LocationKey)
);


DROP SEQUENCE LocationKey ;
DROP SEQUENCE CustomerKey ;

CREATE SEQUENCE LocationKey START WITH 1 CACHE 20;
CREATE SEQUENCE CustomerKey START WITH 1 CACHE 20;

SELECT LocationKey.NEXTVAL FROM DUAL;
SELECT LocationKey.CURRVAL FROM DUAL;

SELECT * FROM user_sequences WHERE sequence_name = 'LocationKey';

SELECT COUNT(*) FROM Customers_Stage;

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
    COMMIT;
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
TRUNCATE TABLE Locations_Preload;
EXECUTE Locations_Transform;
SELECT COUNT(*) FROM locations_preload;

-- Customer Preload and Transform Procedure
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

    DBMS_OUTPUT.PUT_LINE('Number of product added: ' || TO_CHAR(SQL%ROWCOUNT));
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

SET SERVEROUT ON;
TRUNCATE TABLE customers_preload;
EXECUTE CUSTOMERS_TRANSFORM;
SELECT COUNT(*) FROM customers_preload;

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

-- 
-- 
-- 
-- 
-- 
-- 
-- 
-- 
-- 
-- 

SET SERVEROUT ON;
TRUNCATE TABLE Orders_Preload;
EXECUTE Orders_Transform;
SELECT COUNT(*) FROM Orders_Preload;

-- SalesPeople
-- SalesPeople Preload Table (cleaned and transformed)

Drop Table Supplier_Preload;
---------------------------
CREATE TABLE Supplier_Preload (
    SupplierKey NUMBER(10),
    FullName NVARCHAR2(100),
    PhoneNumber NVARCHAR2(20),
    FaxNumber NVARCHAR2(20),
    WebsiteURL NVARCHAR2(256),
    SupplierCategoryName NVARCHAR2(50)
);

CREATE SEQUENCE SUPPLIER_SEQ START WITH 1 CACHE 20;
CREATE OR REPLACE PROCEDURE Suppliers_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Supplier_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    -- Add updated records
    INSERT INTO Supplier_Preload
    SELECT SUPPLIER_SEQ.NEXTVAL AS SupplierKey,
           stg.FullName,
           stg.PhoneNumber,
           stg.FaxNumber,
           stg.WebsiteURL,
           cat.SupplierCategoryName
    FROM Supplier_Stage stg
    JOIN wwidbuser.Suppliers sup
        ON stg.FullName = sup.SupplierName
    JOIN wwidbuser.SupplierCategories cat
        ON sup.SupplierCategoryID = cat.SupplierCategoryID
    JOIN DimSupplier ds
        ON stg.FullName = ds.FullName
    WHERE stg.PhoneNumber <> ds.PhoneNumber
          OR stg.FaxNumber <> ds.FaxNumber
          OR stg.WebsiteURL <> ds.WebsiteURL
          OR cat.SupplierCategoryName <> ds.SupplierCategoryName;

    -- Add existing records
    INSERT INTO Supplier_Preload
    SELECT ds.SupplierKey,
           ds.FullName,
           ds.PhoneNumber,
           ds.FaxNumber,
           ds.WebsiteURL,
           ds.SupplierCategoryName
    FROM DimSupplier ds;

    -- Create new records
    INSERT INTO Supplier_Preload
    SELECT SUPPLIER_SEQ.NEXTVAL AS SupplierKey,
           stg.FullName,
           stg.PhoneNumber,
           stg.FaxNumber,
           stg.WebsiteURL,
           cat.SupplierCategoryName
    FROM Supplier_Stage stg
    JOIN wwidbuser.Suppliers sup
        ON stg.FullName = sup.SupplierName
    JOIN wwidbuser.SupplierCategories cat
        ON sup.SupplierCategoryID = cat.SupplierCategoryID
    WHERE NOT EXISTS ( SELECT 1 FROM DimSupplier ds WHERE stg.FullName = ds.FullName );
    
    DBMS_OUTPUT.PUT_LINE('Number of supplier records added: ' || TO_CHAR(SQL%ROWCOUNT));
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

SET SERVEROUT ON;
TRUNCATE TABLE Supplier_Preload;
EXECUTE Suppliers_Transform;
SELECT COUNT(*) FROM Supplier_Preload;



