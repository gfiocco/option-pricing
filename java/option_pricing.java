// Numerical approximations for the normal PDF and CDF
public static double normsdist(Double _x, boolean _cumulative) {
    double _pdf, _cdf, _t;
    // density of the standard normal distribution
    _pdf = ( 1 / Math.sqrt(2 * Math.PI) * Math.exp(-Math.pow(_x,2)/2) );
    if(!_cumulative){
        return _pdf;
    }
    else {
        // Zelen & Severo (1964) approximation of the cumulative distribution function of the standard normal distribution
        _t = 1/(1 + 0.2316419 * Math.abs(_x));
        _cdf = 1 - _pdf * (0.31938153 * _t - 0.356563782 * Math.pow(_t,2) + 1.781477937 * Math.pow(_t,3) - 1.821255978 * Math.pow(_t,4) + 1.330274429 * Math.pow(_t,5));
        if(_x > 0){
            return _cdf;
        }
        else{
            return 1 - _cdf;
        }
    }
}

// Black-Scholes-Merton (BSM) - Price
public static double bsm_price (String _type, double _X, double _K, double _t, double _r, double _q, double _s) {
    double _d1, _d2;
    _d1 = (Math.log(_X/_K) + (_r - _q + Math.pow(_s,2)/2) * _t) / (_s * Math.sqrt(_t));
    _d2 = _d1 - _s * Math.sqrt(_t);
    if(_type.equals("C")){
            return Math.exp(-_q*_t) * normsdist(_d1, true) * _X - Math.exp(-_r*_t) * normsdist(_d2, true) * _K;
    }
    else {
            return Math.exp(-_r * _t) * normsdist(-_d2, true) * _K - Math.exp(-_q*_t) * normsdist(-_d1, true) * _X;
    }
}

// Black-76 (B76) - Price
public static double b76_price (String _type, double _X, double _K, double _t, double _r, double _s) {
    double _d1, _d2;
    _d1 = (Math.log(_X/_K) + (Math.pow(_s,2)/2)*_t) / (_s * Math.sqrt(_t));
    _d2 = _d1 - _s * Math.sqrt(_t);
    if(_type.equals("C")){
            return Math.exp(-_r*_t) * (normsdist(_d1, true) * _X - normsdist(_d2, true) * _K);
    }
    else {
            return Math.exp(-_r*_t) * (normsdist(-_d2, true) * _K - normsdist(-_d1, true) * _X);
    }
}

// Bachelier Futures Spread (BFS) - Price
public static double bfs_price (String _type, double _X, double _K, double _t, double _r, double _s) {
    double _d;
    _d = (_X - _K) / (_s * Math.sqrt(_t));
    if(_type.equals("C")){
            return Math.exp(-_r*_t) * (normsdist(_d, true) * (_X - _K) + normsdist(_d, false) * (_s * Math.sqrt(_t)));
    }
    else {
            return Math.exp(-_r*_t) * (normsdist(-_d, true) * (_K - _X) + normsdist(_d, false) * (_s * Math.sqrt(_t)));
    }
}

// Black-Scholes-Merton (BSM) - Implied Volatility
public static double bsm_ivol (String _type, double _X, double _K, double _t, double _r, double _q, double _optPrc) {
    double _functionError = 0.000001;
    double _volError = 0.0001;
    double _volLower = 0.0001;
    double _volUpper = 9.0;
    double _volMid = (_volUpper + _volLower) / 2;
    while(Math.abs(bsm_price(_type, _X, _K, _t, _r, _q, _volMid) - _optPrc) > _functionError && Math.abs(_volUpper - _volLower) > _volError) {
        if (bsm_price(_type, _X, _K, _t, _r, _q, _volMid) - _optPrc >= 0) {
            _volUpper = _volMid;
        }
        else {
            _volLower = _volMid;
        }
        _volMid = (_volLower + _volUpper) / 2;
    }
    return _volMid;
}

// Black-76 (B76) - Implied Volatility
public static double b76_ivol (String _type, double _X, double _K, double _t, double _r, double _optPrc) {
    double _functionError = 0.000001;
    double _volError = 0.0001;
    double _volLower = 0.0001;
    double _volUpper = 9.0;
    double _volMid = (_volUpper + _volLower) / 2;
    while(Math.abs(b76_price(_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError && Math.abs(_volUpper - _volLower) > _volError) {
        if (b76_price(_type, _X, _K, _t, _r, _volMid) - _optPrc >= 0) {
            _volUpper = _volMid;
        }
        else {
            _volLower = _volMid;
        }
        _volMid = (_volLower + _volUpper) / 2;
    }
    return _volMid;
}

// Bachelier Futures Spread (BFS) - Implied Volatility
public static double bfs_ivol (String _type, double _X, double _K, double _t, double _r, double _optPrc) {
    double _functionError = 0.000001;
    double _volError = 0.01;
    double _volLower = 0.01;
    double _volUpper = 999;
    double _volMid = (_volUpper + _volLower) / 2;
    while(Math.abs(bfs_price(_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError && Math.abs(_volUpper - _volLower) > _volError) {
        if (bfs_price(_type, _X, _K, _t, _r, _volMid) - _optPrc >= 0) {
            _volUpper = _volMid;
        }
        else {
            _volLower = _volMid;
        }
        _volMid = (_volLower + _volUpper) / 2;
    }
    return _volMid;
}

// ---------------------------------------------------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------------------------------------------------

double X = 50;
double K = 50;
double t = 1;
double r = 0.01;
double q = 0.01;
double s = 0.2;
String type = "C";
double price = 3.9431602019637353;

double bsm_prc = bsm_price(type, X, K, t, r, q, s); // 3.9431602019637353
double b76_prc = b76_price(type, X, K, t, r, s);    // 3.9431602019637397
double bfs_prc = bfs_price(type, X, K, t, r, s);    // 3.9497273838695244

double bsm_ivol = bsm_ivol(type, X, K, t, r, q, price); // 0.2000146183013916
double b76_ivol = b76_ivol(type, X, K, t, r, price);    // 0.2000146183013916
double bfs_ivol = bfs_ivol(type, X, K, t, r, price);    // 0.1996712993621826