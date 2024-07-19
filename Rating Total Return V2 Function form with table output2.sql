DECLARE 
    @Fund varchar(50), 
    @startDate date,
    @endDate date,
    @Sector varchar(50)

SET @Fund = 'AOHY' -- insert ? for excel 
SET @startDate = '2024-01-01' -- insert ? for excel 
SET @endDate = '2024-06-28' -- insert ? for excel 
SET @Sector = 'CRT' -- insert ? for excel  

-- Sector based query logic
IF @Sector = 'CRT'
BEGIN
    WITH temptbl AS (
        SELECT
            Date,
            CASE 
                WHEN pos.AOCA_Rating IN ('AAA', 'AA', 'A') THEN '>BBB'
                WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN pos.AOCA_Rating = 'BB' THEN 'BB'
                WHEN pos.AOCA_Rating IN ('B', 'CCC', 'CC', 'C') THEN '<=B'
                ELSE 'NR' 
            END AS 'Rating',
            1 + SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0) + COALESCE(pos.Interest, 0) + COALESCE(pos.Dividend, 0) + COALESCE(pos.Other, 0)) / NULLIF(SUM(pos.MarketValue) - SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0)), 0) AS 'TotalReturn'
        FROM fund.Positions pos
        LEFT JOIN Instrument c ON pos.cusip = c.cusip
        WHERE pos.Date BETWEEN @startDate AND @endDate
        AND pos.WAL >= 0.5
        AND pos.Fund = @Fund 
        AND c.Class NOT IN ('Cash', 'Derivatives')
        GROUP BY 
            pos.Date, 
            CASE 
                WHEN pos.AOCA_Rating IN ('AAA', 'AA', 'A') THEN '>BBB'
                WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN pos.AOCA_Rating = 'BB' THEN 'BB'
                WHEN pos.AOCA_Rating IN ('B', 'CCC', 'CC', 'C') THEN '<=B'
                ELSE 'NR' 
            END
    ),
    Returns AS (
        SELECT
            Rating,
            EXP(SUM(LOG(CASE WHEN a.TotalReturn IS NULL OR a.TotalReturn <= 0 THEN 1 ELSE a.TotalReturn END))) - 1 AS 'TotalReturn'
        FROM temptbl a
        GROUP BY Rating
    ),
    Positions_CTE AS (
        SELECT 
            CASE 
                WHEN AOCA_Rating IN ('AAA', 'AA', 'A') THEN '>BBB'
                WHEN AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN AOCA_Rating = 'BB' THEN 'BB'
                WHEN AOCA_Rating IN ('B', 'CCC', 'CC', 'C') THEN '<=B'
                ELSE 'NR' 
            END AS 'Rating',
            SUM(Marketvalue) AS 'Marketvalue',
            SUM(Marketvalue) / (SUM(SUM(Marketvalue)) OVER()) AS 'Allocation'
        FROM fund.positions 
        WHERE date = @endDate
        AND fund = @Fund
        AND Sector = @Sector
        GROUP BY
            CASE
                WHEN AOCA_Rating IN ('AAA', 'AA', 'A') THEN '>BBB'
                WHEN AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN AOCA_Rating = 'BB' THEN 'BB'
                WHEN AOCA_Rating IN ('B', 'CCC', 'CC', 'C') THEN '<=B'
                ELSE 'NR' 
            END
    )
    SELECT 
        pos.Rating,
        pos.Marketvalue,
        pos.Allocation,
        r.TotalReturn
    FROM Positions_CTE pos
    LEFT JOIN Returns r ON pos.Rating = r.Rating
    ORDER BY 
        CASE 
            WHEN pos.Rating = '>BBB' THEN 1
            WHEN pos.Rating = 'BBB' THEN 2
            WHEN pos.Rating = 'BB' THEN 3
            WHEN pos.Rating = '<=B' THEN 4
            WHEN pos.Rating = 'NR' THEN 5
            ELSE 6 
        END ASC;
