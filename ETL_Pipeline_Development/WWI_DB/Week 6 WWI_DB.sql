------- CREATE A NEW USER for WWI DB -----------------------------------
ALTER session set "_ORACLE_SCRIPT" = true;

CREATE USER wwidbuser identified by wwidbuser;

GRANT ALL PRIVILEGES TO wwidbuser;

SELECT * FROM all_users ORDER BY Created DESC;

DROP Table People;
----- CREATE WWI TABLES ---------

CREATE TABLE wwidbuser.Countries(
	CountryID NUMBER (10) NOT NULL,
	CountryName NVARCHAR2(60) NOT NULL,
	FormalName NVARCHAR2(60) NOT NULL,
	IsoAlpha3Code NVARCHAR2(3) NULL,
	IsoNumericCode NUMBER (10) NULL,
	CountryType NVARCHAR2(20) NULL,
	LatestRecordedPopulation NUMBER(12) NULL,
	Continent NVARCHAR2(30) NOT NULL,
	Region NVARCHAR2(30) NOT NULL,
	Subregion NVARCHAR2(30) NOT NULL,
    CONSTRAINT PK_Countries_ID PRIMARY KEY (CountryID), 
    CONSTRAINT UQ_Countries_CountryName UNIQUE(CountryName)
);
--SELECT * FROM Countries;


CREATE TABLE wwidbuser.StateProvinces(
	StateProvinceID NUMBER(10),
	StateProvinceCode nvarchar2(5) NOT NULL,
	StateProvinceName nvarchar2(50) NOT NULL,
	CountryID NUMBER(10) NOT NULL,
	SalesTerritory nvarchar2(50) NOT NULL,
	LatestRecordedPopulation NUMBER(12) NULL,
 	CONSTRAINT PK_StateProvinces_ID PRIMARY KEY (StateProvinceID),
	CONSTRAINT FK_StateProvinces_CountryID_Countries FOREIGN KEY(CountryID) REFERENCES wwidbuser.Countries (CountryID)
);


CREATE TABLE wwidbuser.Cities(
	CityID NUMBER(10),
	CityName nvarchar2(50) NOT NULL,
	StateProvinceID NUMBER(10) NOT NULL,
	LatestRecordedPopulation NUMBER(12) NULL,
 CONSTRAINT PK_Cities_ID PRIMARY KEY (CityID), 
 CONSTRAINT FK_Cities_StateProvinceID_StateProvinces FOREIGN KEY(StateProvinceID) REFERENCES wwidbuser.StateProvinces (StateProvinceID)
);
--SELECT * FROM Cities;

CREATE TABLE wwidbuser.CustomerCategories(
	CustomerCategoryID NUMBER(10),
	CustomerCategoryName nvarchar2(50) NOT NULL,
    CONSTRAINT PK_CustomerCategories_ID PRIMARY KEY (CustomerCategoryID),
    CONSTRAINT UQ_CustomerCategories_CustomerCategoryName UNIQUE (CustomerCategoryName)
);
--SELECT * FROM CustomerCategories;


CREATE TABLE wwidbuser.DeliveryMethods(
	DeliveryMethodID NUMBER(10),
	DeliveryMethodName nvarchar2(50) NOT NULL,
    CONSTRAINT PK_DeliveryMethods PRIMARY KEY (DeliveryMethodID),
    CONSTRAINT UQ_DeliveryMethods_DeliveryMethodName UNIQUE (DeliveryMethodName)
);
--SELECT * FROM DeliveryMethods;

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
--SELECT * FROM customers;

CREATE TABLE wwidbuser.Colors(
	ColorID NUMBER(10),
	ColorName nvarchar2(20) NOT NULL,
    CONSTRAINT PK_Colors_ID PRIMARY KEY (ColorID),
    CONSTRAINT UQ_Colors_ColorName UNIQUE (ColorName)
);
--TRUNCATE TABLE Colors;
--SELECT * FROM Colors;

CREATE TABLE wwidbuser.SupplierCategories(
	SupplierCategoryID NUMBER(10),
	SupplierCategoryName nvarchar2(50) NOT NULL,
    CONSTRAINT PK_SupplierCategories_ID PRIMARY KEY (SupplierCategoryID),
    CONSTRAINT UQ_SupplierCategories_SupplierCategoryName UNIQUE (SupplierCategoryName)
);
--SELECT * FROM SupplierCategories;

--DROP TABLE Suppliers;
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
--SELECT * FROM suppliers;


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

CREATE TABLE wwidbuser.Orders(
	OrderID NUMBER(10),
	CustomerID NUMBER(10) NOT NULL,
	SalespersonPersonID NUMBER(10) NOT NULL,
	ContactPersonID NUMBER(10) NOT NULL,
	OrderDate date NOT NULL,
	ExpectedDeliveryDate date NOT NULL,
	CustomerPurchaseOrderNumber nvarchar2(20) NULL,
	IsUndersupplyBackordered NUMBER(1) NOT NULL,
	PickingCompletedWhen Date NULL,
	LastEditedBy NUMBER(10) NOT NULL,
	LastEditedWhen Date NOT NULL,
	CONSTRAINT PK_Orders_ID PRIMARY KEY (OrderID),
	CONSTRAINT FK_Orders_CustomerID_Customers FOREIGN KEY(CustomerID) REFERENCES wwidbuser.Customers (CustomerID),
	CONSTRAINT FK_Orders_SalespersonPersonID_People FOREIGN KEY(SalespersonPersonID) REFERENCES wwidbuser.People (PersonID),
	CONSTRAINT FK_Orders_ContactPersonID_People FOREIGN KEY(ContactPersonID) REFERENCES wwidbuser.People (PersonID),
	CONSTRAINT FK_Orders_People FOREIGN KEY(LastEditedBy) REFERENCES wwidbuser.People (PersonID)
);
--SELECT * FROM orders WHERE orderdate = '2013-01-01';


--DROP TABLE OrderLines;
CREATE TABLE OrderLines(
	OrderLineID NUMBER(10) NOT NULL,
	OrderID NUMBER(10) NOT NULL,
	StockItemID NUMBER(10) NOT NULL,
	Description nvarchar2(100) NOT NULL,
	Quantity NUMBER(4) NOT NULL,
	UnitPrice NUMBER(18, 2) NULL,
	TaxRate NUMBER(18, 3) NOT NULL,
	PickedQuantity NUMBER(4) NOT NULL,
	PickingCompletedWhen Date NULL,
	CONSTRAINT PK_OrderLines_ID PRIMARY KEY (OrderLineID),
	CONSTRAINT FK_OrderLines_Orders FOREIGN KEY(OrderID) REFERENCES wwidbuser.Orders (OrderID),
	CONSTRAINT FK_OrderLines_StockItemID_StockItems FOREIGN KEY(StockItemID) REFERENCES wwidbuser.StockItems (StockItemID)
);
-- TRUNCATE TABLE OrderLines;
SELECT COUNT(*) FROM wwidbuser.Suppliers;


