-- QA script

-- ---------------------------------------------------------------------------------------------------------------------
-- input testing
-- ---------------------------------------------------------------------------------------------------------------------

WITH CONSTS (_type, _X, _K, _t, _r, _q, _s, _opt_price) as (
   values ('call',50,50,1,0.01,0.01,0.2,3.94)
)

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
	SELECT 'BSM' MODEL, BSM_PRICE(_type, _X, _K, _t, _r, _q, _s) PRICE FROM CONSTS UNION ALL
	SELECT 'B76' MODEL, B76_PRICE(_type, _X, _K, _t, _r, _s) PRICE FROM CONSTS UNION ALL
	SELECT 'BFS' MODEL, BFS_PRICE(_type, _X, _K, _t, _r, (_s * _X)) PRICE FROM CONSTS
) AA
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_DELTA(_type, _X, _K, _t, _r, _q, _s) DELTA FROM CONSTS UNION ALL
	SELECT 'B76' MODEL, B76_DELTA(_type, _X, _K, _t, _r, _s) DELTA FROM CONSTS UNION ALL
	SELECT 'BFS' MODEL, BFS_DELTA(_type, _X, _K, _t, _r, (_s * _X)) DELTA FROM CONSTS
) BB
ON AA.MODEL = BB.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_GAMMA(_type, _X, _K, _t, _r, _q, _s) GAMMA FROM CONSTS UNION ALL
	SELECT 'B76' MODEL, B76_GAMMA(_type, _X, _K, _t, _r, _s) GAMMA FROM CONSTS UNION ALL
	SELECT 'BFS' MODEL, BFS_GAMMA(_type, _X, _K, _t, _r, (_s * _X)) GAMMA FROM CONSTS
) CC
ON AA.MODEL = CC.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_RHO(_type, _X, _K, _t, _r, _q, _s) RHO FROM CONSTS UNION ALL
	SELECT 'B76' MODEL, B76_RHO(_type, _X, _K, _t, _r, _s) RHO FROM CONSTS UNION ALL
	SELECT 'BFS' MODEL, BFS_RHO(_type, _X, _K, _t, _r, (_s * _X)) RHO FROM CONSTS
) DD
ON AA.MODEL = DD.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_THETA(_type, _X, _K, _t, _r, _q, _s) THETA FROM CONSTS UNION ALL
	SELECT 'B76' MODEL, B76_THETA(_type, _X, _K, _t, _r, _s) THETA FROM CONSTS UNION ALL
	SELECT 'BFS' MODEL, BFS_THETA(_type, _X, _K, _t, _r, (_s * _X)) THETA FROM CONSTS
) EE
ON AA.MODEL = EE.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_VEGA(_type, _X, _K, _t, _r, _q, _s) VEGA FROM CONSTS UNION ALL
	SELECT 'B76' MODEL, B76_VEGA(_type, _X, _K, _t, _r, _s) VEGA FROM CONSTS UNION ALL
	SELECT 'BFS' MODEL, BFS_VEGA(_type, _X, _K, _t, _r, (_s * _X)) VEGA FROM CONSTS
) FF
ON AA.MODEL = FF.MODEL
LEFT JOIN (
	SELECT 'BSM' MODEL, BSM_IVOL_BS(_type, _X, _K, _t, _r, _q, _opt_price) IVOL FROM CONSTS UNION ALL
	SELECT 'B76' MODEL, B76_IVOL_BS(_type, _X, _K, _t, _r, _opt_price) IVOL FROM CONSTS UNION ALL
	SELECT 'BFS' MODEL, BFS_IVOL_BS(_type, _X, _K, _t, _r,_opt_price)/_X IVOL FROM CONSTS
) GG
ON AA.MODEL = GG.MODEL;

-- ---------------------------------------------------------------------------------------------------------------------
-- validating above Greeks results by measuring the impact of small change in parameters
-- ---------------------------------------------------------------------------------------------------------------------

-- comment based on the following parameters: _X = 50; _K = 50; _t = 1; _r = 0.01; _q = 0.01; _s = 0.2; _type = 'CALL';

-- delta, e.g. a $1 increase in the underlying price is expected to increase the call value by $0.55
SELECT BSM_PRICE(_type, _X + 1, _K, _t, _r, _q, _s) - BSM_PRICE(_type, _X, _K, _t, _r, _q, _s) DELTA FROM CONSTS;

-- gamma, e.g. a $1 increase in the underlying price is expected to change delta by 0.038
SELECT BSM_DELTA(_type, _X + 1, _K, _t, _r, _q, _s) - BSM_DELTA(_type, _X, _K, _t, _r, _q, _s) GAMMA FROM CONSTS;

-- rho, e.g. a 1% increase in the risk-free interest rate is expected to increase the call value by $0.22
SELECT BSM_PRICE(_type, _X, _K, _t, _r + 0.01, _q, _s) - BSM_PRICE(_type, _X, _K, _t, _r, _q, _s) RHO FROM CONSTS;

-- theta, e.g. a 1 less day to maturity is expected to reduce the call value by $0.22
SELECT BSM_PRICE(_type, _X, _K, _t - (1/360), _r, _q, _s) - BSM_PRICE(_type, _X, _K, _t, _r, _q, _s) THETA FROM CONSTS;

-- vega, e.g. a 1% increase in volatility is expected to increase the call value by $0.20
SELECT BSM_PRICE(_type, _X, _K, _t, _r, _q, _s + 0.01) - BSM_PRICE(_type, _X, _K, _t, _r, _q, _s) VEGA FROM CONSTS;

-- vega, e.g. a $1 increase in absolute volatility is expected to increase the call value by $0.39
SELECT BFS_PRICE(_type, _X, _K, _t, _r, (_s * _X) + 1) - BFS_PRICE(_type, _X, _K, _t, _r, (_s * _X)) VEGA FROM CONSTS;



