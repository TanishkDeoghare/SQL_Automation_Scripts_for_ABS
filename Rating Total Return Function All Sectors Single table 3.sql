USE AOCA;
DECLARE 
    @startDate date,
    @endDate date

SET @startDate = '20240101';
SET @endDate = '20240628';

WITH TempTbl AS (
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
            ELSE pos.AOCA_Rating
        END AS 'Rating',
        1 + SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0) + COALESCE(pos.Interest, 0) + COALESCE(pos.Dividend, 0) + COALESCE(pos.Other, 0)) / NULLIF(SUM(pos.MarketValue) - SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0)), 0) AS 'TotalReturn',
        SUM(pos.Marketvalue) AS 'Marketvalue',
        SUM(pos.Marketvalue) / SUM(SUM(pos.Marketvalue)) OVER (PARTITION BY pos.Fund, pos.Sector) * 100 AS 'Allocation'
    FROM fund.Positions pos
    LEFT JOIN Instrument c ON pos.cusip = c.cusip
    WHERE pos.Date = @endDate
	  AND pos.WAL >= 0.5
      AND pos.Fund IN ('AOHY', 'UYLD', 'ANGLX', 'CARY', 'AOUIX', 'MBS', 'ASCIX')
      AND c.Class NOT IN ('Cash', 'Derivatives')
      AND pos.Sector IN ('CRT', 'Prime', 'Non-QM', 'ABS Auto', 'ABS Consumer')
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
            ELSE pos.AOCA_Rating
        END
),
Returns AS (
    SELECT
        Fund,
        Sector,
        Rating,
        EXP(SUM(LOG(CASE WHEN TotalReturn IS NULL OR TotalReturn <= 0 THEN 1 ELSE TotalReturn END))) - 1 AS 'TotalReturn'
    FROM TempTbl
    GROUP BY Fund, Sector, Rating
)

SELECT 
    pos.Fund,
    pos.Sector,
    pos.Rating,
    pos.Marketvalue,
    pos.Allocation,
    r.TotalReturn
FROM TempTbl pos
LEFT JOIN Returns r ON pos.Fund = r.Fund AND pos.Sector = r.Sector AND pos.Rating = r.Rating
ORDER BY 
    pos.Fund,
    pos.Sector,
    pos.Rating;
