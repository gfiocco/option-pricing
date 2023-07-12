-- ---------------------------------------------------------------------------------------------------------------------
-- Statistical Functions
-- ---------------------------------------------------------------------------------------------------------------------

-- Numerical approximations for the normal PDF and CDF
CREATE OR REPLACE FUNCTION NORMSDIST(_x FLOAT, _cumulative BOOLEAN) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_pdf FLOAT;
	_cdf FLOAT;
	_t FLOAT;
BEGIN
	-- prevent underflow
	IF _x < -10 THEN RETURN 0; END IF;
	IF _x > 10 THEN RETURN 1; END IF;
	-- density of the standard normal distribution
	_pdf = (1/sqrt(2 * pi())) * exp(-power(_x,2)/2);
	IF _cumulative = FALSE 
	THEN
		RETURN _pdf;
	ELSE
		-- Zelen & Severo (1964) approximation of the cumulative distribution function of the standard normal distribution
		_t = 1/(1 + 0.2316419 * abs(_x));
		_cdf = 1 - _pdf * (0.31938153 * _t - 0.356563782 * power(_t,2) + 1.781477937 * power(_t,3) - 1.821255978 * power(_t,4) + 1.330274429 * power(_t,5));
		IF _x > 0
			THEN RETURN _cdf;
			ELSE RETURN 1 - _cdf;
		END IF;
	END IF;
	RETURN a * exp(-b * x) + c;
	EXCEPTION when others then 
	    RAISE NOTICE 'ERROR: % for NORMSDIST(%,%)',sqlerrm, _x, _cumulative;
	    RETURN null;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------------------------------------------------
-- Black-Scholes-Merton (BSM)
-- ---------------------------------------------------------------------------------------------------------------------

