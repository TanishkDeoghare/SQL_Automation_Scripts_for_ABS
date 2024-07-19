DECLARE 
    @startDate date,
    @endDate date

SET @startDate = '2024-01-01' -- insert ? for excel 
SET @endDate = '2024-06-28' -- insert ? for excel 

-- Query logic for all sectors and funds
;WITH BaseData AS (
    SELECT
        pos.Fund,
        pos.Sector,
        pos.Date,
        CASE 
            WHEN pos.Sector = 'CRT' THEN
                CASE 
                    WHEN pos.AOCA_Rating IN ('AAA', 'AA', 'A') THEN '>BBB'
                    WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                    WHEN pos.AOCA_Rating = 'BB' THEN 'BB'
                    WHEN pos.AOCA_Rating IN ('B', 'CCC', 'CC', 'C') THEN '<=B'
                    ELSE 'NR' 
                END
            WHEN pos.Sector IN ('Prime', 'Non-QM') THEN
                CASE 
                    WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                    WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                    WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                    WHEN pos.AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                    ELSE 'NR' 
                END
            WHEN pos.Sector IN ('ABS Auto', 'ABS Consumer') THEN
                CASE 
                    WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                    WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                    WHEN pos.AOCA_Rating IN ('BBB', 'BB', 'B', 'CCC', 'CC', 'C') THEN '<=BBB'
                    ELSE 'NR' 
                END
        END AS 'Rating',
        1 + SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0) + COALESCE(pos.Interest, 0) + COALESCE(pos.Dividend, 0) + COALESCE(pos.Other, 0)) / NULLIF(SUM(pos.MarketValue) - SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0)), 0) AS 'TotalReturn'
    FROM fund.Positions pos
    LEFT JOIN Instrument c ON pos.cusip = c.cusip
    WHERE pos.Date BETWEEN @startDate AND @endDate
    AND pos.WAL >= 0.5
    AND c.Class NOT IN ('Cash', 'Derivatives')
    GROUP BY 
        pos.Fund,
        pos.Sector,
        pos.Date,
        CASE 
            WHEN pos.Sector = 'CRT' THEN
                CASE 
                    WHEN pos.AOCA_Rating IN ('AAA', 'AA', 'A') THEN '>BBB'
                    WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                    WHEN pos.AOCA_Rating = 'BB' THEN 'BB'
                    WHEN pos.AOCA_Rating IN ('B', 'CCC', 'CC', 'C') THEN '<=B'
                    ELSE 'NR' 
                END
            WHEN pos.Sector IN ('Prime', 'Non-QM') THEN
                CASE 
                    WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                    WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                    WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                    WHEN pos.AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                    ELSE 'NR' 
                END
            WHEN pos.Sector IN ('ABS Auto', 'ABS Consumer') THEN
                CASE 
                    WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                    WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                    WHEN pos.AOCA_Rating IN ('BBB', 'BB', 'B', 'CCC', 'CC', 'C') THEN '<=BBB'
                    ELSE 'NR' 
                END
    END
),
Returns AS (
    SELECT
        Fund,
        Sector,
        Rating,
        EXP(SUM(LOG(CASE WHEN TotalReturn IS NULL OR TotalReturn <= 0 THEN 1 ELSE TotalReturn END))) - 1 AS 'TotalReturn'
    FROM BaseData
    GROUP BY Fund, Sector, Rating
	--GROUP BY Rating
),
Positions_CTE AS (
    SELECT 
        pos.Fund,
        pos.Sector,
        CASE 
            WHEN pos.Sector = 'CRT' THEN
                CASE 
                    WHEN pos.AOCA_Rating IN ('AAA', 'AA', 'A') THEN '>BBB'
                    WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                    WHEN pos.AOCA_Rating = 'BB' THEN 'BB'
                    WHEN pos.AOCA_Rating IN ('B', 'CCC', 'CC', 'C') THEN '<=B'
                    ELSE 'NR' 
                END
            WHEN pos.Sector IN ('Prime', 'Non-QM') THEN
                CASE 
                    WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                    WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                    WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                    WHEN pos.AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                    ELSE 'NR' 
                END
            WHEN pos.Sector IN ('ABS Auto', 'ABS Consumer') THEN
                CASE 
                    WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                    WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                    WHEN pos.AOCA_Rating IN ('BBB', 'BB', 'B', 'CCC', 'CC', 'C') THEN '<=BBB'
                    ELSE 'NR' 
                END
        END AS 'Rating',
        SUM(pos.Marketvalue) AS 'Marketvalue',
        SUM(pos.Marketvalue) / SUM(SUM(pos.Marketvalue)) OVER (PARTITION BY pos.Fund, pos.Sector) * 100 AS 'Allocation'
    FROM fund.positions pos
    WHERE pos.date = @endDate
    GROUP BY 
        pos.Fund,
        pos.Sector,
        CASE 
            WHEN pos.Sector = 'CRT' THEN
                CASE 
                    WHEN pos.AOCA_Rating IN ('AAA', 'AA', 'A') THEN '>BBB'
                    WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                    WHEN pos.AOCA_Rating = 'BB' THEN 'BB'
                    WHEN pos.AOCA_Rating IN ('B', 'CCC', 'CC', 'C') THEN '<=B'
                    ELSE 'NR' 
                END
            WHEN pos.Sector IN ('Prime', 'Non-QM') THEN
                CASE 
                    WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                    WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                    WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                    WHEN pos.AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                    ELSE 'NR' 
                END
            WHEN pos.Sector IN ('ABS Auto', 'ABS Consumer') THEN
                CASE 
                    WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                    WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                    WHEN pos.AOCA_Rating IN ('BBB', 'BB', 'B', 'CCC', 'CC', 'C') THEN '<=BBB'
                    ELSE 'NR' 
                END
	END
)

SELECT 
    pos.Fund,
    pos.Sector,
    pos.Rating,
    pos.Marketvalue,
    pos.Allocation,
    r.TotalReturn
FROM Positions_CTE pos
LEFT JOIN Returns r ON pos.Fund = r.Fund AND pos.Sector = r.Sector AND pos.Rating = r.Rating
ORDER BY 
    pos.Fund,
    pos.Sector,
    CASE 
        WHEN pos.Rating = 'AAA' THEN 1
        WHEN pos.Rating = 'AA/A' THEN 2
        WHEN pos.Rating = '>BBB' THEN 3
        WHEN pos.Rating = 'BBB' THEN 4
        WHEN pos.Rating = '<=BBB' THEN 5
        WHEN pos.Rating = 'BB' THEN 6
        WHEN pos.Rating = '<=BB' THEN 7
        WHEN pos.Rating = '<=B' THEN 8
        WHEN pos.Rating = 'NR' THEN 9
        ELSE 10 
    END ASC;
