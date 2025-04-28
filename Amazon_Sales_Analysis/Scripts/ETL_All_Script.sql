
---------------------------------------------//**Extract Process**//-----------------------------------------------------

--------------------------/*User Table*/-------------------------------------------

CREATE TABLE Users_Stage(   
	UserName 		NVARCHAR2(100) NULL,
	UserCategory  NVARCHAR2(50) NULL,
	ShippingCity 	NVARCHAR2(50) NULL,
	ShippingStateCode NVARCHAR2(5) NULL,
	ShippingStateName NVARCHAR2(50) NULL,
	ShippingCountryName NVARCHAR2(50) NULL,
	ShippingFormalName NVARCHAR2(50) NULL,
	BillingCity NVARCHAR2(50) NULL,
	BillingStateCode 	NVARCHAR2(50) NULL,
	BillingStateName NVARCHAR2(50) NULL,
	BillingCountryName NVARCHAR2(50) NULL,
	BillingFormalName NVARCHAR2(50) NULL
);
	

CREATE OR REPLACE PROCEDURE Users_Extract
IS
    RowCt NUMBER(10):=0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE amazondmuser.Users_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO amazondmuser.Users_Stage
    WITH CityDetails AS (
        SELECT ci.CityID,
               ci.CityName,
               re.RegionCode,
               re.RegionName,
               co.CountryName,
               co.FormalName
        FROM amazondbuser.Cities ci
        LEFT JOIN amazondbuser.Regions re
            ON ci.RegionID = re.RegionID
        LEFT JOIN amazondbuser.Countries co
            ON re.CountryID = co.CountryID 
    )
    
    SELECT us.UserName,
           cat.UserCategoryName,
           dc.CityName,
           dc.RegionCode,
           dc.RegionName,
           dc.CountryName,
           dc.FormalName,
           pc.CityName,
           pc.RegionCode,
           pc.RegionName,
           pc.CountryName,
           pc.FormalName
    FROM amazondbuser.users us
    LEFT JOIN amazondbuser.UserCategories cat
        ON us.UserCategoryID = cat.UserCategoryID
    LEFT JOIN CityDetails dc
        ON us.ShippingCityID = dc.CityID
    LEFT JOIN CityDetails pc
        ON us.PostalCityID = pc.CityID;

    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of customers added: ' || TO_CHAR(SQL%ROWCOUNT));
    
EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;
/


--------------------------/*Items Table*/-------------------------------------------


CREATE TABLE Items_Stage(

	ItemName NVARCHAR2(100),
	ColorName NVARCHAR2(20),
	Brand NVARCHAR2(50),
	ItemSize NVARCHAR2(20)

)

-----------------Items_Extract procedure--------------------------------------

CREATE OR REPLACE PROCEDURE Items_Extract 
IS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE amazondmuser.Items_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO amazondmuser.Items_Stage
    SELECT si.ItemName, co.ColorName , si.Brand ,si.ItemSize
    FROM amazondbuser.Items si
    LEFT JOIN amazondbuser.Colors co
        ON si.ColorID = co.ColorID;

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
/

--------------------------/*SalesRep Table*/-------------------------------------------


CREATE TABLE SalesRep_Satge( 
	FullName 		NVARCHAR2(50) NULL,
	PreferredName 	NVARCHAR2(50) NULL,
	LogonName 		NVARCHAR2(50) NULL,
	PhoneNumber 	NVARCHAR2(20) NULL,
	FaxNumber 		NVARCHAR2(20) NULL,
	EmailAddress 	NVARCHAR2(256) NULL
);

-------------------SalesRep_Extract procedure---------------------------

CREATE OR REPLACE PROCEDURE SalesRep_Extract 
IS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE amazondmuser.SalesRep_Satge DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO amazondmuser.SalesRep_Satge
    SELECT Fullname, PreferredName,LogonName,PhoneNumber, FaxNumber, EmailAddress
    FROM amazondbuser.Persons
    WHERE IsSalesperson = 1;

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
/

--------------------------/*Vendors Table*/-------------------------------------------


CREATE TABLE Vendors_stage ( 

    VendorName            NVARCHAR2(255) NOT NULL,    
    VendorCategoryName  NVARCHAR2(255) NOT NULL,
    PhoneNumber        NVARCHAR2(20),             
    FaxNumber          NVARCHAR2(20),              
    WebsiteURL         NVARCHAR2(255)                              

);

------------Vendors extract procedure----------------------------------

CREATE OR REPLACE PROCEDURE Vendors_Extract 
IS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE amazondmuser.Vendors_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO amazondmuser.Vendors_Stage
    SELECT vn.VendorName , vc.vendorcategoryname , vn.phonenumber , vn.faxnumber , vn.websiteurl
    FROM amazondbuser.Vendors vn
    LEFT JOIN amazondbuser.VendorCategories vc
        ON vn.vendorcategoryid = vc.vendorcategoryid;

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
/

--------------------------/*Orders Table*/-------------------------------------------


