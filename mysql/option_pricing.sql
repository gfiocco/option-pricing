-- ---------------------------------------------------------------------------------------------------------------------
-- Statistical Functions
-- ---------------------------------------------------------------------------------------------------------------------

-- Numerical approximations for the normal PDF and CDF
DROP FUNCTION IF EXISTS NORMSDIST;
DELIMITER $$
CREATE FUNCTION NORMSDIST(_x DOUBLE, _cumulative BOOLEAN) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _pdf DOUBLE;
		DECLARE _cdf DOUBLE;
		DECLARE _t DOUBLE;
		
		-- density of the standard normal distribution
		SET _pdf = (1/sqrt(2 * pi())) * exp(-power(_x,2)/2);

		IF _cumulative = FALSE 
		THEN
			RETURN _pdf;
		ELSE
			-- Zelen & Severo (1964) approximation of the cumulative distribution function of the standard normal distribution
			SET _t = 1/(1 + 0.2316419 * abs(_x));
			SET _cdf = 1 - _pdf * (0.31938153 * _t - 0.356563782 * power(_t,2) + 1.781477937 * power(_t,3) - 1.821255978 * power(_t,4) + 1.330274429 * power(_t,5));
			IF _x > 0
				THEN RETURN _cdf;
				ELSE RETURN 1 - _cdf;
			END IF;
		END IF;

	END;
	$$
DELIMITER ;

-- ---------------------------------------------------------------------------------------------------------------------
-- Black-Scholes-Merton (BSM)
-- ---------------------------------------------------------------------------------------------------------------------

-- price
DROP FUNCTION IF EXISTS BSM_PRICE;
DELIMITER $$
CREATE FUNCTION BSM_PRICE(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _q DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;
		DECLARE _d2 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
		SET _d2 = _d1 - _s * sqrt(_t);

		IF _type = 'CALL'
			THEN RETURN exp(-_q*_t) * NORMSDIST(_d1, TRUE) * _X - exp(-_r*_t) * NORMSDIST(_d2, TRUE) * _K;
			ELSE RETURN exp(-_r*_t) * NORMSDIST(-_d2, TRUE) * _K - exp(-_q*_t) * NORMSDIST(-_d1, TRUE) * _X;
		END IF;

	END;
	$$
DELIMITER ;

-- delta
DROP FUNCTION IF EXISTS BSM_DELTA;
DELIMITER $$
CREATE FUNCTION BSM_DELTA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _q DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;
		DECLARE _d2 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
		SET _d2 = _d1 - _s * sqrt(_t);

		IF _type = 'CALL'
			THEN RETURN exp(-_q*_t) * NORMSDIST(_d1, TRUE);
			ELSE RETURN exp(-_q*_t) * (NORMSDIST(_d1, TRUE)-1);
		END IF;

	END;
	$$
DELIMITER ;

-- gamma
DROP FUNCTION IF EXISTS BSM_GAMMA;
DELIMITER $$
CREATE FUNCTION BSM_GAMMA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _q DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));

		RETURN ((exp(-_q*_t)/(_X*_s*sqrt(_t)))) * ((1/sqrt(2*pi()))) * (exp(-power(_d1,2)/2));

	END;
	$$
DELIMITER ;

-- rho
DROP FUNCTION IF EXISTS BSM_RHO;
DELIMITER $$
CREATE FUNCTION BSM_RHO(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _q DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;
		DECLARE _d2 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
		SET _d2 = _d1 - _s * sqrt(_t);

		IF _type = 'CALL'
			THEN RETURN (1/100) * (_K*_t*exp(-_r*_t)) * NORMSDIST(_d2, TRUE);
			ELSE RETURN (-1/100) * (_K*_t*exp(-_r*_t)) * NORMSDIST(-_d2, TRUE);
		END IF;

	END;
	$$
DELIMITER ;

-- theta
DROP FUNCTION IF EXISTS BSM_THETA;
DELIMITER $$
CREATE FUNCTION BSM_THETA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _q DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;
		DECLARE _d2 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));
		SET _d2 = _d1 - _s * sqrt(_t);

		IF _type = 'CALL'
			THEN RETURN (1/360) * ( -(((_X*_s*exp(-_q*_t))/(2*sqrt(_t)))*(1/sqrt(2*pi()))*exp(-(power(_d1,2))/2)) -(_r*_K*exp(-_r*_t)*NORMSDIST(_d2, TRUE)) +(_q*_X*exp(-_q*_t)*NORMSDIST(_d1, TRUE)) );
			ELSE RETURN (1/360) * ( -(((_X*_s*exp(-_q*_t))/(2*sqrt(_t)))*(1/sqrt(2*pi()))*exp(-(power(_d1,2))/2)) +(_r*_K*exp(-_r*_t)*NORMSDIST(-_d2, TRUE)) -(_q*_X*exp(-_q*_t)*NORMSDIST(-_d1, TRUE)) );
		END IF;

	END;
	$$
