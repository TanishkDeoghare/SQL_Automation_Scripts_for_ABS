DECLARE 
	@Fund varchar(50), 
	@startDate date,
	@endDate date,
	@Sector varchar(50)

SET @Fund = 'MBS'
SET @startDate = '20240101'
SET @endDate = '20240628'
SET @Sector = 'CRT'

;

with temptbl as (select
			Date,
			CASE 
				WHEN pos.AOCA_Rating in ('AAA','AA','A') THEN '>BBB'
				WHEN pos.AOCA_Rating = ('BBB') THEN 'BBB'
				WHEN pos.AOCA_Rating in ('BB') THEN 'BB'
				WHEN pos.AOCA_Rating in ('B','CCC','CC','C') THEN '<=B'
			ELSE 'NR' END AS 'Rating'
			,1 + sum(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0) + COALESCE(pos.Interest, 0) + COALESCE(pos.Dividend, 0) + COALESCE(pos.Other, 0)) / NULLIF(sum(pos.MarketValue) - sum(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0) ), 0) as 'TotalReturn'
			from fund.Positions pos
			LEFT JOIN Instrument c on pos.cusip = c.cusip
		where pos.Date between @startDate and @endDate
		and pos.WAL >= 0.5
		and pos.Fund = @Fund 
		and c.Class not in ('Cash', 'Derivatives')
			
GROUP BY 		pos.Date, 
				CASE 
				WHEN pos.AOCA_Rating in ('AAA','AA','A') THEN '>BBB'
				WHEN pos.AOCA_Rating in ('BBB') THEN 'BBB'
				WHEN pos.AOCA_Rating in ('BB') THEN 'BB'
				WHEN pos.AOCA_Rating in ('B','CCC','CC','C') THEN '<=B'
			ELSE 'NR' END
		)
		,
		Returns as (
select
        Rating,
		exp(SUM(log(CASE WHEN a.TotalReturn IS NULL OR a.TotalReturn <= 0 THEN 1 ELSE a.TotalReturn END))) - 1 as 'TotalReturn'
    from temptbl a
	group by Rating
)
,
Positions_CTE as(

SELECT 
			CASE 
				WHEN AOCA_Rating in ('AAA','AA','A') THEN '>BBB'
				WHEN AOCA_Rating = ('BBB') THEN 'BBB'
				WHEN AOCA_Rating in ('BB') THEN 'BB'
				WHEN AOCA_Rating in ('B','CCC','CC','C') THEN '<=B'
			ELSE 'NR' END AS 'Rating'
	,SUM(Marketvalue) as 'Marketvalue'
	,SUM(Marketvalue)/(SUM(SUM(Marketvalue)) OVER()) AS 'Allocation'

	from fund.positions where date = @endDate
	and fund = @Fund
	and Sector = @Sector
	GROUP BY
	CASE
		WHEN AOCA_Rating in ('AAA','AA','A') THEN '>BBB'
		WHEN AOCA_Rating = ('BBB') THEN 'BBB'
		WHEN AOCA_Rating in ('BB') THEN 'BB'
		WHEN AOCA_Rating in ('B','CCC','CC','C') THEN '<=B'
	ELSE 'NR' END
)


SELECT 

pos.Rating,pos.Marketvalue,pos.Allocation,r.TotalReturn

FROM Positions_CTE pos
LEFT JOIN Returns r on pos.Rating = r.Rating

ORDER BY CASE 
	WHEN pos.Rating = '>BBB' THEN 1
	WHEN pos.Rating = 'BBB' THEN 2
	WHEN pos.Rating = 'BB' THEN 3
	WHEN pos.Rating = '<=B' THEN 4
	WHEN pos.Rating = 'NR' THEN 5
	ELSE 6 END
	ASC
