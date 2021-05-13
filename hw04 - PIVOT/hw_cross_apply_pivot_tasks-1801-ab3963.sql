/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение. Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/


--напишите здесь свое решение

SELECT *
FROM (
	SELECT 
			 CA.InvoiceMonth
			,SUBSTRING(C.CustomerName,15, 100) AS [CusName]
			,i.InvoiceID
	FROM Sales.Invoices AS i
		JOIN Sales.Customers AS c
			ON c.CustomerID = i.CustomerID
	CROSS APPLY (SELECT CONVERT(NVARCHAR(16),CAST(DATEADD(mm,DATEDIFF(mm,0,i.InvoiceDate),0) AS DATE), 104) AS InvoiceMonth) AS CA
      WHERE  I.CustomerID IN (2,3,4,5,6) 

      GROUP BY CA.InvoiceMonth,SUBSTRING(C.CustomerName,15, 100), i.InvoiceID
) AS b
PIVOT 
(
	   COUNT(InvoiceID)
       FOR CusName IN ([(Sylvanite, MT)],[(Peeples Valley, AZ)],[(Medicine Lodge, KS)],[(Gasport, NY)],[(Jessie, ND)])
) AS pvt

ORDER BY month(InvoiceMonth), year(InvoiceMonth)


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

--напишите здесь свое решение

SELECT *
FROM
(
	SELECT CustomerName
	, DeliveryAddressLine1
	, DeliveryAddressLine2
	, PostalAddressLine1
	, PostalAddressLine2
	FROM Sales.Customers
	Where CustomerName like '%Tailspin Toys%'
) as R
UNPIVOT (Adress FOR Line IN (DeliveryAddressLine1
							, DeliveryAddressLine2
							, PostalAddressLine1
							, PostalAddressLine2) 
		) as unpvt


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

--напишите здесь свое решение

SELECT *
FROM
(
SELECT CountryId,[CountryName], [IsoAlpha3Code], cast([IsoNumericCode]as nvarchar(3)) as IsoNumeric
FROM [Application].[Countries]
) AS q
UNPIVOT (Code FOR Line IN ([IsoAlpha3Code], IsoNumeric)
		) as unpvt


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть 
ид клиета,
его название, 
ид товара, 
цена, 
дата покупки.
*/


------------------------------------------------
 WITH Cte 
AS (
	SELECT DISTINCT 
	il.UnitPrice
	,i.CustomerID
	FROM Sales.InvoiceLines il
	JOIN Sales.Invoices i
	ON i.InvoiceID = il.InvoiceID
), cte1
as
(
SELECT DISTINCT c.CustomerID, o.*
FROM CTE c
CROSS APPLY 
(SELECT TOP 2 c1.UnitPrice  FROM cte c1
 WHERE c1.CustomerID = c.CustomerID
 ORDER BY UnitPrice DESC) O
)

SELECT  c2.CustomerName, c.*, i.InvoiceDate, si.StockItemID
FROM Cte1 c
JOIN Sales.Customers c2
ON c2.CustomerID = c.CustomerID
JOIN Sales.Invoices i
ON i.CustomerID = c.CustomerID
JOIN Warehouse.StockItems AS si
ON c.UnitPrice = si.UnitPrice

ORDER BY c.CustomerID, c.UnitPrice, i.InvoiceDate