DELIMITER ;

-- vega
DROP FUNCTION IF EXISTS BSM_VEGA;
DELIMITER $$
CREATE FUNCTION BSM_VEGA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _q DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (_r - _q + power(_s,2)/2) * _t) / (_s * sqrt(_t));

		RETURN (1/100) * (_X * exp(-_q*_t) * sqrt(_t)) * (1/sqrt(2*pi())) * exp(-power(_d1,2)/2);

	END;
	$$
DELIMITER ;

-- ---------------------------------------------------------------------------------------------------------------------
-- Black-76 (B76)
-- ---------------------------------------------------------------------------------------------------------------------

-- price
DROP FUNCTION IF EXISTS B76_PRICE;
DELIMITER $$
CREATE FUNCTION B76_PRICE(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;
		DECLARE _d2 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
		SET _d2 = _d1 - _s * sqrt(_t);

		IF _type = 'CALL'
			THEN RETURN exp(-_r*_t) * (NORMSDIST(_d1, TRUE) * _X - NORMSDIST(_d2, TRUE) * _K);
			ELSE RETURN exp(-_r*_t) * (NORMSDIST(-_d2, TRUE) * _K - NORMSDIST(-_d1, TRUE) * _X);
		END IF;

	END;
	$$
DELIMITER ;

-- delta
DROP FUNCTION IF EXISTS B76_DELTA;
DELIMITER $$
CREATE FUNCTION B76_DELTA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;
		DECLARE _d2 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
		SET _d2 = _d1 - _s * sqrt(_t);

		IF _type = 'CALL'
			THEN RETURN exp(-_r*_t) * NORMSDIST(_d1, TRUE);
			ELSE RETURN exp(-_r*_t) * (NORMSDIST(_d1, TRUE)-1);
		END IF;

	END;
	$$
DELIMITER ;

-- gamma
DROP FUNCTION IF EXISTS B76_GAMMA;
DELIMITER $$
CREATE FUNCTION B76_GAMMA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));

		RETURN ((exp(-_r*_t)/(_X*_s*sqrt(_t)))) * ((1/sqrt(2*pi()))) * (exp(-power(_d1,2)/2));

	END;
	$$
DELIMITER ;

-- rho
DROP FUNCTION IF EXISTS B76_RHO;
DELIMITER $$
CREATE FUNCTION B76_RHO(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;
		DECLARE _d2 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
		SET _d2 = _d1 - _s * sqrt(_t);

		IF _type = 'CALL'
			THEN RETURN (1/100) * (_K*_t*exp(-_r*_t)) * NORMSDIST(_d2, TRUE);
			ELSE RETURN (-1/100) * (_K*_t*exp(-_r*_t)) * NORMSDIST(-_d2, TRUE);
		END IF;

	END;
	$$
DELIMITER ;

-- theta
DROP FUNCTION IF EXISTS B76_THETA;
DELIMITER $$
CREATE FUNCTION B76_THETA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;
		DECLARE _d2 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));
		SET _d2 = _d1 - _s * sqrt(_t);

		IF _type = 'CALL'
			THEN RETURN (1/360) * ( -(((_X*_s*exp(-_r*_t))/(2*sqrt(_t)))*(1/sqrt(2*pi()))*exp(-(power(_d1,2))/2)) -(_r*_K*exp(-_r*_t)*NORMSDIST(_d2, TRUE)) +(_r*_X*exp(-_r*_t)*NORMSDIST(_d1, TRUE)) );
			ELSE RETURN (1/360) * ( -(((_X*_s*exp(-_r*_t))/(2*sqrt(_t)))*(1/sqrt(2*pi()))*exp(-(power(_d1,2))/2)) +(_r*_K*exp(-_r*_t)*NORMSDIST(-_d2, TRUE)) -(_r*_X*exp(-_r*_t)*NORMSDIST(-_d1, TRUE)) );
		END IF;

	END;
	$$
DELIMITER ;

-- vega
DROP FUNCTION IF EXISTS B76_VEGA;
DELIMITER $$
CREATE FUNCTION B76_VEGA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d1 DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d1 = (ln(_X/_K) + (power(_s,2)/2)*_t) / (_s * sqrt(_t));

		RETURN (1/100) * (_X * exp(-_r*_t) * sqrt(_t)) * (1/sqrt(2*pi())) * exp(-power(_d1,2)/2);

	END;
	$$