-- price
CREATE OR REPLACE FUNCTION BSM_PRICE(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _q FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
	_d2 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
	_d2 = _d1 - _s * sqrt(_t);
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN exp(-_q*_t) * NORMSDIST(_d1, TRUE) * _X - exp(-_r*_t) * NORMSDIST(_d2, TRUE) * _K;
		ELSE RETURN exp(-_r*_t) * NORMSDIST(-_d2, TRUE) * _K - exp(-_q*_t) * NORMSDIST(-_d1, TRUE) * _X;
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BSM_PRICE(%,%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _q, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- delta
CREATE OR REPLACE FUNCTION BSM_DELTA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _q FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
	_d2 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
	_d2 = _d1 - _s * sqrt(_t);
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN exp(-_q*_t) * NORMSDIST(_d1, TRUE);
		ELSE RETURN exp(-_q*_t) * (NORMSDIST(_d1, TRUE)-1);
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BSM_DELTA(%,%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _q, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- gamma
CREATE OR REPLACE FUNCTION BSM_GAMMA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _q FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
_d1 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
	RETURN ((exp(-_q*_t)/(_X*_s*sqrt(_t)))) * ((1/sqrt(2*pi()))) * (exp(-power(_d1,2)/2));
END;
$$ LANGUAGE plpgsql;

-- rho
CREATE OR REPLACE FUNCTION BSM_RHO(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _q FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
	_d2 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
	_d2 = _d1 - _s * sqrt(_t);
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN 0.01 * (_K*_t*exp(-_r*_t)) * NORMSDIST(_d2, TRUE);
		ELSE RETURN -0.01 * (_K*_t*exp(-_r*_t)) * NORMSDIST(-_d2, TRUE);
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BSM_RHO(%,%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _q, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- theta
CREATE OR REPLACE FUNCTION BSM_THETA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _q FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
	_d2 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
	_d2 = _d1 - _s * sqrt(_t);
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN (1::float/360) * ( -(((_X*_s*exp(-_q*_t))/(2*sqrt(_t)))*(1/sqrt(2*pi()))*exp(-(power(_d1,2))/2)) -(_r*_K*exp(-_r*_t)*NORMSDIST(_d2, TRUE)) +(_q*_X*exp(-_q*_t)*NORMSDIST(_d1, TRUE)) );
		ELSE RETURN (1::float/360) * ( -(((_X*_s*exp(-_q*_t))/(2*sqrt(_t)))*(1/sqrt(2*pi()))*exp(-(power(_d1,2))/2)) +(_r*_K*exp(-_r*_t)*NORMSDIST(-_d2, TRUE)) -(_q*_X*exp(-_q*_t)*NORMSDIST(-_d1, TRUE)) );
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BSM_THETA(%,%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _q, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- vega
CREATE OR REPLACE FUNCTION BSM_VEGA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _q FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
	RETURN 0.01 * (_X * exp(-_q*_t) * sqrt(_t)) * (1/sqrt(2*pi())) * exp(-power(_d1,2)/2);
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BSM_VEGA(%,%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _q, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------------------------------------------------
-- Black-76 (B76)
-- ---------------------------------------------------------------------------------------------------------------------

-- price
CREATE OR REPLACE FUNCTION B76_PRICE(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
	_d2 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
	_d2 = _d1 - _s * sqrt(_t);
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN exp(-_r*_t) * (NORMSDIST(_d1, TRUE) * _X - NORMSDIST(_d2, TRUE) * _K);
		ELSE RETURN exp(-_r*_t) * (NORMSDIST(-_d2, TRUE) * _K - NORMSDIST(-_d1, TRUE) * _X);
	END IF;
	EXCEPTION WHEN OTHERS THEN 
	RAISE NOTICE 'ERROR: % for B76_PRICE(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- delta
CREATE OR REPLACE FUNCTION B76_DELTA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
	_d2 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
	_d2 = _d1 - _s * sqrt(_t);
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN exp(-_r*_t) * NORMSDIST(_d1, TRUE);
		ELSE RETURN exp(-_r*_t) * (NORMSDIST(_d1, TRUE)-1);
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for B76_DELTA(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- gamma
CREATE OR REPLACE FUNCTION B76_GAMMA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
	RETURN ((exp(-_r*_t)/(_X*_s*sqrt(_t)))) * ((1/sqrt(2*pi()))) * (exp(-power(_d1,2)/2));
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for B76_GAMMA(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- rho
CREATE OR REPLACE FUNCTION B76_RHO(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
	_d2 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
	_d2 = _d1 - _s * sqrt(_t);
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN 0.01 * (_K*_t*exp(-_r*_t)) * NORMSDIST(_d2, TRUE);
		ELSE RETURN -0.01 * (_K*_t*exp(-_r*_t)) * NORMSDIST(-_d2, TRUE);
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for B76_RHO(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- theta
CREATE OR REPLACE FUNCTION B76_THETA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
	_d2 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
	_d2 = _d1 - _s * sqrt(_t);
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN (1::float/360) * ( -(((_X*_s*exp(-_r*_t))/(2*sqrt(_t)))*(1/sqrt(2*pi()))*exp(-(power(_d1,2))/2)) -(_r*_K*exp(-_r*_t)*NORMSDIST(_d2, TRUE)) +(_r*_X*exp(-_r*_t)*NORMSDIST(_d1, TRUE)) );
		ELSE RETURN (1::float/360) * ( -(((_X*_s*exp(-_r*_t))/(2*sqrt(_t)))*(1/sqrt(2*pi()))*exp(-(power(_d1,2))/2)) +(_r*_K*exp(-_r*_t)*NORMSDIST(-_d2, TRUE)) -(_r*_X*exp(-_r*_t)*NORMSDIST(-_d1, TRUE)) );
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for B76_THETA(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- vega
CREATE OR REPLACE FUNCTION B76_VEGA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d1 FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
	RETURN (1::float/100) * (_X * exp(-_r*_t) * sqrt(_t)) * (1/sqrt(2*pi())) * exp(-power(_d1,2)/2);
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for B76_VEGA(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------------------------------------------------
-- Bachelier Futures Spread (BFS)
-- ---------------------------------------------------------------------------------------------------------------------

-- price
CREATE OR REPLACE FUNCTION BFS_PRICE(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d = (_X - _K) / (_s * sqrt(_t));
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN exp(-_r*_t) * (NORMSDIST(_d, TRUE) * (_X - _K) + NORMSDIST(_d, FALSE) * (_s * sqrt(_t)));
		ELSE RETURN exp(-_r*_t) * (NORMSDIST(-_d, TRUE) * (_K - _X) + NORMSDIST(_d, FALSE) * (_s * sqrt(_t)));
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BFS_PRICE(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- delta
CREATE OR REPLACE FUNCTION BFS_DELTA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d = (_X - _K) / (_s * sqrt(_t));
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN exp(-_r*_t) * NORMSDIST(_d, TRUE);
		ELSE RETURN -exp(-_r*_t) * NORMSDIST(-_d, TRUE);
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BFS_DELTA(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- gamma
CREATE OR REPLACE FUNCTION BFS_GAMMA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d = (_X - _K) / (_s * sqrt(_t));
	RETURN exp(-_r*_t) * NORMSDIST(_d, FALSE) / (_s * sqrt(_t));
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BFS_GAMMA(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- rho
CREATE OR REPLACE FUNCTION BFS_RHO(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d = (_X - _K) / (_s * sqrt(_t));
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN -0.01 * _t * exp(-_r*_t) * (NORMSDIST(_d, TRUE) * (_X - _K) + NORMSDIST(_d, FALSE) * (_s * sqrt(_t)));
		ELSE RETURN -0.01 * _t * exp(-_r*_t) * (NORMSDIST(-_d, TRUE) * (_K - _X) + NORMSDIST(_d, FALSE) * (_s * sqrt(_t)));
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BFS_RHO(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- theta
CREATE OR REPLACE FUNCTION BFS_THETA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d = (_X - _K) / (_s * sqrt(_t));
	IF UPPER(_type) IN ('CALL','C')
		THEN RETURN -(1::float/360) * (-_r * exp(-_r*_t) * (NORMSDIST(_d, TRUE)*(_X - _K) + NORMSDIST(_d, FALSE)*(_s * sqrt(_t))) + (exp(-_r*_t) * _s * NORMSDIST(_d, FALSE)) / (2 * sqrt(_t)));
		ELSE RETURN -(1::float/360) * (-_r * exp(-_r*_t) * (NORMSDIST(-_d, TRUE)*(_K - _X) + NORMSDIST(_d, FALSE)*(_s * sqrt(_t))) +  (exp(-_r*_t) * _s * NORMSDIST(_d, FALSE)) / (2 * sqrt(_t)) - 2 * _r * exp(-_r*_t) * (_X - _K));
	END IF;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BFS_THETA(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- vega
CREATE OR REPLACE FUNCTION BFS_VEGA(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _s FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_d FLOAT;
BEGIN
	-- throw error if type is not CALL or PUT
	IF UPPER(_type) NOT IN ('CALL','PUT','C','P') 
		THEN RAISE EXCEPTION 'Contract type has to be either CALL or PUT';
	END IF;
	_d = (_X - _K) / (_s * sqrt(_t));
	RETURN exp(-_r*_t) * sqrt(_t) * NORMSDIST(_d, FALSE);
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BFS_VEGA(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _s;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------------------------------------------------
-- Implied Volatility with the Bisection Method
-- ---------------------------------------------------------------------------------------------------------------------

-- Black-Scholes-Merton (BSM)
CREATE OR REPLACE FUNCTION BSM_IVOL_BS(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _q FLOAT, _optPrc FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_functionError FLOAT;
	_volError FLOAT;
	_volLower FLOAT;
	_volUpper FLOAT;
	_volMid FLOAT;
BEGIN
	_functionError = 0.000001;
	_volError = 0.0001;
	_volLower = 0.0001;
	_volUpper = 9;
	_volMid = (_volUpper + _volLower) / 2;
	WHILE 
		ABS(BSM_PRICE(_type, _X, _K, _t, _r, _q, _volMid) - _optPrc) > _functionError 
		AND ABS(_volUpper - _volLower) > _volError
	LOOP
	IF (BSM_PRICE(_type, _X, _K, _t, _r, _q, _volMid) - _optPrc) >= 0 
		THEN _volUpper = _volMid;
		ELSE _volLower = _volMid;
	END IF;
	_volMid = (_volLower + _volUpper) / 2;
	END LOOP;
	RETURN _volMid;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BSM_IVOL_BS(%,%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _q, _optPrc;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Black-76 (B76)
CREATE OR REPLACE FUNCTION B76_IVOL_BS(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _optPrc FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_functionError FLOAT;
	_volError FLOAT;
	_volLower FLOAT;
	_volUpper FLOAT;
	_volMid FLOAT;
BEGIN
	_functionError = 0.000001;
	_volError = 0.0001;
	_volLower = 0.0001;
	_volUpper = 9;
	_volMid = (_volUpper + _volLower) / 2;
	WHILE 
		ABS(B76_PRICE(_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError 
		AND ABS(_volUpper - _volLower) > _volError
	LOOP
	IF (B76_PRICE(_type, _X, _K, _t, _r, _volMid) - _optPrc) >= 0 
		THEN _volUpper = _volMid;
		ELSE _volLower = _volMid;
	END IF;
	_volMid = (_volLower + _volUpper) / 2;
	END LOOP;
	RETURN _volMid;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for B76_IVOL_BS(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _optPrc;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Bachelier Futures Spread (BFS)
CREATE OR REPLACE FUNCTION BFS_IVOL_BS(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _optPrc FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_functionError FLOAT;
	_volError FLOAT;
	_volLower FLOAT;
	_volUpper FLOAT;
	_volMid FLOAT;
BEGIN
	_functionError = 0.000001;
	_volError = 0.01;
	_volLower = 0;
	_volUpper = 999;
	_volMid = (_volUpper + _volLower) / 2;
	WHILE 
		ABS(BFS_PRICE(_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError 
		AND ABS(_volUpper - _volLower) > _volError
	LOOP
	IF (BFS_PRICE(_type, _X, _K, _t, _r, _volMid) - _optPrc) >= 0 
		THEN _volUpper = _volMid;
		ELSE _volLower = _volMid;
	END IF;
	_volMid = (_volLower + _volUpper) / 2;
	END LOOP;
	RETURN _volMid;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BFS_IVOL_BS(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _optPrc;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------------------------------------------------
-- Implied Volatility with the Newton-Raphson Method
-- ---------------------------------------------------------------------------------------------------------------------

-- Black-Scholes-Merton (BSM) - development
CREATE OR REPLACE FUNCTION BSM_IVOL_NR(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _q FLOAT, _optPrc FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_functionError FLOAT;
	_ivol FLOAT;
	_ivolNext FLOAT;
BEGIN
	_functionError = 0.000001;
	_ivol = 0.001;
	WHILE 
		ABS(BSM_PRICE(_type, _X, _K, _t, _r, _q, _ivol) - _optPrc) > _functionError
	LOOP
		_ivolNext = ((_optPrc - BSM_PRICE(_type, _X, _K, _t, _r, _q, _ivol)) / BSM_VEGA(_type, _X, _K, _t, _r, _q, _ivol)) + _ivol;	
		_ivol = _ivolNext;
	END LOOP;
	RETURN _ivol;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BSM_IVOL_NR(%,%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _q, _optPrc;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Bachelier Futures Spread (BFS)
CREATE OR REPLACE FUNCTION BFS_IVOL_NR(_type TEXT, _X FLOAT, _K FLOAT, _t FLOAT, _r FLOAT, _optPrc FLOAT) RETURNS FLOAT
IMMUTABLE
AS $$
DECLARE
	_functionError FLOAT;
	_ivol FLOAT;
	_ivolNext FLOAT;
BEGIN
	_functionError = 0.000001;
	_ivol = 0.001;
	WHILE 
		ABS(BFS_PRICE(_type, _X, _K, _t, _r, _ivol) - _optPrc) > _functionError 
	LOOP
		_ivolNext = ((_optPrc - BFS_PRICE(_type, _X, _K, _t, _r, _ivol)) / BFS_VEGA(_type, _X, _K, _t, _r, _ivol)) + _ivol;	
		_ivol = _ivolNext;
	END LOOP;
	RETURN _ivol;
	EXCEPTION WHEN OTHERS THEN 
		RAISE NOTICE 'ERROR: % for BFS_IVOL_NR(%,%,%,%,%,%)',sqlerrm, _type, _X, _K, _t, _r, _optPrc;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;