import math

# Numerical approximations for the normal PDF and CDF
def normsdist(_x, _cumulative):
	# prevent underflow/overfow
	if _x < -10:
		return 0
	if _x > 10:
		return 1
	# density of the standard normal distribution
	_pdf = (1/math.sqrt(2 * math.pi)) * math.exp(-math.pow(_x, 2)/2)
	if _cumulative == False:
		return _pdf
	# Zelen & Severo(1964) approximation of the cumulative distribution function of the standard normal distribution
	_t = 1/(1 + 0.2316419 * abs(_x))
	_cdf = 1 - _pdf * (0.31938153 * _t - 0.356563782 * math.pow(_t, 2) + 1.781477937 *
	                   math.pow(_t, 3) - 1.821255978 * math.pow(_t, 4) + 1.330274429 * math.pow(_t, 5))
	if _x > 0:
		return _cdf
	else:
		return 1 - _cdf

# Black-Scholes-Merton (BSM) - price
def bsm_price(_opttyp, _X, _K, _t, _r, _s, _q):
	_d1 = (math.log(_X/_K) + (_r - _q + pow(_s, 2)/2) * _t) / (_s * math.sqrt(_t))
	_d2 = _d1 - _s * math.sqrt(_t)
	if _opttyp == "C":
		return math.exp(-_q*_t) * normsdist(_d1, True) * _X - math.exp(-_r*_t) * normsdist(_d2, True) * _K
	else:
		return math.exp(-_r*_t) * normsdist(-_d2, True) * _K - math.exp(-_q*_t) * normsdist(-_d1, True) * _X

# Black-Scholes-Merton (BSM) - rho
def bsm_rho(_opttyp, _X, _K, _t, _r, _s, _q):
	_d1 = (math.log(_X/_K) + (_r - _q + pow(_s, 2)/2) * _t) / (_s * math.sqrt(_t))
	_d2 = _d1 - _s * math.sqrt(_t)
	if _opttyp == "C":
		return (1/100) * (_K * _t * math.exp(-_r*_t)) * normsdist(_d2, True)
	else:
		return (-1/100) * (_K * _t * math.exp(-_r*_t)) * normsdist(-_d2, True)

# Black 76
def b76_price(_opttyp, _X, _K, _t, _r, _s):
	_d1 = (math.log(_X/_K) + (pow(_s, 2)/2)*_t) / (_s * math.sqrt(_t))
	_d2 = _d1 - _s * math.sqrt(_t)
	if _opttyp == "C":
		return math.exp(-_r*_t) * (normsdist(_d1, True) * _X - normsdist(_d2, True) * _K)
	else:
		return math.exp(-_r*_t) * (normsdist(-_d2, True) * _K - normsdist(-_d1, True) * _X)

# Black 76 - Implied Volatility with Bisection Method
def b76_ivol_bisection(_opt_type, _X, _K, _t, _r, _optPrc):
	_functionError = 1e-10
	_volError = 1e-10
	_volLower = 0.01
	_volUpper = 999
	_volMid = (_volUpper + _volLower) / 2
	_counter = 0
	while abs(b76_price(_opt_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError and abs(_volUpper - _volLower) > _volError:
		_counter = _counter + 1
		# print(_counter," - ",_volMid)
		if (b76_price(_opt_type, _X, _K, _t, _r, _volMid) - _optPrc >= 0):
			_volUpper = _volMid
		else:
			_volLower = _volMid
		_volMid = (_volLower + _volUpper) / 2
	return _volMid

# Bachelier Futures Spread (BFS) - optprc
def bfs_price(_opttyp, _X, _K, _t, _r, _s):
	_d = (_X - _K) / (_s * math.sqrt(_t))
	if _opttyp == "C":
		return math.exp(-_r*_t) * (normsdist(_d, True) * (_X - _K) + normsdist(_d, False) * (_s * math.sqrt(_t)))
	else:
		return math.exp(-_r*_t) * (normsdist(-_d, True) * (_K - _X) + normsdist(_d, False) * (_s * math.sqrt(_t)))

# Bachelier Futures Spread (BFS) - Implied Volatility with Bisection Method
def bfs_ivol_bisection(_opt_type, _X, _K, _t, _r, _optPrc):
	_functionError = 1e-10
	_volError = 1e-10
	_volLower = 0.01
	_volUpper = 999
	_volMid = (_volUpper + _volLower) / 2
	_counter = 0
	while abs(bfs_price(_opt_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError and abs(_volUpper - _volLower) > _volError:
		_counter = _counter + 1
		# print(_counter," - ",_volMid)
		if (bfs_price(_opt_type, _X, _K, _t, _r, _volMid) - _optPrc >= 0):
			_volUpper = _volMid
		else:
			_volLower = _volMid
		_volMid = (_volLower + _volUpper) / 2
	return _volMid

# Bachelier Futures Spread (BFS) - Vega
def bfs_vega(_X, _K, _t, _r, _s):
	_d = (_X - _K) / (_s * math.sqrt(_t))
	return math.exp(-_r*_t) * math.sqrt(_t) * normsdist(_d, False)

# Bachelier Futures Spread (BFS) - Implied Volatility with Newton–Raphson method,
def bfs_ivol_newton(_opttyp, _X, _K, _t, _r, _optPrc):
	_s = math.sqrt(2*math.pi/_t)*_X/_K
	_counter = 0
	for i in range(10):
		_counter = _counter + 1
		# print(_counter," - ",_s)
		_optPrc0 = bfs_price(_opttyp, _X, _K, _t, _r, _s)
		_s = _s - (_optPrc0 - _optPrc)/bfs_vega(_X, _K, _t, _r, _s)
		if abs(_optPrc0 - _optPrc) < 1e-10:
			break
	return _s

# ----------------------------------------------------------------------------------------------------------------------
# Validation
# ----------------------------------------------------------------------------------------------------------------------

uprc = 50
strike = 50
ttm = 1
frr = 0.01
ivol = 0.2
opttyp = "C"
optprc = 3.9431602019637353

# 3.9497273838695244
print(bfs_price(opttyp, uprc, strike, ttm, frr, ivol*uprc))
# 9.98337307524176 (36 iterations)
print(bfs_ivol_bisection(opttyp, uprc, strike, ttm, frr, optprc))
# 9.983373075487162 (2 iteration)
print(bfs_ivol_newton(opttyp, uprc, strike, ttm, frr, optprc))
# 0.39497273838695246
bfs_vega(uprc, strike, ttm, frr, ivol)


# 3.9497273838695244
print(b76_price(opttyp, uprc, strike, ttm, frr, ivol))
# 0.19999999999499432
print(b76_ivol_bisection(opttyp, uprc, strike, ttm, frr, optprc))