END
ELSE IF @Sector IN ('Prime', 'Non-QM')
BEGIN
    WITH temptbl AS (
        SELECT
            Date,
            CASE 
                WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN pos.AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                ELSE 'NR' 
            END AS 'Rating',
            1 + SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0) + COALESCE(pos.Interest, 0) + COALESCE(pos.Dividend, 0) + COALESCE(pos.Other, 0)) / NULLIF(SUM(pos.MarketValue) - SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0)), 0) AS 'TotalReturn'
        FROM fund.Positions pos
        LEFT JOIN Instrument c ON pos.cusip = c.cusip
        WHERE pos.Date BETWEEN @startDate AND @endDate
        AND pos.WAL >= 0.5
        AND pos.Fund = @Fund 
        AND c.Class NOT IN ('Cash', 'Derivatives')
        GROUP BY 
            pos.Date, 
            CASE 
                WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN pos.AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                ELSE 'NR' 
            END
    ),
    Returns AS (
        SELECT
            Rating,
            EXP(SUM(LOG(CASE WHEN a.TotalReturn IS NULL OR a.TotalReturn <= 0 THEN 1 ELSE a.TotalReturn END))) - 1 AS 'TotalReturn'
        FROM temptbl a
        GROUP BY Rating
    ),
    Positions_CTE AS (
        SELECT 
            CASE 
                WHEN AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                ELSE 'NR' 
            END AS 'Rating',
            SUM(Marketvalue) AS 'Marketvalue',
            SUM(Marketvalue) / (SUM(SUM(Marketvalue)) OVER()) AS 'Allocation'
        FROM fund.positions 
        WHERE date = @endDate
        AND fund = @Fund
        AND Sector = @Sector
        GROUP BY
            CASE 
                WHEN AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                ELSE 'NR' 
            END
    )
    SELECT 
        pos.Rating,
        pos.Marketvalue,
        pos.Allocation,
        r.TotalReturn
    FROM Positions_CTE pos
    LEFT JOIN Returns r ON pos.Rating = r.Rating
    ORDER BY 
        CASE 
            WHEN pos.Rating = 'AAA' THEN 1
            WHEN pos.Rating = 'AA/A' THEN 2
            WHEN pos.Rating = 'BBB' THEN 3
            WHEN pos.Rating = '<=BB' THEN 4
            WHEN pos.Rating = 'NR' THEN 5
            ELSE 6 
        END ASC;
END
ELSE IF @Sector IN ('ABS Auto', 'ABS Consumer')
BEGIN
    WITH temptbl AS (
        SELECT
            Date,
            CASE 
                WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN pos.AOCA_Rating IN ('BBB', 'BB', 'B', 'CCC', 'CC', 'C') THEN '<=BBB'
                ELSE 'NR' 
            END AS 'Rating',
            1 + SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0) + COALESCE(pos.Interest, 0) + COALESCE(pos.Dividend, 0) + COALESCE(pos.Other, 0)) / NULLIF(SUM(pos.MarketValue) - SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0)), 0) AS 'TotalReturn'
        FROM fund.Positions pos
        LEFT JOIN Instrument c ON pos.cusip = c.cusip
        WHERE pos.Date BETWEEN @startDate AND @endDate
        AND pos.WAL >= 0.5
        AND pos.Fund = @Fund 
        AND c.Class NOT IN ('Cash', 'Derivatives')
        GROUP BY 
            pos.Date, 
            CASE 
                WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN pos.AOCA_Rating IN ('BBB', 'BB', 'B', 'CCC', 'CC', 'C') THEN '<=BBB'
                ELSE 'NR' 
            END
    ),
    Returns AS (
        SELECT
            Rating,
            EXP(SUM(LOG(CASE WHEN a.TotalReturn IS NULL OR a.TotalReturn <= 0 THEN 1 ELSE a.TotalReturn END))) - 1 AS 'TotalReturn'
        FROM temptbl a
        GROUP BY Rating
    ),
    Positions_CTE AS (
        SELECT 
            CASE 
                WHEN AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN AOCA_Rating IN ('BBB', 'BB', 'B', 'CCC', 'CC', 'C') THEN '<=BBB'
                ELSE 'NR' 
            END AS 'Rating',
            SUM(Marketvalue) AS 'Marketvalue',
            SUM(Marketvalue) / (SUM(SUM(Marketvalue)) OVER()) AS 'Allocation'
        FROM fund.positions 
        WHERE date = @endDate
        AND fund = @Fund
        AND Sector = @Sector
        GROUP BY
            CASE 
                WHEN AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN AOCA_Rating IN ('BBB', 'BB', 'B', 'CCC', 'CC', 'C') THEN '<=BBB'
                ELSE 'NR' 
            END
    )
    SELECT 
        pos.Rating,
        pos.Marketvalue,
        pos.Allocation,
        r.TotalReturn
    FROM Positions_CTE pos
    LEFT JOIN Returns r ON pos.Rating = r.Rating
    ORDER BY 
        CASE 
            WHEN pos.Rating = 'AAA' THEN 1
            WHEN pos.Rating = 'AA/A' THEN 2
            WHEN pos.Rating = '<=BBB' THEN 3
            WHEN pos.Rating = 'NR' THEN 4
            ELSE 5
        END ASC;