CREATE TABLE Orders_Stage (
    OrderDate       DATE,
    Quantity        NUMBER(3),
    UnitPrice       NUMBER(18,2),
    TaxRate         NUMBER(18,3),
    UserName    NVARCHAR2(100),
    CityName        NVARCHAR2(50),
    StateeName   NVARCHAR2(50),
    CountryName     NVARCHAR2(60),
    ItemName   NVARCHAR2(100),
    PreferredName       NVARCHAR2(50),
	VendorName    NVARCHAR2(50)
	);


---------------Orders extract procedure-------------------------------

create or replace NONEDITIONABLE PROCEDURE Orders_Extract
AS
    RowCt NUMBER(10):= 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE amazondmuser.Orders_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO amazondmuser.Orders_Stage 
    WITH CityDetails AS (
        SELECT ci.CityID,
               ci.CityName,
               re.RegionCode,
               re.RegionName,
               co.CountryName,
               co.FormalName
        FROM amazondbuser.Cities ci
        LEFT JOIN amazondbuser.Regions re
            ON ci.RegionID = re.RegionID
        LEFT JOIN amazondbuser.Countries co
            ON re.CountryID = co.CountryID 
    )

    SELECT o.OrderDate
        ,ol.Quantity
        ,ol.UnitPrice
        ,ol.TaxRate
        ,u.UserName
        ,dc.cityname
        ,dc.Regionname
        ,dc.countryname
        ,i.ItemName
        ,p.PreferredName
		,vn.VendorName
    FROM amazondbuser.Orders o
        LEFT JOIN amazondbuser.OrderLines ol
            ON o.OrderID = ol.OrderID
        LEFT JOIN amazondbuser.users u
            ON o.UserID = u.UserID
        LEFT JOIN CityDetails dc
            ON u.ShippingCityID = dc.CityID
        LEFT JOIN amazondbuser.items i
            ON ol.itemid = i.ItemID
        LEFT JOIN amazondbuser.Persons p
            ON o.SalesrepPersonID = p.personid 
		LEFT JOIN amazondbuser.Vendors vn
            ON i.vendorid = vn.vendorid
		WHERE IsSalesPerson = 1
        AND ( nvl(ol.unitprice,0) <> 0 or nvl(ol.quantity,0) <> 0) ;

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
/

---------------------------------------------//**Transform Process**//-----------------------------------------------------

----------------/* Address Table */----------------------


---Address Preload table-----------

CREATE TABLE Address_Preload (
    AddressKey NUMBER(10) NOT NULL,	
    CityName NVARCHAR2(50) NULL,
    StateCode NVARCHAR2(5) NULL,
    StateName NVARCHAR2(50) NULL,
    CountryName NVARCHAR2(60) NULL,
    CountryFormalName NVARCHAR2(60) NULL,
	CONSTRAINT PK_Address_Preload PRIMARY KEY (AddressKey)

);

CREATE SEQUENCE AddressKey START WITH 1 CACHE 10; --Create sequence for Address KEY


-------Address Transform procedure--------------------------

CREATE OR REPLACE PROCEDURE Address_Transform --Type 1 SCD
AS
  RowCt NUMBER(10):=0;
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Address_Preload DROP STORAGE';
  CurrentRows NUMBER(10):=0; -- Variable to store rows affected by each INSERT

BEGIN
    EXECUTE IMMEDIATE v_sql;
--BEGIN TRANSACTION;
    INSERT INTO Address_Preload /* Column list excluded for brevity */
    SELECT AddressKey.NEXTVAL AS AddressKey,
           cu.ShippingCity,
           cu.ShippingStateCode,
           cu.shippingStateName,
           cu.ShippingCountryName,
           cu.ShippingFormalName
    FROM Users_Stage cu
    WHERE NOT EXISTS 
	( SELECT 1 
              FROM DimAddress loc
              WHERE cu.ShippingCity = loc.City
                AND cu.shippingStateName = loc.StateName
                AND cu.ShippingCountryName = loc.CountryName 
        );
    
    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count
    
    INSERT INTO Address_Preload /* Column list excluded for brevity */
    SELECT loc.AddressKey,
           cu.ShippingCity,
           cu.ShippingStateCode,
           cu.shippingStateName,
           cu.ShippingCountryName,
           cu.ShippingFormalName
    FROM Users_Stage cu
    JOIN DimAddress loc
        ON cu.ShippingCity = loc.City
        AND cu.shippingStateName = loc.StateName
        AND cu.ShippingCountryName = loc.CountryName;
        
    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count
    
--COMMIT TRANSACTION;
    IF RowCt = 0 THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSIF RowCt > 0 THEN
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted in Address_Preload!');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

/

----------------User Preload table------------------

CREATE TABLE Users_Preload(   -- Type 2 SCD
	UserKey 		NUMBER(10),
	UserName 		NVARCHAR2(100) NULL,
	UserCategory  NVARCHAR2(50) NULL,
	ShippingCity 	NVARCHAR2(50) NULL,
	ShippingStateCode NVARCHAR2(5) NULL,
	ShippingCountryName NVARCHAR2(50) NULL,
	BillingCity NVARCHAR2(50) NULL,
	BillingStateCode 	NVARCHAR2(50) NULL,
	BillingCountryName NVARCHAR2(50) NULL,
	StartDate 			DATE NOT NULL,
	EndDate 			DATE NULL,
   CONSTRAINT PK_Users_Preload PRIMARY KEY ( UserKey )  
);

