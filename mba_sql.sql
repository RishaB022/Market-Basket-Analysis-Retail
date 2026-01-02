CREATE DATABASE retail_mba;
USE retail_mba;

CREATE TABLE transactions (
    Invoice VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    Price DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(50),
    TotalAmount DECIMAL(10,2)
);

show tables;

select count(*) as total_rows
from transactions;

SELECT COUNT(DISTINCT Invoice) AS total_invoices
FROM transactions;

SELECT COUNT(DISTINCT StockCode) AS total_products
FROM transactions;

CREATE OR REPLACE VIEW invoice_baskets AS
SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    Price,
    Country
FROM transactions
WHERE Quantity > 0;

##BASKET SIZE ANALYSIS (BUSINESS INSIGHT)
#Items per invoice
SELECT
    Invoice,
    COUNT(DISTINCT StockCode) AS items_in_basket
FROM invoice_baskets
GROUP BY Invoice;

#Average basket size
SELECT
    AVG(items_in_basket) AS avg_items_per_invoice
FROM (
    SELECT
        Invoice,
        COUNT(DISTINCT StockCode) AS items_in_basket
    FROM invoice_baskets
    GROUP BY Invoice
) t;

##MOST FREQUENT PRODUCTS
#Top products by invoice presence
SELECT
    StockCode,
    Description,
    COUNT(DISTINCT Invoice) AS invoice_count
FROM invoice_baskets
GROUP BY StockCode, Description
ORDER BY invoice_count DESC
LIMIT 10;

#COUNTRY-WISE BASKET BEHAVIOR
#Orders by country
SELECT
    Country,
    COUNT(DISTINCT Invoice) AS total_invoices
FROM invoice_baskets
GROUP BY Country
ORDER BY total_invoices DESC;

#Avg basket size by country
SELECT
    Country,
    AVG(items_in_basket) AS avg_basket_size
FROM (
    SELECT
        Invoice,
        Country,
        COUNT(DISTINCT StockCode) AS items_in_basket
    FROM invoice_baskets
    GROUP BY Invoice, Country
) t
GROUP BY Country
ORDER BY avg_basket_size DESC;

##CREATE MBA-READY EXPORT VIEW (FOR PYTHON)
CREATE OR REPLACE VIEW mba_input AS
SELECT
    Invoice,
    StockCode
FROM invoice_baskets;
##Basket summary table
CREATE OR REPLACE VIEW pb_basket_summary AS
SELECT
    Invoice,
    COUNT(DISTINCT StockCode) AS basket_size,
    SUM(Quantity * Price) AS basket_value
FROM transactions
WHERE Quantity > 0
GROUP BY Invoice;

##Product frequency table
CREATE OR REPLACE VIEW pb_product_frequency AS
SELECT
    StockCode,
    Description,
    COUNT(DISTINCT Invoice) AS invoice_count
FROM transactions
WHERE Quantity > 0
GROUP BY StockCode, Description;

##Country-level basket behavior
CREATE OR REPLACE VIEW pb_country_basket AS
SELECT
    Country,
    COUNT(DISTINCT Invoice) AS total_invoices,
    AVG(basket_size) AS avg_basket_size
FROM (
    SELECT
        Invoice,
        Country,
        COUNT(DISTINCT StockCode) AS basket_size
    FROM transactions
    WHERE Quantity > 0
    GROUP BY Invoice, Country
) t
GROUP BY Country;

##Top product pairs
CREATE OR REPLACE VIEW pb_top_pairs AS
SELECT
    a.StockCode AS product_1,
    b.StockCode AS product_2,
    COUNT(DISTINCT a.Invoice) AS co_purchase_count
FROM invoice_baskets a
JOIN invoice_baskets b
  ON a.Invoice = b.Invoice
 AND a.StockCode < b.StockCode
GROUP BY product_1, product_2
HAVING co_purchase_count >= 300;

CREATE OR REPLACE VIEW fact_transactions AS
SELECT
    Invoice,
    StockCode,
    CustomerID,
    Country,
    Quantity,
    Price,
    Quantity * Price AS total_amount,
    InvoiceDate
FROM transactions
WHERE Quantity > 0;

#PRODUCT DIMENSION
CREATE OR REPLACE VIEW dim_product AS
SELECT DISTINCT
    StockCode,
    Description
FROM transactions;

#INVOICE DIMENSION
CREATE OR REPLACE VIEW dim_invoice AS
SELECT DISTINCT
    Invoice,
    InvoiceDate
FROM transactions;

#COUNTRY DIMENSION
CREATE OR REPLACE VIEW dim_country AS
SELECT DISTINCT
    Country
FROM transactions;

CREATE OR REPLACE VIEW fact_top_pairs_country AS
SELECT
    a.Country,
    a.StockCode AS product_1,
    b.StockCode AS product_2,
    COUNT(DISTINCT a.Invoice) AS co_purchase_count
FROM fact_transactions a
JOIN fact_transactions b
    ON a.Invoice = b.Invoice
   AND a.StockCode < b.StockCode
GROUP BY
    a.Country,
    product_1,
    product_2
HAVING COUNT(DISTINCT a.Invoice) >= 100;











