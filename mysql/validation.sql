-- QA script

-- ---------------------------------------------------------------------------------------------------------------------
-- input testing
-- ---------------------------------------------------------------------------------------------------------------------

SET @X = 50;
SET @K = 50;
SET @t = 1;
SET @r = 0.01;
SET @q = 0.01;
SET @s = 0.2;
SET @type = 'CALL';

-- ---------------------------------------------------------------------------------------------------------------------
-- table displaying results on different models for above parameters
-- ---------------------------------------------------------------------------------------------------------------------

-- Note that in the BFS model, vega, rho and ivol are expressed in absolute terms.

SELECT
	AA.MODEL,
	AA.PRICE,
	BB.DELTA,
	CC.GAMMA,
	DD.RHO,
	EE.THETA,
	FF.VEGA,
	GG.IVOL
FROM (
	SELECT 'BSM' MODEL, BSM_PRICE(@type, @X, @K, @t, @r, @q, @s) PRICE UNION ALL
	SELECT 'B76' MODEL, B76_PRICE(@type, @X, @K, @t, @r, @s) PRICE UNION ALL
	SELECT 'BFS' MODEL, BFS_PRICE(@type, @X, @K, @t, @r, (@s * @X)) PRICE
) AA
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_DELTA(@type, @X, @K, @t, @r, @q, @s) DELTA UNION ALL
	SELECT 'B76' MODEL, B76_DELTA(@type, @X, @K, @t, @r, @s) DELTA UNION ALL
	SELECT 'BFS' MODEL, BFS_DELTA(@type, @X, @K, @t, @r, (@s * @X)) DELTA
) BB
ON AA.MODEL = BB.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_GAMMA(@type, @X, @K, @t, @r, @q, @s) GAMMA UNION ALL
	SELECT 'B76' MODEL, B76_GAMMA(@type, @X, @K, @t, @r, @s) GAMMA UNION ALL
	SELECT 'BFS' MODEL, BFS_GAMMA(@type, @X, @K, @t, @r, (@s * @X)) GAMMA
) CC
ON AA.MODEL = CC.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_RHO(@type, @X, @K, @t, @r, @q, @s) RHO UNION ALL
	SELECT 'B76' MODEL, B76_RHO(@type, @X, @K, @t, @r, @s) RHO UNION ALL
	SELECT 'BFS' MODEL, BFS_RHO(@type, @X, @K, @t, @r, (@s * @X)) RHO
) DD
ON AA.MODEL = DD.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_THETA(@type, @X, @K, @t, @r, @q, @s) THETA UNION ALL
	SELECT 'B76' MODEL, B76_THETA(@type, @X, @K, @t, @r, @s) THETA UNION ALL
	SELECT 'BFS' MODEL, BFS_THETA(@type, @X, @K, @t, @r, (@s * @X)) THETA
) EE
ON AA.MODEL = EE.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_VEGA(@type, @X, @K, @t, @r, @q, @s) VEGA UNION ALL
	SELECT 'B76' MODEL, B76_VEGA(@type, @X, @K, @t, @r, @s) VEGA UNION ALL
	SELECT 'BFS' MODEL, BFS_VEGA(@type, @X, @K, @t, @r, (@s * @X)) VEGA
) FF
ON AA.MODEL = FF.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_IVOL(@type, @X, @K, @t, @r, @q, BSM_PRICE(@type, @X, @K, @t, @r, @q, @s)) IVOL UNION ALL
	SELECT 'B76' MODEL, B76_IVOL(@type, @X, @K, @t, @r, B76_PRICE(@type, @X, @K, @t, @r, @s)) IVOL UNION ALL
	SELECT 'BFS' MODEL, BFS_IVOL(@type, @X, @K, @t, @r, BFS_PRICE(@type, @X, @K, @t, @r, (@s * @X))) IVOL
) GG
ON AA.MODEL = GG.MODEL;

-- ---------------------------------------------------------------------------------------------------------------------
-- validating above Greeks results by measuring the impact of small change in parameters
-- ---------------------------------------------------------------------------------------------------------------------

-- comment based on the following parameters: @X = 50; @K = 50; @t = 1; @r = 0.01; @q = 0.01; @s = 0.2; @type = 'CALL';

-- delta, e.g. a $1 increase in the underlying price is expected to increase the call value by $0.55
SELECT BSM_PRICE(@type, @X + 1, @K, @t, @r, @q, @s) - BSM_PRICE(@type, @X, @K, @t, @r, @q, @s) DELTA;

-- gamma, e.g. a $1 increase in the underlying price is expected to change delta by 0.038
SELECT BSM_DELTA(@type, @X + 1, @K, @t, @r, @q, @s) - BSM_DELTA(@type, @X, @K, @t, @r, @q, @s) GAMMA;

-- rho, e.g. a 1% increase in the risk-free interest rate is expected to increase the call value by $0.22
SELECT BSM_PRICE(@type, @X, @K, @t, @r + 0.01, @q, @s) - BSM_PRICE(@type, @X, @K, @t, @r, @q, @s) RHO;

-- theta, e.g. a 1 less day to maturity is expected to reduce the call value by $0.22
SELECT BSM_PRICE(@type, @X, @K, @t - (1/360), @r, @q, @s) - BSM_PRICE(@type, @X, @K, @t, @r, @q, @s) THETA;

-- vega, e.g. a 1% increase in volatility is expected to increase the call value by $0.20
SELECT BSM_PRICE(@type, @X, @K, @t, @r, @q, @s + 0.01) - BSM_PRICE(@type, @X, @K, @t, @r, @q, @s) VEGA;

-- vega, e.g. a $1 increase in absolute volatility is expected to increase the call value by $0.39
SELECT BFS_PRICE(@type, @X, @K, @t, @r, (@s * @X) + 1) - BFS_PRICE(@type, @X, @K, @t, @r, (@s * @X)) VEGA;