CREATE SEQUENCE UserKey START WITH 1 CACHE 10; --Create sequence for User Key


-------User transform procedure ---------------

CREATE OR REPLACE PROCEDURE Users_Transform  --Type 2 SCD
AS
  RowCt NUMBER(10):= 0;
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Users_Preload DROP STORAGE';
  StartDate DATE := SYSDATE; 
  EndDate DATE := SYSDATE - 1;
  CurrentRows NUMBER(10):= 0; -- Variable to store rows affected by each INSERT

BEGIN
    EXECUTE IMMEDIATE v_sql;
 --BEGIN TRANSACTION;
 -- Add updated records
    INSERT INTO Users_Preload /* Column list excluded for brevity */
    SELECT UserKey.NEXTVAL AS UserKey,
           stg.UserName,
           stg.UserCategory,
           stg.ShippingCity,
           stg.ShippingStateCode,
           stg.ShippingCountryName,
           stg.BillingCity,
           stg.BillingStateCode,
           stg.BillingCountryName,
           StartDate,
           NULL
    FROM Users_Stage stg
    JOIN DimUsers cu
        ON stg.UserName = cu.UserName AND cu.EndDate IS NULL
    WHERE stg.UserCategory <> cu.UserCategory
          OR stg.ShippingCity <> cu.ShippingCity
          OR stg.ShippingStateCode <> cu.ShippingStateCode
          OR stg.ShippingCountryName <> cu.ShippingCountryName
          OR stg.BillingCity <> cu.BillingCity
          OR stg.BillingStateCode <> cu.BillingStateCode
          OR stg.BillingCountryName <> cu.BillingCountryName;
          
    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count
    
    -- Add existing records, and expire as necessary
    INSERT INTO Users_Preload /* Column list excluded for brevity */
    SELECT cu.UserKey,
           cu.UserName,
           cu.UserCategory,
           cu.ShippingCity,
           cu.ShippingStateCode,
           cu.ShippingCountryName,
           cu.BillingCity,
           cu.BillingStateCode,
           cu.BillingCountryName,
           cu.StartDate,
           CASE 
               WHEN pl.UserName IS NULL THEN NULL
               ELSE cu.EndDate
           END AS EndDate
    FROM DimUsers cu
    LEFT JOIN Users_Preload pl    
        ON pl.UserName = cu.UserName
        AND cu.EndDate IS NULL;
        
    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count
    
 -- Create new records
    INSERT INTO Users_Preload /* Column list excluded for brevity */
    SELECT UserKey.NEXTVAL AS UserKey,
           stg.UserName,
           stg.UserCategory,
           stg.ShippingCity,
           stg.ShippingStateCode,
           stg.ShippingCountryName,
           stg.BillingCity,
           stg.BillingStateCode,
           stg.BillingCountryName,
           StartDate,
           NULL
    FROM Users_Stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM DimUsers cu WHERE  stg.UserName = cu.UserName);
    
    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count
    
    -- Expire missing records
    INSERT INTO Users_Preload /* Column list excluded for brevity */
    SELECT cu.Userkey,
            cu.UserName,
           cu.UserCategory,
           cu.ShippingCity,
           cu.ShippingStateCode,
           cu.ShippingCountryName,
           cu.BillingCity,
           cu.BillingStateCode,
           cu.BillingCountryName,
           cu.StartDate,
           EndDate
    FROM DimUsers cu
    WHERE NOT EXISTS ( SELECT 1 FROM Users_Stage stg WHERE stg.UserName = cu.UserName )
          AND cu.EndDate IS NULL;
          
    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count

    IF RowCt = 0 THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSIF RowCt > 0 THEN
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted in Users_Preload!');
    END IF;
--COMMIT TRANSACTION;
EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;
/

-------Sales Rep procedure ---------------


CREATE TABLE SalesRep_Preload (
    SalesRepKey INT NOT NULL,
    FullName NVARCHAR2(50) NULL,
    PreferredName NVARCHAR2(50) NULL,
    LogonName NVARCHAR2(50) NULL,
    PhoneNumber NVARCHAR2(20) NULL,
    FaxNumber NVARCHAR2(20) NULL,
    EmailAddress NVARCHAR2(256) NULL,
    CONSTRAINT PK_SalesRep_Preload PRIMARY KEY (SalesRepKey)
);

CREATE SEQUENCE SalesRepKeySeq START WITH 1 CACHE 10; -- Sequence for SalesRepKey


CREATE OR REPLACE PROCEDURE SalesRep_Transform
AS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE SalesRep_Preload DROP STORAGE';
    CurrentRows NUMBER(10) := 0;
