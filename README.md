# CCPs Quantitative Option Pricing

The scope of this repository is to provide a library in different programming languages of the option pricing formulas currently being used by most of the global derivatives central counterparty clearing houses (CCPs).

## Some history before getting started

In 1900, Louis Bachelier thesis, _Theory of Speculation_, pioneered the idea of using Brownian motion to price European-style options. The nature of Bachelier's work was not recognised for decades because of the scepticism around the use of mathematics to model the stock market at the time.

In 1973, _The Pricing of Options and Corporate Liabilities_ by Fisher Black and Myron Scholes, introduced the Black-Scholes (BS) model. Almost at the same time, the _Theory of Rational Option Pricing_ by Robert Merton presented an extension to the BS model accounting for dividends, this widely used extension is known as the Black-Scholes-Merton (BSM) model.

In 1976, Fisher Black proposed a way to apply the Black-Scholes model to European-style options on forwards and futures in _The Pricing of Commodity Contracts_. In essence, the Black 1976 (B76) model is the same as the BSM model applied on a stock that pays dividends at a rate equal to the free risk rate (note that the initial investment in any forward or future contract is zero).

For the past 40 years, numbers of financial mathematicians have been expanding and improving this field of quantitative finance. However, from this point in time, much of the effort has concentrated on the development of newer and better numerical methods for the pricing of more complex options.

## Formulas

CCPs use option pricing formulas to calculate their clearing members' intraday P&L, stress tests and margin requirements. In order words, CCPs are generally more interested in capturing the change in the value of an option contract instead of the price alone. Therefore, it is common for CCPs to use European-style options pricing formulas to price American-style options or other exotic options. The price between these types of options can be significantly different; however, the rate of change in the value is very similar in magnitude, especially in the contest of a clearing member portfolio.

The benefit of using a closed-form solution formula exceeds the more accurate results that can be achieved by a numerical method. While numerical methods are capable of producing accurate solutions, they are also difficult to use and consume more computationally resources. 

For this reason, this repository omits other option pricing techniques that would be otherwise more appropriate for the pricing of specific options.

### Parameters and functions glossary

    X      = underlying price;
    K      = strike price;
    t      = time to expiration (% of year);
    s      = volatility (% p.a. except in BFS formula);
    r      = risk-free interest rate (% p.a.);
    q      = dividend yield (% p.a.);
    N()    = cumulative distribution function of the standard normal distribution;
    n()    = probability density function of the standard normal distribution;
    exp()  = exponential function;
    sqrt() = square root function;
    Pi     = Archimedes' constant (~3.14159);

###  Black-Scholes-Merton (BSM)

The Merton's extension of the 1973 Black-Sholes formula is commonly used for the pricing of dividend-paying equity European-options. Note that this formula is not appropriate for any option on forwards and futures as this model accounts for the initial investment value of the underlying.

    bsmCallPrice(X, t) = exp(-q*t) * N(d1)*X - exp(-r*t) * N(d2)*K;

    bsmPutPrice(X, t) = exp(-r*t) * N(-d2)*K - exp(-q*t) * N(-d1)*X;

    d1 = [ln(X/K) + (r - q + s^2/2)*t] / [s * sqrt(t)];

    d2 = d1 - s * sqrt(t)

Greeks:

    bsmCallDelta(X, q, t, K, r, s) = exp(-q*t) * N(d1);

    bsmPutDelta(X, q, t, K, r, s) = exp(-q*t) * (N(d1)-1);

    bsmCallGamma(X, q, t, K, r, s) = [(exp(-q*t)/(X*s*sqrt(t)))] * [(1/sqrt(2*Pi))] * [exp(-d1^2/2)];

    bsmPutGamma(X, q, t, K, r, s) = bsmCallGamma(X, q, t, K, r, s);

    bsmCallRho(X, q, t, K, r, s) = (1/100) * (K*t*exp(-r*t)) * N(d2);

    bsmPutRho(X, q, t, K, r, s) = (-1/100) * (K*t*exp(-r*t)) * N(-d2);

    bsmCallTheta(X, q, t, K, r, s) = (1/360) * { -{[(X*s*exp(-q*t))/(2*sqrt(t))]*[1/sqrt(2*Pi)]*exp(-(d1^2)/2)} -[r*K*exp(-r*t)*N(d2)] +[q*X*exp(-q*t)*N(d1)] };

    bsmPutTheta(X, q, t, K, r, s)  = (1/360) * { -{[(X*s*exp(-q*t))/(2*sqrt(t))]*[1/sqrt(2*Pi)]*exp(-(d1^2)/2)} +[r*K*exp(-r*t)*N(-d2)] -[q*X*exp(-q*t)*N(-d1)] };

    bsmCallVega(X, q, t, K, r, s) = (1/100) * (X * exp(-q*t) * sqrt(t)) * (1/sqrt(2*Pi)) * exp(-d1^2/2);

    bsmPutVega(X, q, t, K, r, s) = bsmCallVega(X, q, t, K, r, s);

### Black 1976 (B76)

CCPs widely use the Black 1976 formula for pricing options on future contracts.

    b76CallPrice(X, t) = exp(-r*t) * [N(d1)*X - N(d2)*K];

    b76PutPrice(X, t) = exp(-r*t) * [N(-d2)*K - N(-d1)*X];

    d1 = [ln(X/K) + (s^2/2)*t] / [s * sqrt(t)];

    d2 = d1 - s * sqrt(t);