DELIMITER ;

-- ---------------------------------------------------------------------------------------------------------------------
-- Bachelier Futures Spread (BFS)
-- ---------------------------------------------------------------------------------------------------------------------

-- price
DROP FUNCTION IF EXISTS BFS_PRICE;
DELIMITER $$
CREATE FUNCTION BFS_PRICE(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d = (_X - _K) / (_s * sqrt(_t));

		IF _type = 'CALL'
			THEN RETURN exp(-_r*_t) * (NORMSDIST(_d, TRUE) * (_X - _K) + NORMSDIST(_d, FALSE) * (_s * sqrt(_t)));
			ELSE RETURN exp(-_r*_t) * (NORMSDIST(-_d, TRUE) * (_K - _X) + NORMSDIST(_d, FALSE) * (_s * sqrt(_t)));
		END IF;

	END;
	$$
DELIMITER ;

-- delta
DROP FUNCTION IF EXISTS BFS_DELTA;
DELIMITER $$
CREATE FUNCTION BFS_DELTA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d = (_X - _K) / (_s * sqrt(_t));

		IF _type = 'CALL'
			THEN RETURN exp(-_r*_t) * NORMSDIST(_d, TRUE);
			ELSE RETURN -exp(-_r*_t) * NORMSDIST(-_d, TRUE);
		END IF;

	END;
	$$
DELIMITER ;

-- gamma
DROP FUNCTION IF EXISTS BFS_GAMMA;
DELIMITER $$
CREATE FUNCTION BFS_GAMMA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d = (_X - _K) / (_s * sqrt(_t));

		RETURN exp(-_r*_t) * NORMSDIST(_d, FALSE) / (_s * sqrt(_t));

	END;
	$$
DELIMITER ;

-- rho
DROP FUNCTION IF EXISTS BFS_RHO;
DELIMITER $$
CREATE FUNCTION BFS_RHO(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d = (_X - _K) / (_s * sqrt(_t));

		IF _type = 'CALL'
			THEN RETURN -_t * exp(-_r*_t) * (NORMSDIST(_d, TRUE) * (_X - _K) + NORMSDIST(_d, FALSE) * (_s * sqrt(_t)));
			ELSE RETURN -_t * exp(-_r*_t) * (NORMSDIST(-_d, TRUE) * (_K - _X) + NORMSDIST(_d, FALSE) * (_s * sqrt(_t)));
		END IF;

	END;
	$$
DELIMITER ;

-- theta
DROP FUNCTION IF EXISTS BFS_THETA;
DELIMITER $$
CREATE FUNCTION BFS_THETA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d = (_X - _K) / (_s * sqrt(_t));

		IF _type = 'CALL'
			THEN RETURN -(1/360) * (-_r * exp(-_r*_t) * (NORMSDIST(_d, TRUE)*(_X - _K) + NORMSDIST(_d, FALSE)*(_s * sqrt(_t))) + (exp(-_r*_t) * _s * NORMSDIST(_d, FALSE)) / (2 * sqrt(_t)));
			ELSE RETURN -(1/360) * (-_r * exp(-_r*_t) * (NORMSDIST(-_d, TRUE)*(_K - _X) + NORMSDIST(_d, FALSE)*(_s * sqrt(_t))) +  (exp(-_r*_t) * _s * NORMSDIST(_d, FALSE)) / (2 * sqrt(_t)) - 2 * _r * exp(-_r*_t) * (_X - _K));
		END IF;

	END;
	$$
DELIMITER ;

-- vega
DROP FUNCTION IF EXISTS BFS_VEGA;
DELIMITER $$
CREATE FUNCTION BFS_VEGA(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _s DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _d DOUBLE;

		-- throw error if type is not CALL or PUT
		IF _type NOT IN ('CALL','PUT') 
			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contract type has to be either CALL or PUT';
		END IF;

		SET _d = (_X - _K) / (_s * sqrt(_t));

		RETURN exp(-_r*_t) * sqrt(_t) * NORMSDIST(_d, FALSE);

	END;
	$$
DELIMITER ;

-- ---------------------------------------------------------------------------------------------------------------------
-- Implied Volatility with the Bisection Method
-- ---------------------------------------------------------------------------------------------------------------------

-- Black-Scholes-Merton (BSM)
DROP FUNCTION IF EXISTS BSM_IVOL;
DELIMITER $$
CREATE FUNCTION BSM_IVOL(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _q DOUBLE, _optPrc DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _functionError DOUBLE;
		DECLARE _volError DOUBLE;
		DECLARE _volLower DOUBLE;
		DECLARE _volUpper DOUBLE;
		DECLARE _volMid DOUBLE;

		SET _functionError = 0.000001;
		SET _volError = 0.0001;
		SET _volLower = 0.0001;
		SET _volUpper = 9;
		
		SET _volMid = (_volUpper + _volLower) / 2;
		
		
		WHILE 
			ABS(BSM_PRICE(_type, _X, _K, _t, _r, _q, _volMid) - _optPrc) > _functionError 
			AND ABS(_volUpper - _volLower) > _volError
		DO

		IF (BSM_PRICE(_type, _X, _K, _t, _r, _q, _volMid) - _optPrc) >= 0 
			THEN SET _volUpper = _volMid;
			ELSE SET _volLower = _volMid;
		END IF;
		
		SET _volMid = (_volLower + _volUpper) / 2;
		
		END WHILE;
		
		RETURN _volMid;

	END;
	$$
DELIMITER ;

-- Black-76 (B76)
DROP FUNCTION IF EXISTS B76_IVOL;
DELIMITER $$
CREATE FUNCTION B76_IVOL(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _optPrc DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _functionError DOUBLE;
		DECLARE _volError DOUBLE;
		DECLARE _volLower DOUBLE;
		DECLARE _volUpper DOUBLE;
		DECLARE _volMid DOUBLE;

		SET _functionError = 0.000001;
		SET _volError = 0.0001;
		SET _volLower = 0.0001;
		SET _volUpper = 9;
		
		SET _volMid = (_volUpper + _volLower) / 2;
		
		WHILE 
			ABS(B76_PRICE(_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError 
			AND ABS(_volUpper - _volLower) > _volError
		DO

		IF (B76_PRICE(_type, _X, _K, _t, _r, _volMid) - _optPrc) >= 0 
			THEN SET _volUpper = _volMid;
			ELSE SET _volLower = _volMid;
		END IF;
		
		SET _volMid = (_volLower + _volUpper) / 2;
		
		END WHILE;
		
		RETURN _volMid;

	END;
	$$
DELIMITER ;

-- Bachelier Futures Spread (BFS)
DROP FUNCTION IF EXISTS BFS_IVOL;
DELIMITER $$
CREATE FUNCTION BFS_IVOL(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _optPrc DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _functionError DOUBLE;
		DECLARE _volError DOUBLE;
		DECLARE _volLower DOUBLE;
		DECLARE _volUpper DOUBLE;
		DECLARE _volMid DOUBLE;

		SET _functionError = 0.000001;
		SET _volError = 0.01;
		SET _volLower = 0;
		SET _volUpper = 999;
		
		SET _volMid = (_volUpper + _volLower) / 2;
		
		WHILE 
			ABS(BFS_PRICE(_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError 
			AND ABS(_volUpper - _volLower) > _volError
		DO

		IF (BFS_PRICE(_type, _X, _K, _t, _r, _volMid) - _optPrc) >= 0 
			THEN SET _volUpper = _volMid;
			ELSE SET _volLower = _volMid;
		END IF;
		
		SET _volMid = (_volLower + _volUpper) / 2;
		
		END WHILE;
		
		RETURN _volMid;

	END;
	$$
DELIMITER ;

-- ---------------------------------------------------------------------------------------------------------------------
-- Implied Volatility with the Newton-Raphson Method
-- ---------------------------------------------------------------------------------------------------------------------

-- Black-Scholes-Merton (BSM) - development
DROP FUNCTION IF EXISTS BSM_IVOL_NR;
DELIMITER $$
CREATE FUNCTION BSM_IVOL_NR(_type TEXT, _X DOUBLE, _K DOUBLE, _t DOUBLE, _r DOUBLE, _q DOUBLE, _optPrc DOUBLE) RETURNS DOUBLE 
	DETERMINISTIC
	BEGIN

		DECLARE _functionError DOUBLE;
		DECLARE _ivol DOUBLE;
		DECLARE _ivolNext DOUBLE;

		SET _functionError = 0.000001;
		SET _ivol = 0.001;

		WHILE 
			ABS(BSM_PRICE(_type, _X, _K, _t, _r, _q, _ivol) - _optPrc) > _functionError
		DO

			SET _ivolNext = ((_optPrc - BSM_PRICE(_type, _X, _K, _t, _r, _q, _ivol)) / BSM_VEGA(_type, _X, _K, _t, _r, _q, _ivol)) + _ivol;
			
			SET _ivol = _ivolNext;
		
		END WHILE;
		
		RETURN _ivol;

	END;
	$$
DELIMITER ;