CREATE TABLE wwidbuser.Suppliers(
	SupplierID NUMBER(10) NOT NULL,
	SupplierName nvarchar2(100) NOT NULL,
	SupplierCategoryID NUMBER(10) NOT NULL,
	PrimaryContactPersonID NUMBER(10) NOT NULL,
	DeliveryCityID NUMBER(10) NOT NULL,
	PostalCityID NUMBER(10) NOT NULL,
	SupplierReference nvarchar2(20) NULL,
	BankAccountName nvarchar2(50) NULL,
	BankAccountBranch nvarchar2(50) NULL,
	BankAccountCode nvarchar2(20) NULL,
	BankAccountNumber nvarchar2(20) NULL,
	BankInternationalCode nvarchar2(20) NULL,
	PaymentDays NUMBER(10) NOT NULL,
	InternalComments nvarchar2(300) NULL,
	PhoneNumber nvarchar2(20) NOT NULL,
	FaxNumber nvarchar2(20) NOT NULL,
	WebsiteURL nvarchar2(256) NOT NULL,
	DeliveryAddressLine1 nvarchar2(60) NOT NULL,
	DeliveryAddressLine2 nvarchar2(60) NULL,
	DeliveryPostalCode nvarchar2(10) NOT NULL,
	PostalAddressLine1 nvarchar2(60) NOT NULL,
	PostalAddressLine2 nvarchar2(60) NULL,
	PostalPostalCode nvarchar2(10) NOT NULL,
	CONSTRAINT PK_Suppliers_ID PRIMARY KEY (SupplierID),
	CONSTRAINT UQ_Suppliers_SupplierName UNIQUE (SupplierName),
	CONSTRAINT FK_Suppliers_PrimaryContactPersonID_People FOREIGN KEY(PrimaryContactPersonID) REFERENCES wwidbuser.People (PersonID),
	CONSTRAINT FK_Suppliers_DeliveryCityID_Cities FOREIGN KEY(DeliveryCityID) REFERENCES wwidbuser.Cities (CityID),
	CONSTRAINT FK_Suppliers_PostalCityID_Cities FOREIGN KEY(PostalCityID) REFERENCES wwidbuser.Cities (CityID),
	CONSTRAINT FK_Suppliers_SupplierCategoryID_SupplierCategories FOREIGN KEY(SupplierCategoryID) REFERENCES wwidbuser.SupplierCategories (SupplierCategoryID)
);

CREATE TABLE wwidbuser.SupplierCategories(
	SupplierCategoryID NUMBER(10),
	SupplierCategoryName nvarchar2(50) NOT NULL,
    CONSTRAINT PK_SupplierCategories_ID PRIMARY KEY (SupplierCategoryID),
    CONSTRAINT UQ_SupplierCategories_SupplierCategoryName UNIQUE (SupplierCategoryName)
);

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
TRUNCATE TABLE Supplier_Preload;
EXECUTE Supplier_Transform;
SELECT COUNT(*) FROM Supplier_Preload;

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