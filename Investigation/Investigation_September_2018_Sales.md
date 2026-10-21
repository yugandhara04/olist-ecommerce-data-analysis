**Investigation: September 2018 Sales Decline**



Background



During validation of the monthly sales trend in Power BI, September 2018 showed an unusually low recorded product sales value of \*\*145\*\*.



To investigate this anomaly, I cross-checked the `Orders` and `Order Items` tables using MySQL.



Key Findings



\* September 2018 had \*\*16 orders\*\*, of which \*\*15 were cancelled\*\*.

\* The remaining shipped order had a recorded product price of \*\*145\*\*.

\* None of the 15 cancelled orders had corresponding records in the `Order Items` table.

\* The Power BI sales measure, `SUM(fact\_order\_items\[price])`, was consistent with the underlying data.



Conclusion



The unusually low recorded sales value is consistent with the limited number of orders that had corresponding order-item records during the period examined.



This finding explains the September figure within the scope of this investigation. However, it should not be interpreted as evidence of an overall business-performance decline without further validation.



