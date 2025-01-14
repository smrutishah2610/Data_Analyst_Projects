
CREATE TABLE wwidbuser.StockItems(
	StockItemID NUMBER(10),
	StockItemName nvarchar2(100) NOT NULL,
	SupplierID NUMBER(10) NOT NULL,
	ColorID NUMBER(10) NULL,
	Brand nvarchar2(50) NULL,
	ItemSize nvarchar2(20) NULL,
	LeadTimeDays NUMBER(10) NOT NULL,
	QuantityPerOuter NUMBER(10) NOT NULL,
	IsChillerStock NUMBER(1) NOT NULL,
	Barcode nvarchar2(50) NULL,
	TaxRate NUMBER(18, 3) NOT NULL,
	UnitPrice NUMBER(18, 2) NOT NULL,
	RecommendedRetailPrice NUMBER(18, 2) NULL,
	TypicalWeightPerUnit NUMBER(18, 3) NOT NULL,
	MarketingComments nvarchar2(300) NULL,
	InternalComments nvarchar2(300) NULL,
	CustomFields nvarchar2(300) NULL,
	Tags nvarchar2(200) NULL,
	SearchDetails nvarchar2(200) NULL,
	CONSTRAINT PK_StockItems PRIMARY KEY (StockItemID),
	CONSTRAINT UQ_StockItems_StockItemName UNIQUE (StockItemName),
	CONSTRAINT FK_StockItems_ColorID_Colors FOREIGN KEY(ColorID) REFERENCES wwidbuser.Colors (ColorID),
	CONSTRAINT FK_StockItems_SupplierID_Suppliers FOREIGN KEY(SupplierID) REFERENCES wwidbuser.Suppliers (SupplierID)
);

CREATE TABLE wwidbuser.Colors(
	ColorID NUMBER(10),
	ColorName nvarchar2(20) NOT NULL,
    CONSTRAINT PK_Colors_ID PRIMARY KEY (ColorID),
    CONSTRAINT UQ_Colors_ColorName UNIQUE (ColorName)
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
TRUNCATE TABLE Products_Preload;
EXECUTE Product_Transform;
SELECT COUNT(*) FROM Products_Preload;

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
