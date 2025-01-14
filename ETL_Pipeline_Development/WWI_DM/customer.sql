CREATE TABLE wwidbuser.CustomerCategories(
	CustomerCategoryID NUMBER(10),
	CustomerCategoryName nvarchar2(50) NOT NULL,
    CONSTRAINT PK_CustomerCategories_ID PRIMARY KEY (CustomerCategoryID),
    CONSTRAINT UQ_CustomerCategories_CustomerCategoryName UNIQUE (CustomerCategoryName)
);

CREATE TABLE wwidbuser.Customers(
	CustomerID NUMBER(10) NOT NULL,
	CustomerName nvarchar2(100) NOT NULL,
	BillToCustomerID NUMBER(10) NOT NULL,
	CustomerCategoryID NUMBER(10) NOT NULL,
	PrimaryContactPersonID NUMBER(10) NOT NULL,
	DeliveryMethodID NUMBER(10) NOT NULL,
	DeliveryCityID NUMBER(10) NOT NULL,
	PostalCityID NUMBER(10) NOT NULL,
	CreditLimit NUMBER(18, 2) NULL,
	AccountOpenedDate date NOT NULL,
	StandardDiscountPercentage NUMBER(18, 3) NOT NULL,
	IsStatementSent NUMBER(1) NOT NULL,
	IsOnCreditHold NUMBER(1) NOT NULL,
	PaymentDays NUMBER(10) NOT NULL,
	PhoneNumber nvarchar2(20) NOT NULL,
	FaxNumber nvarchar2(20) NOT NULL,
	WebsiteURL nvarchar2(256) NOT NULL,
	DeliveryAddressLine1 nvarchar2(60) NOT NULL,
	DeliveryAddressLine2 nvarchar2(60) NULL,
	DeliveryPostalCode nvarchar2(10) NOT NULL,
	PostalAddressLine1 nvarchar2(60) NOT NULL,
	PostalAddressLine2 nvarchar2(60) NULL,
	PostalPostalCode nvarchar2(10) NOT NULL,
 	CONSTRAINT PK_Sales_Customers_ID PRIMARY KEY (CustomerID),
	CONSTRAINT FK_Customers_PrimaryContactPersonID_People FOREIGN KEY(PrimaryContactPersonID) REFERENCES wwidbuser.People (PersonID)
);

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

EXECUTE customers_transform;

SELECT * FROM customers_preload;


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
