/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [Sales].MaxCustomersPurchase ()

RETURNS TABLE 
AS
RETURN 

(
		WITH a
		AS
		(
			SELECT CustomerID, MAX(TransactionAmount) OVER() MAXamount
			FROM [Sales].[CustomerTransactions]
			group by TransactionAmount, CustomerID
		)

		Select C.CustomerID, C.TransactionAmount, A.MAXamount
		FROM [Sales].[CustomerTransactions] C
			JOIN a ON C.CustomerID = A.CustomerID
		WHERE TransactionAmount =  MAXamount
		GROUP BY C.CustomerID, TransactionAmount, MAXamount
);

GO

SELECT * FROM [Sales].MaxCustomersPurchase ()

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/


USE WideWorldImporters
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE Sales.SumPurchase

@CustomerID INT

AS
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT SUM(A.sumP) OVER (PARTITION BY C.customerID) overSum

	FROM Sales.Customers C
		JOIN Sales.Invoices i ON C.CustomerID = I.CustomerID
		JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
	CROSS APPLY (SELECT SUM(IL.ExtendedPrice) OVER (PARTITION BY IL.InvoiceID) as sumP) A
	WHERE C.CustomerID = @CustomerID
	
END


EXEC Sales.SumPurchase 20


/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
--Функция\процедура показывает самые любимые товары для вызываемого кастомера

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [Sales].FavouriteItemCustomers (@CustomerID INT)

RETURNS TABLE 
AS
RETURN 
(
		  WITH CTE
		as
		(
			SELECT DISTINCT
				il.[StockItemID]
			  , il.[Description]
			  ,i.CustomerID
			,SUM(il.Quantity) OVER (PARTITION BY i.CustomerID, il.StockItemID) as SumQ
			FROM [WideWorldImporters].[Sales].[InvoiceLines] IL
			JOIN Sales.Invoices i ON IL.InvoiceID = i.InvoiceID
			WHERE i.CustomerID = @CustomerID
		)

		SELECT 
				CTE.[StockItemID]
			  , CTE.[Description]
			  , CTE.CustomerID
			  , cte.SumQ
			  , ROW_NUMBER() OVER ( PARTITION BY CTE.CustomerID order by cte.SumQ desc) RowN
	  
		  FROM cte
		  

);
GO




  --------------------------------------

  USE WideWorldImporters
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [Sales].FavouriteItemCustomersProc

@CustomerID INT

AS
BEGIN

	SET NOCOUNT ON;

		WITH CTE
			as
			(
				SELECT DISTINCT
					il.[StockItemID]
					, il.[Description]
					,i.CustomerID
				,SUM(il.Quantity) OVER (PARTITION BY i.CustomerID, il.StockItemID) as SumQ
				FROM [WideWorldImporters].[Sales].[InvoiceLines] IL
				JOIN Sales.Invoices i ON IL.InvoiceID = i.InvoiceID
				WHERE i.CustomerID = @CustomerID
			)

			SELECT 
					CTE.[StockItemID]
					, CTE.[Description]
					, CTE.CustomerID
					, cte.SumQ
					, ROW_NUMBER() OVER ( PARTITION BY CTE.CustomerID order by cte.SumQ desc) RowN
	  
				FROM cte
				

END
GO

Select * From [Sales].FavouriteItemCustomers (10)
EXEC [Sales].FavouriteItemCustomersProc 10

/*Процедура менее производительна, так как функция сначала использует кластерный индекс, а потом присоединяет некластерный и затрагивает всего 115 строк. 
В дальнейшем у функции сразу используется фильтр и дальнейшие операторы работают с меньшим количеством строк, чем процедура.

Процедура запускает поиск по индексам одновременно и через некластерный индекс проходит большой поток данных (около 70к строк). Сам план запроса у процедуры длиннее
и фильтр находится примерно по середины после Hash Match и Compute Scalar. То есть программа использует все строки для вычисления и после этого уже фильтрует. 

!!! Когда я перенесла "where" в CTE - у меня выровнились оба плана, так что разницы теперь между ними нет
*/

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

--Функция подобна предыдущей, но заодно высчитывает прибыль которую принес вызываемый CustomerID за каждую позицию

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [Sales].FavouriteItemCustomers (@CustomerID INT)

RETURNS TABLE 
AS
RETURN 
(
	WITH CTE
		as
		(
			SELECT DISTINCT
				il.[StockItemID]
			  , il.[Description]
			  ,i.CustomerID
			  ,il.[TaxRate]
			  ,il.[UnitPrice]
			,SUM(il.Quantity) OVER (PARTITION BY i.CustomerID, il.StockItemID) as SumQ
			FROM [WideWorldImporters].[Sales].[InvoiceLines] IL
			JOIN Sales.Invoices i ON IL.InvoiceID = i.InvoiceID
			where @CustomerID = i.CustomerID
		)

		SELECT 
				CTE.[StockItemID]
			  , CTE.[Description]
			  , CTE.CustomerID
			  , cte.SumQ
			  , ROW_NUMBER() OVER ( PARTITION BY CTE.CustomerID order by cte.SumQ desc) RowN
			  ,A.Profit
			  ,B.PaidSum
			  ,cte.UnitPrice
	  
		  FROM cte
		  CROSS APPLY (select PaidSum = cte.[UnitPrice] / 100 * (cte.TaxRate + 100) * cte.SumQ) B
		  CROSS APPLY (select Profit = B.PaidSum/100*cte.taxrate) A

);
GO
/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
--Так как все процедуры и функции по большей части вызывают таблицы или значения, ничего не изменяя, то по-умолчанию Read Commited, 
-- функция которого -  считывать все данные, с зафиксированными изменениями, вполне хватит для проведения 