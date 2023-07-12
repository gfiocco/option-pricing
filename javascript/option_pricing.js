// Numerical approximations for the normal PDF and CDF
function normsdist(_x, _cumulative) {
    let _pdf, _cdf, _t
    // density of the standard normal distribution
    _pdf = (1 / Math.sqrt(2 * Math.PI)) * Math.exp(-Math.pow(_x, 2) / 2)
    if (!_cumulative) {
        return _pdf
    } else {
        // Zelen & Severo (1964) approximation of the cumulative distribution function of the standard normal distribution
        _t = 1 / (1 + 0.2316419 * Math.abs(_x))
        _cdf =
            1 -
            _pdf *
                (0.31938153 * _t -
                    0.356563782 * Math.pow(_t, 2) +
                    1.781477937 * Math.pow(_t, 3) -
                    1.821255978 * Math.pow(_t, 4) +
                    1.330274429 * Math.pow(_t, 5))
        if (_x > 0) {
            return _cdf
        } else {
            return 1 - _cdf
        }
    }
}

// Black-Scholes-Merton (BSM) - Price
function bsm_price(_type, _X, _K, _t, _r, _q, _s) {
    let _d1, _d2
    _d1 = (Math.log(_X / _K) + (_r - _q + Math.pow(_s, 2) / 2) * _t) / (_s * Math.sqrt(_t))
    _d2 = _d1 - _s * Math.sqrt(_t)
    if (_type == 'C') {
        return Math.exp(-_q * _t) * normsdist(_d1, true) * _X - Math.exp(-_r * _t) * normsdist(_d2, true) * _K
    } else {
        return Math.exp(-_r * _t) * normsdist(-_d2, true) * _K - Math.exp(-_q * _t) * normsdist(-_d1, true) * _X
    }
}

// Black-76 (B76) - Price
function b76_price(_type, _X, _K, _t, _r, _s) {
    let _d1, _d2
    _d1 = (Math.log(_X / _K) + (Math.pow(_s, 2) / 2) * _t) / (_s * Math.sqrt(_t))
    _d2 = _d1 - _s * Math.sqrt(_t)
    if (_type == 'C') {
        return Math.exp(-_r * _t) * (normsdist(_d1, true) * _X - normsdist(_d2, true) * _K)
    } else {
        return Math.exp(-_r * _t) * (normsdist(-_d2, true) * _K - normsdist(-_d1, true) * _X)
    }
}

// Bachelier Futures Spread (BFS) - Price
function bfs_price(_type, _X, _K, _t, _r, _s) {
    let _d
    _d = (_X - _K) / (_s * Math.sqrt(_t))
    if (_type == 'C') {
        return Math.exp(-_r * _t) * (normsdist(_d, true) * (_X - _K) + normsdist(_d, false) * (_s * Math.sqrt(_t)))
    } else {
        return Math.exp(-_r * _t) * (normsdist(-_d, true) * (_K - _X) + normsdist(_d, false) * (_s * Math.sqrt(_t)))
    }
}

// Binomial Tree (BT) - Price
const bt_price = (_type, _X, _K, _t, _r, _s, _n) => {
    let dt = _t / _n
    let u = Math.exp(_s * Math.sqrt(dt))
    let d = 1 / u
    let p = (Math.exp(_r * dt) - d) / (u - d)
    let priceTree = new Array(_n + 1)
    for (let i = 0; i < priceTree.length; i++) {
        priceTree[i] = new Array(i + 1)
    }
    for (let i = 0; i <= _n; i++) {
        for (let j = 0; j <= i; j++) {
            priceTree[j][i] = _X * Math.pow(u, j) * Math.pow(d, i - j)
        }
    }
    let optionTree = new Array(_n + 1)
    for (let i = 0; i < optionTree.length; i++) {
        optionTree[i] = new Array(i + 1)
    }
    for (let j = 0; j <= _n; j++) {
        optionTree[j][_n] = Math.max(0, (_type === 'C' ? 1 : -1) * (priceTree[j][_n] - _K))
    }
    for (let i = _n - 1; i >= 0; i--) {
        for (let j = 0; j <= i; j++) {
            optionTree[j][i] = Math.exp(-_r * dt) * (p * optionTree[j + 1][i + 1] + (1 - p) * optionTree[j][i + 1])
        }
    }
    return optionTree[0][0]
}

// Black-Scholes-Merton (BSM) - Implied Volatility
function bsm_ivol(_type, _X, _K, _t, _r, _q, _optPrc) {
    let _functionError = 0.000001
    let _volError = 0.0001
    let _volLower = 0.0001
    let _volUpper = 9.0
    let _volMid = (_volUpper + _volLower) / 2
    while (
        Math.abs(bsm_price(_type, _X, _K, _t, _r, _q, _volMid) - _optPrc) > _functionError &&
        Math.abs(_volUpper - _volLower) > _volError
    ) {
        if (bsm_price(_type, _X, _K, _t, _r, _q, _volMid) - _optPrc >= 0) {
            _volUpper = _volMid
        } else {
            _volLower = _volMid
        }
        _volMid = (_volLower + _volUpper) / 2
    }
    return _volMid
}

// Black-76 (B76) - Implied Volatility
function b76_ivol(_type, _X, _K, _t, _r, _optPrc) {
    let _functionError = 0.000001
    let _volError = 0.0001
    let _volLower = 0.0001
    let _volUpper = 9.0
    let _volMid = (_volUpper + _volLower) / 2
    while (
        Math.abs(b76_price(_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError &&
        Math.abs(_volUpper - _volLower) > _volError
    ) {
        if (b76_price(_type, _X, _K, _t, _r, _volMid) - _optPrc >= 0) {
            _volUpper = _volMid
        } else {
            _volLower = _volMid
        }
        _volMid = (_volLower + _volUpper) / 2
    }
    return _volMid
}

// Bachelier Futures Spread (BFS) - Implied Volatility
function bfs_ivol(_type, _X, _K, _t, _r, _optPrc) {
    let _functionError = 0.000001
    let _volError = 0.01
    let _volLower = 0.01
    let _volUpper = 999
    let _volMid = (_volUpper + _volLower) / 2
    while (
        Math.abs(bfs_price(_type, _X, _K, _t, _r, _volMid) - _optPrc) > _functionError &&
        Math.abs(_volUpper - _volLower) > _volError
    ) {
        if (bfs_price(_type, _X, _K, _t, _r, _volMid) - _optPrc >= 0) {
            _volUpper = _volMid
        } else {
            _volLower = _volMid
        }
        _volMid = (_volLower + _volUpper) / 2
    }
    return _volMid
}

// ---------------------------------------------------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------------------------------------------------

let X = 50
let K = 50
let t = 1
let r = 0.01
let q = 0.01
let s = 0.2
let type = 'C'
let price = 3.9431602019637353

console.log(bsm_price(type, X, K, t, r, q, s)) // 3.9431602019637353
console.log(b76_price(type, X, K, t, r, s)) // 3.9431602019637397
console.log(bfs_price(type, X, K, t, r, s * X)) // 3.9497273838695244
console.log(bt_price(type, X, K, t, r, s, 1000)) // 4.215667518047203

console.log(bsm_ivol(type, X, K, t, r, q, price)) // 0.2000146183013916
console.log(b76_ivol(type, X, K, t, r, price)) // 0.2000146183013916
console.log(bfs_ivol(type, X, K, t, r, price) / X) // 0.1996712993621826
