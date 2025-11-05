CREATE DATABASE TelcoDatabase;
GO

CREATE TABLE dbo.TelcoCustomers (
CustomerID NVARCHAR(50),
Gender NVARCHAR(10),
SeniorCitizen BIT,              
Partner NVARCHAR(5),     
Dependents NVARCHAR(5),     
Tenure INT,              
PhoneService NVARCHAR(5),      
MultipleLines NVARCHAR(30),
InternetService NVARCHAR(30),
OnlineSecurity NVARCHAR(30),
OnlineBackup NVARCHAR(30),
DeviceProtection  NVARCHAR(30),
TechSupport NVARCHAR(30),
StreamingTV NVARCHAR(30),
StreamingMovies NVARCHAR(30),
Contract NVARCHAR(30),
PaperlessBilling  NVARCHAR(5),
PaymentMethod NVARCHAR(50),
MonthlyCharges DECIMAL(10,2),
TotalCharges DECIMAL(10,2),
Churn NVARCHAR(5))

BULK INSERT dbo.TelcoCustomers
FROM '/var/opt/mssql/data/telco_churn.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',',ROWTERMINATOR = '0x0a')

SELECT * FROM TelcoCustomers

-- Boş totalcharges satırlarını NULL yapıyoruz
UPDATE dbo.TelcoCustomers
SET TotalCharges = NULL
WHERE TRY_CAST(TotalCharges AS DECIMAL(10,2)) IS NULL

-- Kolon tipini sayıya dönüştürüyoruz
ALTER TABLE dbo.TelcoCustomers
ALTER COLUMN TotalCharges DECIMAL(10,2);

----------------------------------------

SELECT * FROM TelcoCustomers

-- Toplam müşteri sayısını bul.
SELECT COUNT(CustomerID) AS TOPLAMMUSTERI
FROM TelcoCustomers

-- Churn olan (Yes) müşterilerin sayısını ve oranını bul.
SELECT COUNT(CustomerID) AS ToplamMusteri,
SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS ChurnOlanMusteri,
SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS ChurnOrani
FROM TelcoCustomers;

-- Sözleşme türüne (Contract) göre müşteri sayılarını listele.
SELECT Contract, COUNT(*) AS ToplamMusteri
FROM TelcoCustomers
GROUP BY Contract

-- İnternet hizmeti almayan (InternetService = 'No') müşterileri listele.
SELECT COUNT(*) AS InternetHizmetiAlamayanlar
FROM TelcoCustomers
WHERE InternetService='No'

-- Aylık ücreti (MonthlyCharges) 80’den büyük olan müşterileri CustomerID ile birlikte getir.
SELECT CustomerID
FROM TelcoCustomers
WHERE MonthlyCharges>80

-- Aylık ücrete göre müşterileri “Düşük (0-50)”, “Orta (50-90)”, “Yüksek (90+)” diye gruplayıp kaç müşteri olduğunu göster.
SELECT COUNT(*) AS MusteriSayisi,
CASE 
WHEN MonthlyCharges<=50 THEN 'Düşük'
WHEN MonthlyCharges<=90 THEN 'Orta'
ELSE 'Yüksek' END AS UcretGrubu
FROM TelcoCustomers
GROUP BY 
CASE 
WHEN MonthlyCharges<=50 THEN 'Düşük'
WHEN MonthlyCharges<=90 THEN 'Orta' 
ELSE 'Yüksek' END 
ORDER BY 1

-- Tenure’a göre müşterileri 12 aydan kısa / 12-24 arası / 24+ olarak gruplandır ve her grubun churn oranını getir.
SELECT COUNT(*) AS ToplamMusteri,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*1.0/COUNT(*) AS ChurnOrani,
CASE 
WHEN Tenure<12 THEN '<12'
WHEN Tenure<=24 THEN '12-24'
ELSE '24+' END AS TenureGrupları
FROM TelcoCustomers
GROUP BY
CASE 
WHEN Tenure<12 THEN '<12'
WHEN Tenure<=24 THEN '12-24'
ELSE '24+' END

-- PaymentMethod’a göre ortalama MonthlyCharges değerlerini hesapla, yüksekten düşüğe sırala.
SELECT PaymentMethod,
AVG(MonthlyCharges) AS AylıkGelirOrtalamasi
FROM TelcoCustomers
GROUP BY PaymentMethod
ORDER BY 2 DESC

-- Contract = ‘Month-to-month’ olan ve Churn = ‘Yes’ olan müşterilerin ortalama tenure değerini bul.
SELECT
AVG(Tenure) AS OrtalamaTenure
FROM TelcoCustomers
WHERE Contract='Month-to-month' AND Churn='Yes'

-- PaperlessBilling = ‘Yes’ olan müşterilerin kaç tanesi InternetService = ‘Fiber optic’ kullanıyor?
SELECT COUNT(CustomerID) AS MusteriSayisi
FROM TelcoCustomers
WHERE PaperlessBilling='Yes' AND InternetService='Fiber optic'

-- Önce her Contract türü için churn oranını hesaplayan bir CTE yaz(ara tablo), sonra en yüksek churn oranına sahip sözleşme türünü getir(ana sorgu).
WITH ContractChurn AS
(SELECT Contract,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*1.0/COUNT(*) AS ChurnOrani
FROM TelcoCustomers
GROUP BY Contract)
SELECT TOP 1 *
FROM ContractChurn
ORDER BY ChurnOrani DESC

