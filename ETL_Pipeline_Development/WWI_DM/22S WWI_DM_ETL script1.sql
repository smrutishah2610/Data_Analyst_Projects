------- CREATE WWI_DM USER --------
ALTER session set "_ORACLE_SCRIPT" = true;
CREATE USER wwidbuser identified by wwidbuser;
GRANT ALL PRIVILEGES TO wwidbuser;
SELECT * FROM all_users ORDER BY Created DESC;


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

TRUNCATE Table orders_stage;
EXECUTE Orders_Extract;
SELECT COUNT(*) FROM orders_stage;

CREATE TABLE Location_Preload (
    LocationKey NUMBER(10) NOT NULL,	
    CityName NVARCHAR2(50) NULL,
    StateProvCode NVARCHAR2(5) NULL,
    StateProvName NVARCHAR2(50) NULL,
    CountryName NVARCHAR2(60) NULL,
    CountryFormalName NVARCHAR2(60) NULL,
    CONSTRAINT PK_Location_Preload PRIMARY KEY (LocationKey)
);


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

CREATE SEQUENCE LocationKey START WITH 1;
CREATE SEQUENCE CustomerKey START WITH 1;

CREATE OR REPLACE PROCEDURE Locations_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Locations_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    INSERT INTO Location_Preload /* Column list excluded for brevity */
    SELECT LocationKey.NEXTVAL AS LocationKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvinceCode,
           cu.DeliveryStateProvinceName,
           cu.DeliveryCountryName,
           cu.DeliveryFormalName
    FROM Customers_Stage cu
    WHERE NOT EXISTS 
	( SELECT 1 
              FROM DimLocation ci
              WHERE cu.DeliveryCityName = ci.CityName
                AND cu.DeliveryStateProvinceName = ci.StateProvName
                AND cu.DeliveryCountryName = ci.CountryName 
        );
        
    INSERT INTO Location_Preload /* Column list excluded for brevity */
    SELECT ci.LocationKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvinceCode,
           cu.DeliveryStateProvinceName,
           cu.DeliveryCountryName,
           cu.DeliveryFormalName
    FROM Customers_Stage cu
    JOIN DimLocation ci
        ON cu.DeliveryCityName = ci.CityName
        AND cu.DeliveryStateProvinceName = ci.StateProvName
        AND cu.DeliveryCountryName = ci.CountryName;
    
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

SET SERVEROUT ON;
-- TRUNCATE TABLE Location_Preload;
EXECUTE Locations_Transform;
SELECT COUNT(*) FROM location_preload;

CREATE OR REPLACE PROCEDURE Customers_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Customers_Preload DROP STORAGE';
  StartDate DATE := SYSDATE; 
  EndDate DATE := SYSDATE - 1;
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

SET SERVEROUT ON;
TRUNCATE TABLE Customers_Preload;
EXECUTE Customers_Transform;
SELECT COUNT(*) FROM Customers_Preload;

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
-- Delete from DIMCUSTOMERS;