END
ELSE
BEGIN
    -- Default query logic if no specific sector matches
    WITH temptbl AS (
        SELECT
            Date,
            CASE 
                WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN pos.AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                ELSE 'NR' 
            END AS 'Rating',
            1 + SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0) + COALESCE(pos.Interest, 0) + COALESCE(pos.Dividend, 0) + COALESCE(pos.Other, 0)) / NULLIF(SUM(pos.MarketValue) - SUM(COALESCE(pos.UnrealizedPrice, 0) + COALESCE(pos.RealizedPrice, 0)), 0) AS 'TotalReturn'
        FROM fund.Positions pos
        LEFT JOIN Instrument c ON pos.cusip = c.cusip
        WHERE pos.Date BETWEEN @startDate AND @endDate
        AND pos.WAL >= 0.5
        AND pos.Fund = @Fund 
        AND c.Class NOT IN ('Cash', 'Derivatives')
        GROUP BY 
            pos.Date, 
            CASE 
                WHEN pos.AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN pos.AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN pos.AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN pos.AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                ELSE 'NR' 
            END
    ),
    Returns AS (
        SELECT
            Rating,
            EXP(SUM(LOG(CASE WHEN a.TotalReturn IS NULL OR a.TotalReturn <= 0 THEN 1 ELSE a.TotalReturn END))) - 1 AS 'TotalReturn'
        FROM temptbl a
        GROUP BY Rating
    ),
    Positions_CTE AS (
        SELECT 
            CASE 
                WHEN AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                ELSE 'NR' 
            END AS 'Rating',
            SUM(Marketvalue) AS 'Marketvalue',
            SUM(Marketvalue) / (SUM(SUM(Marketvalue)) OVER()) AS 'Allocation'
        FROM fund.positions 
        WHERE date = @endDate
        AND fund = @Fund
        AND Sector = @Sector
        GROUP BY
            CASE 
                WHEN AOCA_Rating = 'AAA' THEN 'AAA'
                WHEN AOCA_Rating IN ('A', 'AA') THEN 'AA/A'
                WHEN AOCA_Rating = 'BBB' THEN 'BBB'
                WHEN AOCA_Rating IN ('BB', 'B', 'CCC', 'CC', 'C') THEN '<=BB'
                ELSE 'NR' 
            END
    )
    SELECT 
        pos.Rating,
        pos.Marketvalue,
        pos.Allocation,
        r.TotalReturn
    FROM Positions_CTE pos
    LEFT JOIN Returns r ON pos.Rating = r.Rating
    ORDER BY 
        CASE 
            WHEN pos.Rating = 'AAA' THEN 1
            WHEN pos.Rating = 'AA/A' THEN 2
            WHEN pos.Rating = 'BBB' THEN 3
            WHEN pos.Rating = '<=BB' THEN 4
            WHEN pos.Rating = 'NR' THEN 5
            ELSE 6 
        END ASC;
END;