BEGIN
    -- Truncate the Preload table
    EXECUTE IMMEDIATE v_sql;

    -- Insert new sales rep records into the preload table
    INSERT INTO SalesRep_Preload (SalesRepKey, FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress)
    SELECT SalesRepKeySeq.NEXTVAL AS SalesRepKey,
           sr.FullName,
           sr.PreferredName,
           sr.LogonName,
           sr.PhoneNumber,
           sr.FaxNumber,
           sr.EmailAddress
    FROM SalesRep_Satge sr
    WHERE NOT EXISTS (
        SELECT 1
        FROM DimSalesRep dim
        WHERE sr.FullName = dim.FullName
          AND sr.PreferredName = dim.PreferredName
          AND sr.LogonName = dim.LogonName
          AND sr.PhoneNumber = dim.PhoneNumber
          AND sr.FaxNumber = dim.FaxNumber
          AND sr.EmailAddress = dim.EmailAddress
    );

    CurrentRows := SQL%ROWCOUNT;
    RowCt := RowCt + CurrentRows;

    -- Update existing sales rep records in the preload table
    INSERT INTO SalesRep_Preload (SalesRepKey, FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress)
    SELECT dim.SalesRepKey,
           sr.FullName,
           sr.PreferredName,
           sr.LogonName,
           sr.PhoneNumber,
           sr.FaxNumber,
           sr.EmailAddress
    FROM SalesRep_Satge sr
    JOIN DimSalesRep dim
        ON sr.FullName = dim.FullName
        AND sr.PreferredName = dim.PreferredName
        AND sr.LogonName = dim.LogonName
        AND sr.PhoneNumber = dim.PhoneNumber
        AND sr.FaxNumber = dim.FaxNumber
        AND sr.EmailAddress = dim.EmailAddress;

    CurrentRows := SQL%ROWCOUNT;
    RowCt := RowCt + CurrentRows;

    -- Capture row count and provide feedback
    IF RowCt = 0 THEN
        dbms_output.put_line('No records found. Check with source system.');
    ELSE
        dbms_output.put_line(TO_CHAR(RowCt) || ' Rows have been inserted in SalesRep_Preload!');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error occurred: ' || SQLERRM);
        dbms_output.put_line(v_sql);
END;
/

------------Items Preload and Transform-----------------------------------------

CREATE TABLE Items_Preload (
    ItemKey INT NOT NULL,
    ItemName NVARCHAR2(100) NULL,
    ColorName NVARCHAR2(20) NULL,
    Brand NVARCHAR2(50) NULL,
    ItemSize NVARCHAR2(20) NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    CONSTRAINT PK_Items_Preload PRIMARY KEY (ItemKey)
);

CREATE SEQUENCE ItemKeySeq START WITH 1 CACHE 10; -- Sequence for ItemKey


CREATE OR REPLACE PROCEDURE Items_Transform
AS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Items_Preload DROP STORAGE';
    StartDate DATE := SYSDATE;
    EndDate DATE := SYSDATE - 1;
    CurrentRows NUMBER(10) := 0;
BEGIN
    -- Truncate the Items_Preload table
    EXECUTE IMMEDIATE v_sql;

    -- Insert updated records into Items_Preload
    INSERT INTO Items_Preload
    SELECT 
        ItemKeySeq.NEXTVAL AS ItemKey,
        stg.ItemName,
        stg.ColorName,
        stg.Brand,
        stg.ItemSize,
        StartDate,
        NULL
    FROM Items_Stage stg
    JOIN DimProducts dp
        ON stg.ItemName = dp.ProductName AND dp.EndDate IS NULL
    WHERE stg.ColorName <> dp.ProductColour
          OR stg.Brand <> dp.ProductBrand
          OR stg.ItemSize <> dp.ProductSize;

    CurrentRows := SQL%ROWCOUNT;
    RowCt := RowCt + CurrentRows;

    -- Add existing records to Items_Preload and expire as necessary
    INSERT INTO Items_Preload
    SELECT
        dp.ProductKey AS ItemKey,
        dp.ProductName AS ItemName,
        dp.ProductColour AS ColorName,
        dp.ProductBrand AS Brand,
        dp.ProductSize AS ItemSize,
        dp.StartDate,
        CASE 
            WHEN pl.ItemName IS NULL THEN NULL
            ELSE dp.EndDate
        END AS EndDate
    FROM DimProducts dp
    LEFT JOIN Items_Preload pl   
        ON pl.ItemName = dp.ProductName
        AND dp.EndDate IS NULL;

    CurrentRows := SQL%ROWCOUNT;
    RowCt := RowCt + CurrentRows;

    -- Create new records in Items_Preload
    INSERT INTO Items_Preload
    SELECT
        ItemKeySeq.NEXTVAL AS ItemKey,
        stg.ItemName,
        stg.ColorName,
        stg.Brand,
        stg.ItemSize,
        StartDate,
        NULL
    FROM Items_Stage stg
    WHERE NOT EXISTS (
        SELECT 1 
        FROM DimProducts dp 
        WHERE stg.ItemName = dp.ProductName
    );

    CurrentRows := SQL%ROWCOUNT;
    RowCt := RowCt + CurrentRows;

    -- Expire missing records in Items_Preload
    INSERT INTO Items_Preload
    SELECT
        dp.ProductKey AS ItemKey,
        dp.ProductName AS ItemName,
        dp.ProductColour AS ColorName,
        dp.ProductBrand AS Brand,
        dp.ProductSize AS ItemSize,
        dp.StartDate,
        EndDate
    FROM DimProducts dp
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Items_Stage stg 
        WHERE stg.ItemName = dp.ProductName
    )
    AND dp.EndDate IS NULL;

    CurrentRows := SQL%ROWCOUNT;
    RowCt := RowCt + CurrentRows;

    -- Log the number of rows inserted
    IF RowCt = 0 THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSE
       dbms_output.put_line(TO_CHAR(RowCt) || ' Rows have been inserted in Items_Preload!');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error: ' || SQLERRM);
        dbms_output.put_line(v_sql);
        ROLLBACK;
