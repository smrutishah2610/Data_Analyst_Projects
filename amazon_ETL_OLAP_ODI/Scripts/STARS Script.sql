
------- CREATE Amazon DM USER --------
ALTER session set "_ORACLE_SCRIPT" = true;
CREATE USER amazondmuser identified by amazondmuser;
GRANT ALL PRIVILEGES TO amazondmuser;
SELECT * FROM all_users ORDER BY Created DESC;

-----------------------------------------------

CREATE TABLE DimAddress(  -- Type 1 SCD
	AddressKey 	NUMBER(10),
	City    		NVARCHAR2(50) NULL,
	StateCode    	NVARCHAR2(5) NULL,
	StateName   	NVARCHAR2(50) NULL,
	CountryName 	NVARCHAR2(60) NULL,
	CountryFullName NVARCHAR2(60) NULL,
    CONSTRAINT PK_DimAddress PRIMARY KEY ( AddressKey )
);


CREATE TABLE DimUsers(   -- Type 2 SCD
	UserKey 		        NUMBER(10),
	UserName 		NVARCHAR2(100) NULL,
	UserCategory  NVARCHAR2(50) NULL,
	ShippingCity 	NVARCHAR2(50) NULL,
	ShippingStateCode NVARCHAR2(50) NULL,
	ShippingCountryName NVARCHAR2(50) NULL,
	BillingCity NVARCHAR2(50) NULL,
	BillingStateCode 	NVARCHAR2(50) NULL,
	BillingCountryName NVARCHAR2(50) NULL,
	StartDate 			DATE NOT NULL,
	EndDate 			DATE NULL,
    CONSTRAINT PK_DimUsers PRIMARY KEY ( UserKey )
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

CREATE TABLE DimSalesRep(    -- Type 1 SCD
	SalesRepKey 	NUMBER(10),
	FullName 		NVARCHAR2(50) NULL,
	PreferredName 	NVARCHAR2(50) NULL,
	LogonName 		NVARCHAR2(50) NULL,
	PhoneNumber 	NVARCHAR2(20) NULL,
	FaxNumber 		NVARCHAR2(20) NULL,
	EmailAddress 	NVARCHAR2(256) NULL,
    CONSTRAINT PK_DimSalesRep PRIMARY KEY (SalesRepKey )
);

CREATE TABLE DimVendors ( --Type 2 SCD 
    VendorKey             NUMBER(10) ,
    VendorName            NVARCHAR2(255) NOT NULL,    
    VendorCategoryName  NVARCHAR2(255) NOT NULL,
    PhoneNumber        NVARCHAR2(20),             
    FaxNumber          NVARCHAR2(20),              
    WebsiteURL         NVARCHAR2(255),            
    StartDate          DATE NOT NULL,            
    EndDate            DATE,                      
    CONSTRAINT PK_DimVendors  PRIMARY KEY ( VendorKey )

);

CREATE TABLE DimInvoices (   -- Type 2 SCD 
    InvoiceKey      NUMBER(10),
    InvoiceDate     DATE NOT NULL,
    TotalAmount     NUMBER(18, 2) NOT NULL,
    Status          NVARCHAR2(20) NULL,
    StartDate       DATE NOT NULL,
    EndDate         DATE NULL,
    CONSTRAINT PK_DimInvoices PRIMARY KEY (InvoiceKey)
);


CREATE TABLE DimDate (
    DateKey    	    NUMBER(10) NOT NULL,
    DateValue  	    DATE NOT NULL,
    CYear 	        NUMBER(10) NOT NULL,
    CQtr 	        NUMBER(1) NOT NULL,
    CMonth 	        NUMBER(2) NOT NULL,
    DayNo 	        NUMBER(2) NOT NULL,
    StartOfMonth    DATE NOT NULL,
    EndOfMonth  	DATE NOT NULL,
    MonthName   	VARCHAR2(9) NOT NULL,
    DayOfWeekName   VARCHAR2(9) NOT NULL,    

    CONSTRAINT PK_DimDate PRIMARY KEY ( DateKey )
);



---Fact Table with indexes-----
CREATE TABLE FactAmazonSales (
    UserKey      	NUMBER(10) NOT NULL,
    AddressKey      	NUMBER(10) NOT NULL,
    ProductKey       	NUMBER(10) NOT NULL,
    SalesrepKey   	NUMBER(10) NOT NULL,
    DateKey 	      	NUMBER(8) NOT NULL,
    VendorKey         NUMBER(10) NOT NULL,
    InvoiceKey     NUMBER(10) NOT NULL,            -- Foreign key reference to Invoice_Preload
    Quantity 	      	NUMBER(4) NOT NULL,
    UnitPrice        	NUMBER(18,2) NOT NULL,
    TaxRate 	      	NUMBER(18,3) NOT NULL,
    TotalBeforeTax   	NUMBER(18,2) NOT NULL,
    TotalAfterTax    	NUMBER(18,2) NOT NULL,
    CONSTRAINT FK_FactAmazonSales_DimUsers FOREIGN KEY (UserKey) REFERENCES DimUsers(UserKey),
    CONSTRAINT FK_FactAmazonSales_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT FK_FactAmazonSales_DimAddress FOREIGN KEY (AddressKey) REFERENCES DimAddress (AddressKey),
    CONSTRAINT FK_FactAmazonSales_DimProducts FOREIGN KEY (ProductKey) REFERENCES DimProducts(ProductKey),
    CONSTRAINT FK_FactAmazonSales_DimSalesRep FOREIGN KEY (SalesrepKey) REFERENCES DimSalesRep(SalesrepKey),
    CONSTRAINT FK_FactAmazonSales_DimVendors FOREIGN KEY (VendorKey) REFERENCES DimVendors(VendorKey),
    CONSTRAINT FK_FactAmazonSales_DimInvoices FOREIGN KEY (InvoiceKey)REFERENCES DimInvoices(InvoiceKey) 

);


--Indexes for FactAmazonSales table------------
CREATE INDEX IX_FactAmazonSales_UserKey	ON FactAmazonSales(UserKey);
CREATE INDEX IX_FactAmazonSales_DateKey 	ON FactAmazonSales(DateKey);
CREATE INDEX IX_FactAmazonSales_AddressKey 	ON FactAmazonSales(AddressKey);
CREATE INDEX IX_FactAmazonSales_ProductKey 	ON FactAmazonSales(ProductKey);
CREATE INDEX IX_FactAmazonSales_SalesrepKey ON FactAmazonSales(SalesrepKey);
CREATE INDEX IX_FactAmazonSales_VendorKey ON FactAmazonSales(VendorKey);
CREATE INDEX IX_FactAmazonSales_InvoiceKey ON FactAmazonSales(InvoiceKey);



----In DIMDATE LOAD Data from 2022 to 2024 as per sales data -------------------------------

CREATE OR REPLACE PROCEDURE DimDate_Load (StartDate IN DATE)
IS
    CurrentDate DATE := StartDate; -- Initialize with the starting date
    EndDate     DATE := ADD_MONTHS(StartDate, 12 * 3) - 1; -- Add 3 years to the start date
BEGIN
    WHILE CurrentDate <= EndDate LOOP
        INSERT INTO DimDate (
            DateKey, DateValue, CYear, CQtr, CMonth, DayNo,
            StartOfMonth, EndOfMonth, MonthName, DayOfWeekName
        )
        VALUES (
            EXTRACT(YEAR FROM CurrentDate) * 10000 
            + EXTRACT(MONTH FROM CurrentDate) * 100 
            + EXTRACT(DAY FROM CurrentDate), -- DateKey
            CurrentDate, -- DateValue
            EXTRACT(YEAR FROM CurrentDate), -- CYear
            TO_NUMBER(TO_CHAR(CurrentDate, 'Q')), -- CQtr
            EXTRACT(MONTH FROM CurrentDate), -- CMonth
            EXTRACT(DAY FROM CurrentDate), -- DayNo
            TRUNC(CurrentDate, 'MM'), -- StartOfMonth
            LAST_DAY(CurrentDate), -- EndOfMonth
            TO_CHAR(CurrentDate, 'MONTH'), -- MonthName
            TO_CHAR(CurrentDate, 'DAY') -- DayOfWeekName
        );

        -- Increment the date by 1 day
        CurrentDate := CurrentDate + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Date dimension loaded for 5 years starting from ' || TO_CHAR(StartDate, 'YYYY-MM-DD'));
END;
/

--Executed query to insert date data from 2022 to 2024 as per orderdate

SET SERVEROUTPUT ON;

BEGIN
   -- Call the procedure with the starting date as January 1, 2012
   DimDate_Load(TO_DATE('2022-01-01', 'YYYY-MM-DD'));
END;