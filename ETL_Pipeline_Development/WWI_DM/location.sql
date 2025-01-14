CREATE TABLE wwidbuser.Cities(
	CityID NUMBER(10),
	CityName nvarchar2(50) NOT NULL,
	StateProvinceID NUMBER(10) NOT NULL,
	LatestRecordedPopulation NUMBER(12) NULL,
 CONSTRAINT PK_Cities_ID PRIMARY KEY (CityID), 
 CONSTRAINT FK_Cities_StateProvinceID_StateProvinces FOREIGN KEY(StateProvinceID) REFERENCES wwidbuser.StateProvinces (StateProvinceID)
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
TRUNCATE TABLE Locations_Preload;
EXECUTE Locations_Transform;
SELECT COUNT(*) FROM locations_preload;

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