END;
/

--------------Vendors Table ---------------------------------------------

CREATE TABLE Vendors_Preload (
    VendorKey NUMBER(10) NOT NULL,
    VendorName NVARCHAR2(255) NOT NULL,
    VendorCategoryName NVARCHAR2(255) NOT NULL,
    PhoneNumber NVARCHAR2(20),
    FaxNumber NVARCHAR2(20),
    WebsiteURL NVARCHAR2(255),
    StartDate DATE NOT NULL,
    EndDate DATE,
    CONSTRAINT PK_Vendors_Preload PRIMARY KEY (VendorKey)
);

CREATE SEQUENCE VendorKeySeq START WITH 1 CACHE 10; -- Sequence for VendorKey


CREATE OR REPLACE PROCEDURE Vendors_Transform
AS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Vendors_Preload DROP STORAGE';
    StartDate DATE := SYSDATE;
    EndDate DATE := SYSDATE - 1;
    CurrentRows NUMBER(10) := 0; -- Variable to store rows affected by each INSERT
BEGIN
    -- Truncate the Vendors_Preload table
    EXECUTE IMMEDIATE v_sql;

    -- Insert updated records into Vendors_Preload
    INSERT INTO Vendors_Preload
    SELECT
        VendorKeySeq.NEXTVAL AS VendorKey,
        stg.VendorName,
        stg.VendorCategoryName,
        stg.PhoneNumber,
        stg.FaxNumber,
        stg.WebsiteURL,
        StartDate,
        NULL
    FROM Vendors_Stage stg
    JOIN DimVendors dv
        ON stg.VendorName = dv.VendorName AND dv.EndDate IS NULL
    WHERE stg.VendorCategoryName <> dv.VendorCategoryName
          OR stg.PhoneNumber <> dv.PhoneNumber
          OR stg.FaxNumber <> dv.FaxNumber
          OR stg.WebsiteURL <> dv.WebsiteURL;

    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the first INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count

    -- Add existing records to Vendors_Preload and expire as necessary
    INSERT INTO Vendors_Preload
    SELECT
        dv.VendorKey,
        dv.VendorName,
        dv.VendorCategoryName,
        dv.PhoneNumber,
        dv.FaxNumber,
        dv.WebsiteURL,
        dv.StartDate,
        CASE
            WHEN pl.VendorName IS NULL THEN NULL
            ELSE dv.EndDate
        END AS EndDate
    FROM DimVendors dv
    LEFT JOIN Vendors_Preload pl
        ON pl.VendorName = dv.VendorName
        AND dv.EndDate IS NULL;

    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count

    -- Create new records in Vendors_Preload
    INSERT INTO Vendors_Preload
    SELECT
        VendorKeySeq.NEXTVAL AS VendorKey,
        stg.VendorName,
        stg.VendorCategoryName,
        stg.PhoneNumber,
        stg.FaxNumber,
        stg.WebsiteURL,
        StartDate,
        NULL
    FROM Vendors_Stage stg
    WHERE NOT EXISTS (
        SELECT 1
        FROM DimVendors dv
        WHERE stg.VendorName = dv.VendorName
    );

    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count

    -- Expire missing records in Vendors_Preload
    INSERT INTO Vendors_Preload
    SELECT
        dv.VendorKey,
        dv.VendorName,
        dv.VendorCategoryName,
        dv.PhoneNumber,
        dv.FaxNumber,
        dv.WebsiteURL,
        dv.StartDate,
        EndDate
    FROM DimVendors dv
    WHERE NOT EXISTS (
        SELECT 1
        FROM Vendors_Stage stg
        WHERE stg.VendorName = dv.VendorName
    )
    AND dv.EndDate IS NULL;

    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count

    -- Log the number of rows inserted
    IF RowCt = 0 THEN
       dbms_output.put_line('No records found in Vendors. Check with source system.');
    ELSE
       dbms_output.put_line(TO_CHAR(RowCt) || ' Rows have been inserted in Vendors_Preload!');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_sql);
        ROLLBACK;
END;
/

---Invoice Preload table-----------------

