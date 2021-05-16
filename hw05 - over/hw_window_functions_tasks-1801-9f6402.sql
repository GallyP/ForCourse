/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

--напишите здесь свое решение

WITH CTE
AS
(

		SELECT IL.InvoiceID
		, IL.ExtendedPrice
		, I.CustomerID
		,I.InvoiceDate
	
		FROM Sales.InvoiceLines AS IL
		JOIN Sales.Invoices AS I
		ON I.InvoiceID = IL.InvoiceID

		WHERE YEAR(I.InvoiceDate) >= 2015
),cte2
AS
		(SELECT IL2.InvoiceID
		, IL2.ExtendedPrice
		, I2.CustomerID
		,I2.InvoiceDate
	
		FROM Sales.InvoiceLines AS IL2
		JOIN Sales.Invoices AS I2
		ON I2.InvoiceID = IL2.InvoiceID
		WHERE YEAR(I2.InvoiceDate) >= 2015
	)

SELECT cte.InvoiceID
		, cte.ExtendedPrice
		, cte.CustomerID
		,cte.InvoiceDate
		,SUM(cte2.ExtendedPrice) AS total
FROM CTE
JOIN CTE2
	ON MONTH(CTE2.InvoiceDate) <= month(CTE.InvoiceDate)
	AND YEAR(CTE2.InvoiceDate) <= year(CTE.InvoiceDate)
GROUP BY cte.InvoiceID
, cte.ExtendedPrice
, cte.CustomerID
,cte.InvoiceDate
ORDER BY cte.InvoiceDate
/*У некоторых инвойсов проскакивает большая сумма, например у инвойса 39125 в дате 2015-01-01 (может это только у меня такой глюк?) */



/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

sELECT  IL.InvoiceID
--, SUM(IL.ExtendedPrice) OVER(PARTITION BY IL.InvoiceID) AS InvoicePrice
,IL.ExtendedPrice
, I.CustomerID
,I.InvoiceDate
,SUM(IL.ExtendedPrice) OVER (ORDER BY MONTH(I.InvoiceDate), YEAR(I.InvoiceDate) ) AS SumSumP
FROM Sales.InvoiceLines AS IL
JOIN Sales.Invoices AS I
ON I.InvoiceID = IL.InvoiceID
WHERE YEAR(I.InvoiceDate) >= 2015

ORDER BY I.InvoiceDate

/*В этом решении второй месяц посчитался неверно. 14 990 520.55 а должен быть 9 886 572.30, но итоговая сумма получилась верно 52052049.15 
* как и в предыдущем запросе*\
*/
SELECT  IL.InvoiceID
,IL.TransactionAmount
, I.CustomerID
,I.InvoiceDate
,SUM(IL.TransactionAmount) OVER (PARTITION BY YEAR(i.InvoiceDate)ORDER BY MONTH(I.InvoiceDate), YEAR(I.InvoiceDate) ) AS SumSumP
FROM Sales.CustomerTransactions AS IL
JOIN Sales.Invoices AS I
ON I.InvoiceID = IL.InvoiceID
WHERE YEAR(I.InvoiceDate) >= 2015

ORDER BY I.InvoiceDate

--Если года разделить, то и все будет считаться правильно, однако считаться заново начиная с каждого года, что не соответствует задаче.

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

--напишите здесь свое решение
WITH CTE
AS
(
	
		SELECT il.StockItemID
		,SUM(il.Quantity) OVER (PARTITION BY il.StockItemID,MONTH(I.InvoiceDate)) sumQ
		,MONTH(I.InvoiceDate) [MONTH]
		FROM Sales.InvoiceLines AS il
		JOIN Sales.Invoices AS i
		ON i.InvoiceID = il.InvoiceID

		WHERE YEAR(i.InvoiceDate) = '2016'
), R
AS(
		SELECT DISTINCT
		c.StockItemID
		,sumQ
		,c.[MONTH]
		,DENSE_RANK() OVER (PARTITION BY [month] order BY SumQ desc ) DRUNK
		FROM CTE AS c

)

SELECT 
 r.StockItemID
,r.sumQ
,r.[MONTH]
,r.DRUNK
FROM R AS r
WHERE R.Drunk <=2
ORDER BY [month], SUmQ DESC



/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задаче НЕ нужно писать аналог без аналитических функций.
*/

--напишите здесь свое решение
SELECT StockItemID
	  ,StockItemName
	  ,Brand
	  ,UnitPrice
	  ,DENSE_RANK() OVER ( PARTITION BY SUBSTRING(StockItemName,1,1) ORDER BY StockItemName ) DRUNK
	  ,COUNT(*) OVER () AS C
	  ,LEAD(StockItemID) OVER(ORDER BY StockItemName) Follow
	  ,lAG(StockItemID) OVER(ORDER BY StockItemName) Prev
	  ,LAG(StockItemName,2,'no_Items') OVER(ORDER BY StockItemName) Prev_2
	  --,TypicalWeightPerUnit
	  --,NTILE(30) OVER (ORDER BY TypicalWeightPerUnit)
FROM Warehouse.StockItems 
ORDER BY StockItemName, DRUNK


--Отдельная сортировка по весу 
SELECT StockItemID
	  ,StockItemName
	  ,TypicalWeightPerUnit
	  ,NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) NT
FROM Warehouse.StockItems 
ORDER BY NT 




/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

--напишите здесь свое решение
WITH CTE
AS
(
		SELECT i.SalespersonPersonID
		, i.CustomerID
		, I.InvoiceDate
		, CT.[TransactionAmount]
		, i.InvoiceID
		, i.OrderID
		, DENSE_RANK() OVER (PARTITION BY i.SalespersonPersonID ORDER BY i.InvoiceDate desc, i.InvoiceID desc) DRUNK
		FROM Sales.Invoices AS i
		JOIN [Sales].[CustomerTransactions] CT
			ON i.InvoiceID = CT.InvoiceID
)
SELECT  c.SalespersonPersonID
, p.FullName
, c.CustomerID
, [CustomerName]
, c.InvoiceDate
, c.[TransactionAmount]
FROM CTE AS c
JOIN APPLICATION.People AS p
	ON p.[PersonID] = c.SalespersonPersonID
JOIN Sales.Customers AS c2
	ON c.CustomerID = c2.CustomerID
WHERE DRUNK <=1
ORDER BY c.SalespersonPersonID

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

--напишите здесь свое решение
WITH CTE
AS
(
		SELECT   i.CustomerID
				,c3.CustomerName
				,il.StockItemID
				,il.UnitPrice
				,i.InvoiceDate
		,DENSE_RANK() OVER (PARTITION BY I.CustomerID ORDER BY il.UnitPrice desc) DRUNK
		FROM Sales.InvoiceLines AS il
		JOIN Sales.Invoices AS i
			ON i.InvoiceID = il.InvoiceID
		JOIN Sales.Customers AS c3
		ON c3.CustomerID = i.CustomerID

)

SELECT DISTINCT c.*
FROM CTE AS c
WHERE DRUNK <= 2
ORDER BY c.CustomerID, c.UnitPrice DESC


Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 