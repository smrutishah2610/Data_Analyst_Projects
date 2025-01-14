
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

CREATE TABLE FactOrders (
    -- Should we create a surrogate key?
    CustomerKey      	NUMBER(10) NOT NULL,
    LocationKey      	NUMBER(10) NOT NULL,
    ProductKey       	NUMBER(10) NOT NULL,
    SalespersonKey   	NUMBER(10) NOT NULL,
    DateKey 	      	NUMBER(8) NOT NULL,
    Quantity 	      	NUMBER(4) NOT NULL,
    UnitPrice        	NUMBER(18,2) NOT NULL,
    TaxRate 	      	NUMBER(18,3) NOT NULL,
    TotalBeforeTax   	NUMBER(18,2) NOT NULL,
    TotalAfterTax    	NUMBER(18,2) NOT NULL,
    CONSTRAINT FK_FactOrders_DimCustomers FOREIGN KEY (CustomerKey) REFERENCES DimCustomers(CustomerKey)
);

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
    LogonName       NVARCHAR2(50),
    SupplierName nvarchar2(100)
);

CREATE OR REPLACE PROCEDURE Orders_Extract
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE wwidmuser.Orders_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO wwidmuser.Orders_Stage (
        OrderDate,
        Quantity,
        UnitPrice,
        TaxRate,
        CustomerName,
        CityName,
        StateProvinceName,
        CountryName,
        StockItemName,
        LogonName,
        SupplierName
    )
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
    SELECT o.OrderDate,
           ol.Quantity,
           ol.UnitPrice,
           ol.TaxRate,
           c.CustomerName,
           dc.CityName,
           dc.StateProvinceName,
           dc.CountryName,
           stk.StockItemName,
           p.LogonName,
           s.SupplierName
    FROM wwidbuser.Orders o
        LEFT JOIN wwidbuser.OrderLines ol
            ON o.OrderID = ol.OrderID
        LEFT JOIN wwidbuser.Customers c
            ON o.CustomerID = c.CustomerID
        LEFT JOIN CityDetails dc
            ON c.DeliveryCityID = dc.CityID
        LEFT JOIN wwidbuser.StockItems stk
            ON ol.StockItemID = stk.StockItemID
        LEFT JOIN wwidbuser.People p
            ON o.SalespersonPersonID = p.PersonID AND IsSalesPerson = 1
        LEFT JOIN wwidbuser.Suppliers s
            ON stk.SupplierID = s.SupplierID;
    
    RowCt := SQL%ROWCOUNT;
    IF RowCt = 0 THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSE
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

Set serverout on;
EXECUTE Orders_Extract;
SELECT COUNT(*) FROM orders_stage;

CREATE TABLE Orders_Preload (
    CustomerKey NUMBER(10) NOT NULL,
    CityKey NUMBER(10) NOT NULL,
    ProductKey NUMBER(10) NOT NULL,
    SalespersonKey NUMBER(10) NOT NULL,
    SupplierKey NUMBER(10) NOT NULL,
    DateKey NUMBER(8) NOT NULL,
    Quantity NUMBER(3) NOT NULL,
    UnitPrice NUMBER(18, 2) NOT NULL,
    TaxRate NUMBER(18, 3) NOT NULL,
    TotalBeforeTax NUMBER(18, 2) NOT NULL,
    TotalAfterTax NUMBER(18, 2) NOT NULL
);

CREATE OR REPLACE PROCEDURE Orders_Transform
AS
    RowCt NUMBER(10);
    v_sql VARCHAR(255) := 'TRUNCATE TABLE Orders_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    INSERT INTO Orders_Preload /* Columns excluded for brevity */
    SELECT cu.CustomerKey,
        ci.LocationKey,
        pr.ProductKey,
        sp.SalespersonKey,
        su.SupplierKey,
        EXTRACT(YEAR FROM ord.OrderDate)*10000 + EXTRACT(Month FROM ord.OrderDate)*100 + EXTRACT(Day FROM ord.OrderDate),
        SUM(ord.Quantity) AS Quantity,
        AVG(ord.UnitPrice) AS UnitPrice,
        AVG(ord.TaxRate) AS TaxRate,
        SUM(ord.Quantity * ord.UnitPrice) AS TotalBeforeTax,
        SUM(ord.Quantity * ord.UnitPrice * (1 + ord.TaxRate/100)) AS TotalAfterTax
    FROM Orders_Stage ord
    JOIN Customers_Preload cu
        ON ord.CustomerName = cu.CustomerName
    JOIN Locations_Preload ci
        ON ord.CityName = ci.CityName AND ord.StateProvinceName = ci.StateProvName
        AND ord.CountryName = ci.CountryName
    JOIN Products_Preload pr
        ON ord.StockItemName = pr.ProductName
    JOIN SalesPeople_Preload sp
        ON ord.LogonName = sp.LogonName
    JOIN Supplier_Preload su
        ON ord.SupplierName = su.FullName
    GROUP BY cu.CustomerKey, ci.LocationKey, pr.ProductKey, sp.SalespersonKey, su.SupplierKey, ord.OrderDate;

    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) || ' Rows have been processed!');
END;
/

-- Execute the Orders_Transform procedure
TRUNCATE TABLE Orders_Preload;
SET SERVEROUT ON;
EXECUTE Orders_Transform;
Select COUNT(*) from Orders_Preload;

CREATE OR REPLACE PROCEDURE Orders_Load
AS
BEGIN
    INSERT INTO FactOrders (
        CustomerKey,
        LocationKey,
        ProductKey,
        SalespersonKey,
        DateKey,
        Quantity,
        UnitPrice,
        TaxRate,
        TotalBeforeTax,
        TotalAfterTax,
        SupplierKey
    )
    SELECT CustomerKey,
           CityKey,
           ProductKey,
           SalespersonKey,
           DateKey,
           Quantity,
           ROUND(UnitPrice, 2),        -- Round to fit the defined precision
           ROUND(TaxRate, 3),          -- Round to fit the defined precision
           ROUND(TotalBeforeTax, 2),   -- Round to fit the defined precision
           ROUND(TotalAfterTax, 2),     -- Round to fit the defined precision
           SupplierKey
    FROM Orders_Preload;

    COMMIT;
END;
/

SET SERVEROUT ON;
EXECUTE ORDERS_LOAD;
SELECT COUNT(*) FROM FACTORDERS;