CREATE TABLE Invoice_Preload (
    InvoiceKey      NUMBER(10),
    InvoiceDate     DATE NOT NULL,
    TotalAmount     NUMBER(18, 2) NOT NULL,
    Status          NVARCHAR2(20) NULL,
    StartDate       DATE NOT NULL,
    EndDate         DATE NULL,
    CONSTRAINT PK_Invoice_Preload PRIMARY KEY (InvoiceKey)
);

CREATE SEQUENCE InvoiceKey START WITH 1 CACHE 10; -- Create sequence for Invoice Key

CREATE OR REPLACE PROCEDURE Invoice_Transform -- Type 2 SCD for DimInvoices
AS
    RowCt NUMBER(10) := 0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Invoice_Preload DROP STORAGE';
    StartDate DATE := SYSDATE; 
    EndDate DATE := SYSDATE - 1;
    CurrentRows NUMBER(10) := 0; -- Variable to store rows affected by each INSERT
BEGIN
    -- Truncate the Invoice_Preload table
    EXECUTE IMMEDIATE v_sql;

    -- Step 1: Aggregate data for insertion
    INSERT INTO Invoice_Preload (
        InvoiceKey,
        InvoiceDate,
        TotalAmount,
        Status,
        StartDate,
        EndDate
    )
    SELECT 
        InvoiceKey.NEXTVAL,                         -- Generate a new InvoiceKey
        agg.OrderDate,                              -- Grouped OrderDate
        agg.TotalAmount,                            -- Aggregated TotalAmount
        'New' AS Status,                            -- Set the status as 'New'
        StartDate,                                  -- Start date of the invoice validity
        NULL                                        -- End date of the invoice validity
    FROM (
        SELECT 
            stg.OrderDate,
            SUM(NVL(stg.Quantity, 0) * NVL(stg.UnitPrice, 0) * (1 + NVL(stg.TaxRate, 0) / 100)) AS TotalAmount
        FROM Orders_Stage stg
        WHERE NOT EXISTS (
            SELECT 1 
            FROM DimInvoices di 
            WHERE stg.OrderDate = di.InvoiceDate    -- Ensure no existing record for the OrderDate in DimInvoices
        )
        GROUP BY stg.OrderDate
    ) agg;

    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count

    -- Expire missing records in Invoice_Preload
    INSERT INTO Invoice_Preload (
        InvoiceKey,
        InvoiceDate,
        TotalAmount,
        Status,
        StartDate,
        EndDate
    )
    SELECT 
        di.InvoiceKey,
        di.InvoiceDate,
        di.TotalAmount,
        di.Status,
        di.StartDate,
        EndDate
    FROM DimInvoices di
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Orders_Stage stg 
        WHERE stg.OrderDate = di.InvoiceDate
    )
    AND di.EndDate IS NULL;

    CurrentRows := SQL%ROWCOUNT; -- Get the rows affected by the INSERT
    RowCt := RowCt + CurrentRows; -- Accumulate the total row count
    
    -- Log the number of rows inserted
    IF RowCt = 0 THEN
       DBMS_OUTPUT.PUT_LINE('No records found. Check with source system.');
    ELSIF RowCt > 0 THEN
       DBMS_OUTPUT.PUT_LINE(TO_CHAR(RowCt) || ' Rows have been inserted in Invoice_Preload!');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_sql);
        ROLLBACK;
END;

/

-----Orders Preload table-------------------------------------------------------------------------


CREATE TABLE Orders_Preload (
    UserKey        NUMBER(10) NOT NULL,            -- Foreign key reference to Users_Preload
    AddressKey     NUMBER(10) NOT NULL,            -- Foreign key reference to Address_Preload
    ItemKey     NUMBER(10) NOT NULL,            -- Foreign key reference to Items_Preload (Product)
    SalesrepKey    NUMBER(10) NOT NULL,            -- Foreign key reference to SalesRep_Preload
    DateKey        NUMBER(8) NOT NULL,             -- Date in YYYYMMDD format
    VendorKey      NUMBER(10) NOT NULL,            -- Foreign key reference to Vendors_Preload
    InvoiceKey     NUMBER(10) NOT NULL,            -- Foreign key reference to Invoice_Preload
    Quantity       NUMBER(4) NOT NULL,             -- Quantity of the product
    UnitPrice      NUMBER(18, 2) NOT NULL,         -- Price of a single unit of the product
    TaxRate        NUMBER(18, 3) NOT NULL,         -- Tax rate (percentage)
    TotalBeforeTax NUMBER(18, 2) NOT NULL,         -- Total amount before tax
    TotalAfterTax  NUMBER(18, 2) NOT NULL,         -- Total amount after tax
    CONSTRAINT PK_Orders_Preload PRIMARY KEY (UserKey, AddressKey, ItemKey, DateKey,VendorKey,SalesrepKey,InvoiceKey),  -- Composite primary key to uniquely identify records
    CONSTRAINT FK_Orders_Preload_User FOREIGN KEY (UserKey) REFERENCES Users_Preload(UserKey),  -- Foreign key to Users_Preload
    CONSTRAINT FK_Orders_Preload_Address FOREIGN KEY (AddressKey) REFERENCES Address_Preload(AddressKey),  -- Foreign key to Address_Preload
    CONSTRAINT FK_Orders_Preload_Items FOREIGN KEY (ItemKey) REFERENCES Items_Preload(ItemKey),  -- Foreign key to Items_Preload
    CONSTRAINT FK_Orders_Preload_SalesRep FOREIGN KEY (SalesrepKey) REFERENCES SalesRep_Preload(SalesRepKey),  -- Foreign key to SalesRep_Preload
    CONSTRAINT FK_Orders_Preload_Vendor FOREIGN KEY (VendorKey) REFERENCES Vendors_Preload(VendorKey),  -- Foreign key to Vendors_Preload
    CONSTRAINT FK_Orders_Preload_Invoice FOREIGN KEY (InvoiceKey) REFERENCES Invoice_Preload(InvoiceKey)  -- Foreign key to Invoice_Preload
);

