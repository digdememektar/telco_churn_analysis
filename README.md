# Telco Customer Churn Analysis | SQL & Python 

Bu çalışma, Kaggle’daki **Telco Customer Churn** verisi üzerinden yaptığım çift yönlü bir analiz pratiğidir.  
Amacım aynı datayı hem **SQL** hem **Python (Pandas)** tarafında ele alarak iki farklı analiz dilinin düşünme şeklini karşılaştırmaktı.

Projeye başlamadan önce ChatGPT’den bu veriyle ilgili çeşitli SQL ve Python soruları üretmesini istedim.  
O sordu, ben ise sorguları ve kodları kendim yazarak çözdüm.

---

## 🔹 SQL Tarafı
SQL kısmında CASE, RANK, WITH, HAVING gibi kalıpları kullanarak farklı seviyelerde 15’ten fazla sorgu yazdım.  
Segment bazlı churn oranlarını, gelir analizlerini ve müşteri davranışlarını sorguladım.  
Bu bölümde veri sorgulama, filtreleme ve gruplama pratiğini derinleştirmeyi hedefledim.

---

## 🔹 Python Tarafı
Aynı veri bu kez Python tarafında, **Pandas** kütüphanesi ile ele alındı.  
SQL’deki sorguların karşılıklarını yeniden yazarken:
- Yeni kolonlar oluşturdum (`customer_value = MonthlyCharges * tenure`)
- Segment bazlı churn oranlarını hesapladım  
- Ortalama karşılaştırmaları ve görselleştirmeler yaptım  

Kullanılan kütüphaneler:
```python
import pandas as pd
import matplotlib.pyplot as plt
