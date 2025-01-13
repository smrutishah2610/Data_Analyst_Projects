x------- CREATE Amazon DB USER --------
ALTER session set "_ORACLE_SCRIPT" = true;
CREATE USER amazondbuser identified by amazondbuser;
GRANT ALL PRIVILEGES TO amazondbuser;
SELECT * FROM all_users ORDER BY Created DESC;


----- CREATE Amazon DB TABLES ---------

CREATE TABLE Persons (
    PersonID NUMBER(10) NOT NULL,                      -- Primary Key
    FullName NVARCHAR2(50) NOT NULL,                  -- Full name of the person
    PreferredName NVARCHAR2(50) NOT NULL,             -- Preferred name of the person
    IsPermittedToLogon NUMBER(1) NOT NULL,            -- Indicates if the person can log in
    LogonName NVARCHAR2(50) NULL,                     -- Logon name (optional)
    IsExternalLogonProvider NUMBER(1) NOT NULL,       -- External logon provider flag
    IsSystemUser NUMBER(1) NOT NULL,                  -- Indicates if the person is a system user
    IsEmployee NUMBER(1) NOT NULL,                    -- Indicates if the person is an employee
    IsSalesPerson NUMBER(1) NOT NULL,                 -- Indicates if the person is a salesperson
    UserPreferences NVARCHAR2(400) NULL,             -- User preferences (optional)
    PhoneNumber NVARCHAR2(20) NULL,                  -- Phone number (optional)
    FaxNumber NVARCHAR2(20) NULL,                    -- Fax number (optional)
    EmailAddress NVARCHAR2(256) NULL,                -- Email address (optional)
    CONSTRAINT PK_Persons PRIMARY KEY (PersonID)      -- Primary Key Constraint
);