-- Indexes for Orders_Preload table

CREATE INDEX IX_Orders_Preload_UserKey ON Orders_Preload(UserKey);
CREATE INDEX IX_Orders_Preload_AddressKey ON Orders_Preload(AddressKey);
CREATE INDEX IX_Orders_Preload_ItemKey ON Orders_Preload(ItemKey);
CREATE INDEX IX_Orders_Preload_SalesrepKey ON Orders_Preload(SalesrepKey);
CREATE INDEX IX_Orders_Preload_DateKey ON Orders_Preload(DateKey);
CREATE INDEX IX_Orders_Preload_VendorKey ON Orders_Preload(VendorKey);
CREATE INDEX IX_Orders_Preload_InvoiceKey ON Orders_Preload(InvoiceKey);


CREATE OR REPLACE PROCEDURE Orders_Transform
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Orders_Preload DROP STORAGE';
BEGIN
    -- Truncate the target Orders_Preload table
    EXECUTE IMMEDIATE v_sql;

    -- Insert transformed data into Orders_Preload, linking it with Invoice data
    INSERT INTO Orders_Preload (
        UserKey,
        AddressKey,
        ItemKey,
        SalesrepKey,
        DateKey,
        VendorKey,
        InvoiceKey,          -- Adding InvoiceKey to link with Invoice_Preload
        Quantity,
        UnitPrice,
        TaxRate,
        TotalBeforeTax,
        TotalAfterTax
    )
    SELECT 
        cu.UserKey,
        addr.AddressKey,
        itm.ItemKey,                     -- ProductKey from ItemName
        sp.SalesrepKey,
        EXTRACT(YEAR FROM ord.OrderDate)*10000 + EXTRACT(Month FROM ord.OrderDate)*100 + EXTRACT(Day FROM ord.OrderDate) AS DateKey,  -- Derive DateKey from OrderDate
        vn.VendorKey,
        inv.InvoiceKey,                    -- Linking the InvoiceKey for the current order
        SUM(ord.Quantity) AS Quantity,
        AVG(ord.UnitPrice) AS UnitPrice,
        AVG(ord.TaxRate) AS TaxRate,
        SUM(ord.Quantity * ord.UnitPrice) AS TotalBeforeTax,
        SUM(ord.Quantity * ord.UnitPrice * (1 + ord.TaxRate / 100)) AS TotalAfterTax
    FROM Orders_Stage ord
    JOIN Users_Preload cu
        ON ord.UserName = cu.UserName
    JOIN Address_Preload addr
        ON ord.CityName = addr.CityName 
        AND ord.StateeName = addr.StateName 
        AND ord.CountryName = addr.CountryName
    JOIN Items_Preload itm
        ON ord.ItemName = itm.ItemName
    JOIN SalesRep_Preload sp
        ON ord.PreferredName = sp.PreferredName
    JOIN Vendors_Preload vn
        ON ord.VendorName = vn.VendorName
    LEFT JOIN Invoice_Preload inv        -- Join with Invoice_Preload to get the correct InvoiceKey
        ON ord.OrderDate = inv.InvoiceDate  -- Assuming OrderDate and InvoiceDate are the same
    GROUP BY 
        cu.UserKey,
        addr.AddressKey,
        itm.ItemKey,
        sp.SalesrepKey,
        EXTRACT(YEAR FROM ord.OrderDate)*10000 + EXTRACT(Month FROM ord.OrderDate)*100 + EXTRACT(Day FROM ord.OrderDate), -- Group by DateKey derived from OrderDate
        vn.VendorKey,
        inv.InvoiceKey;                  -- Include InvoiceKey in the group by clause

    -- Log the number of rows inserted
    RowCt := SQL%ROWCOUNT;
    IF RowCt = 0 THEN
        dbms_output.put_line('No records found in Orders_Stage. Check with the source system.');
    ELSIF RowCt > 0 THEN
        dbms_output.put_line(TO_CHAR(RowCt) || ' Rows have been inserted into Orders_Preload!');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_sql);
        ROLLBACK;
END;
/

---------------------------------------------//**LOAD Process**//-----------------------------------------------------

-----------------------Address Load Procedure-------------------------------

