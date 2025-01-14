CREATE TABLE wwidbuser."PEOPLE" (	
    "PERSONID" NUMBER(10,0), 
	"FULLNAME" NVARCHAR2(50) NOT NULL, 
	"PREFERREDNAME" NVARCHAR2(50) NOT NULL, 
	"ISPERMITTEDTOLOGON" NUMBER(1,0) NOT NULL, 
	"LOGONNAME" NVARCHAR2(50), 
	"ISEXTERNALLOGONPROVIDER" NUMBER(1,0) NOT NULL , 
	"ISSYSTEMUSER" NUMBER(1,0) NOT NULL , 
	"ISEMPLOYEE" NUMBER(1,0) NOT NULL , 
	"ISSALESPERSON" NUMBER(1,0) NOT NULL , 
	"USERPREFERENCES" NVARCHAR2(400), 
	"PHONENUMBER" NVARCHAR2(20), 
	"FAXNUMBER" NVARCHAR2(20), 
	"EMAILADDRESS" NVARCHAR2(256), 
	 CONSTRAINT "PK_PEOPLE_ID" PRIMARY KEY ("PERSONID")
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

SET SERVEROUT ON;
EXECUTE SalesPeople_Transform;
SELECT COUNT(*) FROM SalesPeople_Preload;


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