-- MonthlyCharges değeri en yüksek ilk 10 müşteriyi sıralayarak listele (eşitliklerde aynı sırayı versin).Önce herkese sıra numarası ver(ara tablo) sonra ilk 10'u sırala(ana sorgu)
WITH ChargesRank AS
(SELECT CustomerID, MonthlyCharges,
RANK() OVER (ORDER BY MonthlyCharges DESC) AS UcretSirasi
FROM TelcoCustomers)
SELECT TOP 10 *
FROM ChargesRank
ORDER BY UcretSirasi

-- Churn olan müşterilerde “OnlineSecurity” = ‘No’ ise 1 puan, ‘Yes’ ise 0 puan ver; toplam “güvenlik açığı puanı”nı hesapla.
WITH Churn AS
(SELECT *
FROM TelcoCustomers
WHERE Churn='Yes')
SELECT 
SUM(CASE WHEN OnlineSecurity='No' THEN 1 ELSE 0 END) AS GuvenlikAcigiPuani
FROM Churn

-- Tenure’a göre müşteri başına ortalama MonthlyCharges’ı bulan bir ara tablo oluştur, sonra bu ara tablodan ortalamanın üstünde olan müşterileri getir.
WITH AVGMONTHLYCHARGES AS
(SELECT Tenure, AVG(MonthlyCharges) AS OrtalamaMonthlyCharges
FROM TelcoCustomers
GROUP BY Tenure)
SELECT T.CustomerID,
T.MonthlyCharges,
T.Tenure,
A.OrtalamaMonthlyCharges
FROM TelcoCustomers T JOIN AVGMONTHLYCHARGES A ON T.Tenure=A.Tenure
WHERE T.MonthlyCharges>A.OrtalamaMonthlyCharges

-- Hem InternetService = ‘Fiber optic’ olan hem de StreamingTV = ‘Yes’ olan müşteriler içinde churn oranını hesapla ve genel churn oranıyla karşılaştır (iki satır gibi düşün).
SELECT 'Fiber&TV' AS Grup,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*1.0/COUNT(*) AS ChurnOrani
FROM TelcoCustomers
WHERE InternetService='Fiber optic' AND StreamingTV='Yes'

UNION ALL

SELECT 'Genel' AS Grup,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*1.0/COUNT(*) AS ChurnOrani
FROM TelcoCustomers

-- Her müşterinin MonthlyCharges değerini kendi Contract türünün ortalamasıyla karşılaştır. Kendi Contract ortalamasının ÜSTÜNDE olan müşterileri listele.
WITH AVGCONTRACT AS
(SELECT CustomerID, Contract, MonthlyCharges,
AVG(MonthlyCharges) OVER (PARTITION BY Contract) AS ContractOrtalamasi
FROM TelcoCustomers)
SELECT * 
FROM AVGCONTRACT
WHERE MonthlyCharges > ContractOrtalamasi

-- Her InternetService türü için churn oranını hesaplayan bir CTE oluştur. CTE'den churn oranı 0.25'ten büyük olan internet türlerini getir.
WITH CHURNORANI AS 
(SELECT InternetService,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*1.0/COUNT(*) AS ChurnOrani
FROM TelcoCustomers
GROUP BY InternetService)
SELECT InternetService
FROM CHURNORANI
WHERE ChurnOrani>0.25

-- Tek satırda şu değerleri göster:
-- 1) Toplam müşteri sayısı
-- 2) Fiber optic müşteriler
-- 3) Fiber optic + churn olan müşteriler
-- 4) PaperlessBilling='Yes' müşteriler
SELECT
COUNT(CustomerID) AS ToplamMusteriSayisi,
SUM(CASE WHEN InternetService='Fiber optic' THEN 1 ELSE 0 END) AS FiberOptikMusteriSayisi,
SUM(CASE WHEN InternetService='Fiber optic' AND Churn='Yes' THEN 1 ELSE 0 END) AS FiberChurnMüsteriSayisi,
SUM(CASE WHEN PaperlessBilling='Yes' THEN 1 ELSE 0 END) AS PaperlessBilling
FROM TelcoCustomers

-- 1. satırda: Contract='Month-to-month' olanların churn oranı
-- 2. satırda: Contract='Two year' olanların churn oranı. 
SELECT 'Month-to-month' AS Grup,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*1.0/COUNT(*) AS ChurnOrani
FROM TelcoCustomers
WHERE Contract='Month-to-month'

UNION ALL

SELECT 'Two year' AS Grup,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*1.0/COUNT(*) AS ChurnOrani
FROM TelcoCustomers
WHERE Contract='Two year'

-- InternetService='Fiber optic' olan müşterilerde MonthlyCharges'e göre azalan sıralama yap.
-- ROW_NUMBER() kullanarak her müşteriye sıra numarası ver.
-- İlk 5 müşteriyi getir.
WITH FiberSirali AS (
SELECT
CustomerID,
MonthlyCharges,
ROW_NUMBER() OVER (ORDER BY MonthlyCharges DESC) AS Sira
FROM TelcoCustomers
WHERE InternetService = 'Fiber optic')
SELECT *
FROM FiberSirali
WHERE Sira <= 5