CREATE TABLE Countries(
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


CREATE TABLE Regions(
	RegionID NUMBER(10),
	RegionCode nvarchar2(5) NOT NULL,
	RegionName nvarchar2(50) NOT NULL,
	CountryID NUMBER(10) NOT NULL,
	SalesTerritory nvarchar2(50) NOT NULL,
	LatestRecordedPopulation NUMBER(12) NULL,
 	CONSTRAINT PK_Regions_ID PRIMARY KEY (RegionID),
	CONSTRAINT FK_Regions_CountryID_Countries FOREIGN KEY(CountryID) REFERENCES Countries (CountryID)
);


CREATE TABLE Cities(
	CityID NUMBER(10),
	CityName nvarchar2(50) NOT NULL,
	RegionID NUMBER(10) NOT NULL,
	LatestRecordedPopulation NUMBER(12) NULL,
 CONSTRAINT PK_Cities_ID PRIMARY KEY (CityID), 
 CONSTRAINT FK_Cities_RegionID_Regions FOREIGN KEY(RegionID) REFERENCES Regions(RegionID)
);

CREATE TABLE UserCategories(
	UserCategoryID NUMBER(10),
	UserCategoryName nvarchar2(50) NOT NULL,
    CONSTRAINT PK_UserCategories_ID PRIMARY KEY (UserCategoryID),
    CONSTRAINT UQ_UserCategories_UserCategoryName UNIQUE (UserCategoryName)
);


CREATE TABLE ShippingMethods(
	ShippingMethodID NUMBER(10),
	ShippingMethodName nvarchar2(50) NOT NULL,
    CONSTRAINT PK_ShippingMethods PRIMARY KEY (ShippingMethodID),
    CONSTRAINT UQ_ShippingMethods_ShippingMethodName UNIQUE (ShippingMethodName)
);

CREATE TABLE Users(
	UserID NUMBER(10) NOT NULL,
	UserName nvarchar2(100) NOT NULL,
	BillToUserID NUMBER(10) NOT NULL,
	UserCategoryID NUMBER(10) NOT NULL,
	PrimaryContactPersonID NUMBER(10) NOT NULL,
	ShippingMethodID NUMBER(10) NOT NULL,
	ShippingCityID NUMBER(10) NOT NULL,
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
 	CONSTRAINT PK_Sales_Users_ID PRIMARY KEY (UserID),
	CONSTRAINT FK_Users_PrimaryContactPersonID_Persons FOREIGN KEY(PrimaryContactPersonID) REFERENCES Persons (PersonID),
	CONSTRAINT FK_Users_UserCategoryID_UserCategories FOREIGN KEY(UserCategoryID) REFERENCES UserCategories (UserCategoryID),
	CONSTRAINT FK_Users_ShippingMethodID_ShippingMethods FOREIGN KEY(ShippingMethodID) REFERENCES ShippingMethods (ShippingMethodID)

);

CREATE TABLE Colors(
	ColorID NUMBER(10),
	ColorName nvarchar2(20) NOT NULL,
    CONSTRAINT PK_Colors_ID PRIMARY KEY (ColorID),
    CONSTRAINT UQ_Colors_ColorName UNIQUE (ColorName)
);


CREATE TABLE VendorCategories(
	VendorCategoryID NUMBER(10),
	VendorCategoryName nvarchar2(50) NOT NULL,
    CONSTRAINT PK_VendorCategories_ID PRIMARY KEY (VendorCategoryID),
    CONSTRAINT UQ_VendorCategories_VendorCategoryName UNIQUE (VendorCategoryName)
);

CREATE TABLE Vendors(
	VendorID NUMBER(10) NOT NULL,
	VendorName nvarchar2(100) NOT NULL,
	VendorCategoryID NUMBER(10) NOT NULL,
	PrimaryContactPersonID NUMBER(10) NOT NULL,
	ShippingCityID NUMBER(10) NOT NULL,
	PostalCityID NUMBER(10) NOT NULL,
	VendorReference nvarchar2(20) NULL,
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
	ShippingAddressLine1 nvarchar2(60) NOT NULL,
	ShippingAddressLine2 nvarchar2(60) NULL,
	ShippingPostalCode nvarchar2(10) NOT NULL,
	PostalAddressLine1 nvarchar2(60) NOT NULL,
	PostalAddressLine2 nvarchar2(60) NULL,
	PostalPostalCode nvarchar2(10) NOT NULL,
	CONSTRAINT PK_Vendors_ID PRIMARY KEY (VendorID),
	CONSTRAINT UQ_Vendor_VendorName UNIQUE (VendorName),
	CONSTRAINT FK_Vendor_PrimaryContactPersonID_Persons FOREIGN KEY(PrimaryContactPersonID) REFERENCES Persons (PersonID),
	CONSTRAINT FK_Vendor_ShippingCityID_Cities FOREIGN KEY(ShippingCityID) REFERENCES Cities (CityID),
	CONSTRAINT FK_Vendor_PostalCityID_Cities FOREIGN KEY(PostalCityID) REFERENCES Cities (CityID),
	CONSTRAINT FK_Vendor_VendorCategoryID_VendorCategories FOREIGN KEY(VendorCategoryID) REFERENCES VendorCategories (VendorCategoryID)
);


CREATE TABLE Items(
	ItemID NUMBER(10),
	ItemName nvarchar2(100) NOT NULL,
	VendorID NUMBER(10) NOT NULL,
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
	CONSTRAINT PK_Items PRIMARY KEY (ItemID),
	CONSTRAINT UQ_Items_ItemName UNIQUE (ItemName),
	CONSTRAINT FK_Items_ColorID_Colors FOREIGN KEY(ColorID) REFERENCES Colors (ColorID),
	CONSTRAINT FK_Items_VendorID_Vendors FOREIGN KEY(VendorID) REFERENCES Vendors (VendorID)
);

CREATE TABLE Orders(
	OrderID NUMBER(10),
	UserID NUMBER(10) NOT NULL,
	SalesrepPersonID NUMBER(10) NOT NULL,
	ContactPersonID NUMBER(10) NOT NULL,
	OrderDate date NOT NULL,
	ExpectedDeliveryDate date NOT NULL,
	CustomerPurchaseOrderNumber nvarchar2(20) NULL,
	IsUndersupplyBackordered NUMBER(1) NOT NULL,
	PickingCompletedWhen Date NULL,
	LastEditedBy NUMBER(10) NOT NULL,
	LastEditedWhen Date NOT NULL,
	CONSTRAINT PK_Orders_ID PRIMARY KEY (OrderID),
	CONSTRAINT FK_Orders_UsersID_Users FOREIGN KEY(UserID) REFERENCES Users (UserID),
	CONSTRAINT FK_Orders_SalesrepPersonID_Persons FOREIGN KEY(SalesrepPersonID) REFERENCES Persons (PersonID),
	CONSTRAINT FK_Orders_ContactPersonID_Persons FOREIGN KEY(ContactPersonID) REFERENCES Persons (PersonID),
	CONSTRAINT FK_Orders_Persons FOREIGN KEY(LastEditedBy) REFERENCES Persons (PersonID)
);


CREATE TABLE OrderLines(
	OrderLineID NUMBER(10) NOT NULL,
	OrderID NUMBER(10) NOT NULL,
	ItemID NUMBER(10) NOT NULL,
	Description nvarchar2(100) NOT NULL,
	Quantity NUMBER(4) NOT NULL,
	UnitPrice NUMBER(18, 2) NULL,
	TaxRate NUMBER(18, 3) NOT NULL,
	PickedQuantity NUMBER(4) NOT NULL,
	PickingCompletedWhen Date NULL,
	CONSTRAINT PK_OrderLines_ID PRIMARY KEY (OrderLineID),
	CONSTRAINT FK_OrderLines_Orders FOREIGN KEY(OrderID) REFERENCES Orders (OrderID),
	CONSTRAINT FK_OrderLines_ItemID_Items FOREIGN KEY(ItemID) REFERENCES Items (ItemID)
);