CREATE OR REPLACE PROCEDURE Address_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimAddress dl
    WHERE EXISTS (SELECT null FROM Address_Preload pl
                    WHERE dl.AddressKey = pl.AddressKey);

    INSERT INTO DimAddress /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Address_Preload;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback if any error occurs 
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;  -- Reraise the exception for further handling
END;
/
-------------------------Users Load Procedure-------------------------------

CREATE OR REPLACE PROCEDURE Users_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimUsers cu
    WHERE EXISTS (SELECT null FROM Users_Preload pl
                    WHERE cu.UserKey = pl.UserKey);

    INSERT INTO DimUsers /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Users_Preload;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback if any error occurs 
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;  -- Reraise the exception for further handling
END;
/
---------------------------SalesRep Load Procedure---------------------------

CREATE OR REPLACE PROCEDURE SalesRep_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimSalesRep dl
    WHERE EXISTS (SELECT null FROM SalesRep_Preload pl
                    WHERE dl.SalesRepKey = pl.SalesRepKey);

    INSERT INTO DimSalesRep /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM SalesRep_Preload;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback if any error occurs 
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;  -- Reraise the exception for further handling
END;
/
--------------Items Load Procedure-----------------------------------
CREATE OR REPLACE PROCEDURE Items_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimProducts dl
    WHERE EXISTS (SELECT null FROM Items_Preload pl
                    WHERE dl.ProductKey = pl.ItemKey);

    INSERT INTO DimProducts /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Items_Preload;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback if any error occurs 
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;  -- Reraise the exception for further handling
END;
/
------Vendors Load Procedure-----------------------------------------------------


CREATE OR REPLACE PROCEDURE Vendors_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimVendors dl
    WHERE EXISTS (SELECT null FROM Vendors_Preload pl
                    WHERE dl.VendorKey = pl.VendorKey);

    INSERT INTO DimVendors /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Vendors_Preload;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback if any error occurs 
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;  -- Reraise the exception for further handling
END;
/

------Invoice Load Procedure-----------------------------------------------------


CREATE OR REPLACE PROCEDURE Invoice_Load
AS
BEGIN
    --START TRANSACTION;

    DELETE FROM DimInvoices dl
    WHERE EXISTS (SELECT null FROM Invoice_Preload pl
                    WHERE dl.InvoiceKey = pl.InvoiceKey);

    INSERT INTO DimInvoices /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Invoice_Preload;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback if any error occurs 
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;  -- Reraise the exception for further handling
END;
/
-------------Orders Load Procedure-----------------------------------

CREATE OR REPLACE PROCEDURE Orders_Load
AS
BEGIN
    INSERT INTO FactAmazonSales /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM Orders_Preload ord;
	
	DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into FactAmazonSales');

    COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback if any error occurs 
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;  -- Reraise the exception for further handling
END;
/

----------------EXECUTE ALL ETL procedures--------------------------------------------


-----------------------Extract Execution----------------------------------------------

TRUNCATE TABLE users_stage;
EXECUTE Users_Extract;
SELECT COUNT(*) FROM users_stage;

TRUNCATE TABLE items_stage;
EXECUTE Items_Extract;
SELECT COUNT(*) FROM items_stage;

TRUNCATE TABLE SalesRep_satge;
EXECUTE SalesRep_Extract;
SELECT COUNT(*) FROM SalesRep_satge;

TRUNCATE TABLE Vendors_stage;
EXECUTE Vendors_Extract;
SELECT COUNT(*) FROM Vendors_stage;

TRUNCATE TABLE Orders_Stage;
EXECUTE Orders_Extract;
SELECT COUNT(*) FROM Orders_Stage;

----------------------Transform Execution------------------------------------------

TRUNCATE TABLE FACTAMAZONSALES;

EXECUTE Address_Transform;
SELECT COUNT(*) FROM Address_preload;

EXECUTE Users_Transform;
SELECT COUNT(*) FROM users_preload;

EXECUTE salesrep_Transform;
SELECT COUNT(*) FROM salesrep_preload;

EXECUTE Items_Transform;
SELECT COUNT(*) FROM items_preload;

EXECUTE Vendors_Transform;
SELECT COUNT(*) FROM vendors_preload;

EXECUTE Invoice_Transform;
SELECT COUNT(*) FROM invoice_preload;

EXECUTE Orders_Transform;
SELECT COUNT(*) FROM orders_preload;

----------------------LOAD Execution------------------------------------------

EXECUTE address_load;
SELECT COUNT(*) FROM DIMADDRESS;

EXECUTE users_load;
SELECT COUNT(*) FROM DIMUSERS;

EXECUTE salesrep_load;
SELECT COUNT(*) FROM DIMSALESREP;

EXECUTE items_load;
SELECT COUNT(*) FROM DIMPRODUCTS;

EXECUTE vendors_load;
SELECT COUNT(*) FROM DIMVENDORS;

EXECUTE invoice_load;
SELECT COUNT(*) FROM DIMINVOICE;

EXECUTE orders_load;
SELECT COUNT(*) FROM FACTAMAZONSALES;

SELECT * FROM FACTAMAZONSALES;

