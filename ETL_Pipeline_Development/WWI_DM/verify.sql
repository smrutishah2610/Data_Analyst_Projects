SELECT CustomerName, COUNT(*) 
FROM Customers_Preload
GROUP BY CustomerName
HAVING COUNT(*) > 1;

SELECT ProductName, COUNT(*) 
FROM PRODUCTS_PRELOAD
GROUP BY ProductName
HAVING COUNT(*) > 1;

SELECT LogonName, COUNT(*) 
FROM SalesPeople_Preload
GROUP BY LogonName
HAVING COUNT(*) > 1;

SELECT FullName, COUNT(*) 
FROM Supplier_Preload
GROUP BY FullName
HAVING COUNT(*) > 1;

SELECT CustomerKey, CityKey, ProductKey, SalespersonKey, SupplierKey, DateKey, COUNT(*)
FROM Orders_Preload
GROUP BY CustomerKey, CityKey, ProductKey, SalespersonKey, SupplierKey, DateKey
HAVING COUNT(*) > 1;

SELECT *
FROM Orders_Preload
WHERE SupplierKey IS NULL;