Greeks:

    b76CallDelta(X, t, K, r, s) = exp(-r*t) * N(d1);

    b76PutDelta(X, t, K, r, s) = exp(-r*t) * (N(d1)-1);

    b76CallGamma(X, t, K, r, s) = [(exp(-r*t)/(X*s*sqrt(t)))] * [(1/sqrt(2*Pi))] * [exp(-d1^2/2)];

    b76PutGamma(X, t, K, r, s) = b76CallGamma(X, t, K, r, s);

    b76CallRho(X, t, K, r, s) = (1/100) * (K*t*exp(-r*t)) * N(d2);

    b76PutRho(X, t, K, r, s) = (-1/100) * (K*t*exp(-r*t)) * N(-d2);

    b76CallTheta(X, t, K, r, s) = (1/360) * { -{[(X*s*exp(-r*t))/(2*sqrt(t))]*[1/sqrt(2*Pi)]*exp(-(d1^2)/2)} -[r*K*exp(-r*t)*N(d2)] +[r*X*exp(-r*t)*N(d1)] };

    b76PutTheta(X, t, K, r, s)  = (1/360) * { -{[(X*s*exp(-r*t))/(2*sqrt(t))]*[1/sqrt(2*Pi)]*exp(-(d1^2)/2)} +[r*K*exp(-r*t)*N(-d2)] -[r*X*exp(-r*t)*N(-d1)] };

    b76CallVega(X, t, K, r, s) = (1/100) * (X * exp(-r*t) * sqrt(t)) * (1/sqrt(2*Pi)) * exp(-d1^2/2);

    b76PutVega(X, t, K, r, s) = b76CallVega(X, t, K, r, s);

### Bachelier Futures Spread (BFS)

The Bachelier Future Spread model is a variant of the 1900 Bachelier model. The BFS model differs from the traditional Bachelier model as it takes into account the time value of money and the null initial investment in future contracts. In the BFS model, the dynamics of the underlying is an arithmetic Brownian motion, and because of that, this model is preferred for the pricing of spread option on forwards and futures where the underlying price can be negative (e.g. an option on a calendar spread future).

This model yields very good approximation results with respect to the B76 for options that are close at-the-money and with a short time to maturity. Generally, transaction volume in options contracts is concentrated in short-maturity at-the-money contracts, which is why the BFS formula is as a standard among CCPs.

**WARNING** : the volatility in the BFS model is expressed in absolute terms.

    bfsCallPrice(X, t) = exp(-r*t) * [N(d)*(X - K) + n(d)*(s * sqrt(t))];

    bfsPutPrice(X, t) = exp(-r*t) * [N(-d)*(K - X) + n(d)*(s * sqrt(t))];

    d = (X - K) / (s * sqrt(t));

Greeks:

    bfsCallDelta(X, t, K, r, s) = exp(-r*t) * N(d);

    bfsPutDelta(X, t, K, r, s) = -exp(-r*t) * N(-d);

    bfsCallGamma(X, t, K, r, s) = exp(-r*t) * n(d) / (s * sqrt(t));

    bfsPutGamma(X, t, K, r, s) = bfsCallGamma(X, t, K, r, s);

    bfsCallRho(X, t, K, r, s) = -t * exp(-r*t) * [N(d)*(X - K) + n(d)*(s * sqrt(t))];

    bfsPutRho(X, t, K, r, s) = -t * exp(-r*t) * [N(-d)*(K - X) + n(d)*(s * sqrt(t))];

    bfsCallTheta(X, t, K, r, s) = -r * exp(-r*t) * [N(d)*(X - K) + n(d)*(s * sqrt(t))] + (exp(-r*t) * s * n(d)) / (2 * sqrt(t));

    bfsPutTheta(X, t, K, r, s) = -r * exp(-r*t) * [N(-d)*(K - X) + n(d)*(s * sqrt(t))] +  (exp(-r*t) * s * n(d)) / (2 * sqrt(t)) - 2 * r * exp(-r*t) * (X - K);

    bfsCallVega(X, t, K, r, s) = exp(-r*t) * sqrt(t) * n(d);

    bfsPutVega(X, t, K, r, s) = bfsPutVega(X, t, K, r, s);


### Extracting the Implied Volatility with the Bisection Method

Implied volatility is one of the deciding factors in the pricing of options. There is no closed-form inverse for any of the formulas presented above, so the volatility `s`, cannot be expressed as a function of `X, K, r, t and q`, and therefore a numerical method must be employed. The methods for achieving these are known as root-finding algorithms and the most common are the Bisection, Newton-Raphson and Brent's methods.

The bisection method does require a little knowledge of the function. It assumes the that the root is bracketed in an interval `[a,b]` such that `f(a)` and `f(b)` have opposite signs. This is because it relies on the intermediate value theorem for correctness. With those assumptions, convergence is guaranteed, and it is linear to the iterations.

The Newton-Raphson's method also requires a good initial guess but requires many more assumptions of the function in a neighbourhood around the initial guess. In particular, it requires you to know how to compute the derivative. Convergence is quadratic and therefore much faster than the bisection method; however, iterations can overshoot the root, or get locked into a periodic iteration forever.

The Brent's method combines the bisection method, the secant method and inverse quadratic interpolation. It has the reliability of the bisection method with quicker convergence.

### Approximation of the Cumulative Distribution Function

Zelen & Severo (1964) approximation of the cumulative distribution function of the standard normal distribution

    _pdf = (1/sqrt(2 * pi())) * exp(-power(_x,2)/2);
    _t = 1/(1 + 0.2316419 * abs(_x));
    _cdf = 1 - _pdf * (0.31938153 * _t - 0.356563782 * power(_t,2) + 1.781477937 * power(_t,3) - 1.821255978 * power(_t,4) + 1.330274429 * power(_t,5));
    if(_x > 0)
        then return _cdf;
    else 
        return 1 - _cdf;