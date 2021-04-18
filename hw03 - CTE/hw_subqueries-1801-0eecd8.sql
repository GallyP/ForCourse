/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--TODO: напишите здесь свое решение
SELECT PersonID,FullName
FROM Application.People 
Where IsSalesperson = 1
AND   PersonID not in (select [SalespersonPersonID] 
				   from Sales.Invoices
				   Where [InvoiceDate] = '2015-06-05')
--Если вывести оба запроса отдельно, то можно убедиться, 
--что в этот день все сотрудники совершили продажу. 



/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

--TODO: напишите здесь свое решение

--В этом варианте я не уверена, что используется подзапрос и работало ли это бы, если указать другую таблицу
-- Без топ 1 выводит все варианты, иначе вывести не получилось


--Подзапрос в WHERE
SELECT [StockItemID]
	  ,[StockItemName]
	  ,[UnitPrice]
FROM Warehouse.StockItems
WHERE UnitPrice = (Select MIN(UnitPrice) FROM Warehouse.StockItems)

--Преобразование подзапроса в WHERE 
SELECT [StockItemID]
	  ,[StockItemName]
	  ,[UnitPrice]
FROM Warehouse.StockItems
WHERE UnitPrice <= ALL (Select UnitPrice FROM Warehouse.StockItems)

--Подзапрос во FROM
SELECT [StockItemID]
	  ,[StockItemName]
	  ,S.[UnitPrice]
	  ,S1.minPrice
FROM Warehouse.StockItems S 
JOIN (Select UnitPrice, MIN(UnitPrice)OVER () as minPrice FROM Warehouse.StockItems
	  GROUP BY UnitPrice) S1
ON S.UnitPrice = S1.UnitPrice
WHERE S.UnitPrice = S1.minPrice







/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--TODO: напишите здесь свое решение

--Подзапросы в подзапросе подзапросом погоняют


SELECT * 
FROM Sales.Customers SC

JOIN (Select Distinct M.CustomerID
		FROM Sales.Customers C
		JOIN (  SELECT   [CustomerID]
				,TransactionAmount
				,ROW_NUMBER () OVER (ORDER BY TransactionAmount desc ) AS RowNumber
				FROM Sales.CustomerTransactions
				GROUP BY CustomerID,TransactionAmount) M
		
		ON C.CustomerID = M.CustomerID
		WHERE M.RowNumber <=5
		Group by M.[CustomerID]) C
		ON  SC.CustomerID = C.CustomerID

go

--CTE
WITH MaxTrans 
AS
(
		Select [CustomerID]
				,TransactionAmount
				,ROW_NUMBER () OVER (ORDER BY TransactionAmount desc ) AS RowNumber
		FROM Sales.CustomerTransactions
		GROUP BY CustomerID,TransactionAmount
)
, Customers --Выведен только для того, чтобы вывести чистые данные без повторений
AS
(
		Select Distinct M.CustomerID
		FROM Sales.Customers C
		JOIN MaxTrans M
		ON C.CustomerID = M.CustomerID
		WHERE RowNumber <=5
		Group by M.[CustomerID]
)

SELECT * 
FROM Sales.Customers SC
JOIN Customers C
ON  SC.CustomerID = C.CustomerID





/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, 
а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).
*/

--TODO: напишите здесь свое решение

DROP VIEW IF EXISTS StockItemsView;
Go 
CREATE VIEW StockItemsView 
AS 

SELECT 
		 [StockItemID]
		,[UnitPrice]
		,ROW_NUMBER () OVER (ORDER BY [UnitPrice] desc ) AS RowNumber
FROM [Warehouse].[StockItems] 
GO


SELECT DISTINCT 
	   P.FullName
	   ,DeliveryCityID
	   ,Ci.CityName
FROM [Sales].[InvoiceLines] IL
	JOIN StockItemsView S
	ON S.[StockItemID] = IL.[StockItemID]
	JOIN Sales.Invoices I
	ON I.InvoiceID = IL.InvoiceID
	JOIN Sales.Customers C
	ON C.CustomerID = I.CustomerID
	JOIN Application.Cities Ci
	ON C.DeliveryCityID = Ci.CityID
	JOIN Application.People p
	ON P.PersonID = I.PackedByPersonID
WHERE  S.RowNumber<=3
Order by CityName

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,

	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,

	SalesTotals.TotalSumm AS TotalSummByInvoice, 

	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = 
								   (SELECT Orders.OrderId 
									FROM Sales.Orders
									WHERE Orders.PickingCompletedWhen IS NOT NULL	
									AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems

FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

--TODO: напишите здесь свое решение

WITH SalesPersonName 
AS
(
		SELECT P.FullName
			  ,I.OrderID
			  ,I.InvoiceID
			  ,I.InvoiceDate
				FROM Application.People P
				JOIN Sales.Invoices I
				ON P.PersonID = I.SalespersonPersonID
),

TotalSummForPickedItemsCTE
AS
(		
		SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalSummForPickedItems
		,Invoices.InvoiceID
		FROM Sales.OrderLines
		JOIN Sales.Orders
		ON OrderLines.OrderId = Orders.OrderId 	
		JOIN Sales.Invoices
		ON  Orders.OrderId = Invoices.OrderId
		WHERE Orders.PickingCompletedWhen IS NOT NULL
		GROUP BY Invoices.InvoiceID
),
SalesTotals
AS
(
		SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
		FROM Sales.InvoiceLines
		GROUP BY InvoiceId
		HAVING SUM(Quantity*UnitPrice) > 27000
)
SELECT 
	SP.InvoiceID, 
	SP.InvoiceDate,
	SP.FullName,
	TS.TotalSummForPickedItems,
	TotalSumm
FROM SalesPersonName SP
JOIN TotalSummForPickedItemsCTE TS
ON  SP.InvoiceID = TS.InvoiceID
JOIN SalesTotals T
ON SP.InvoiceID = T.InvoiceID
ORDER BY T.TotalSumm DESC

















