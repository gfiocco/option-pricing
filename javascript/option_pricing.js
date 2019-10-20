// NOTE: this script is a work in progress

// Black 76
var b76 = (S, X, r, v, t) => {
  
  var d1 = (Math.log(S/X) + Math.pow(v,2) * (t/2)) / (v * Math.sqrt(t));
  var d2 = d1 - (v * Math.sqrt(t))
  
  var prcC = Math.exp(-r * t) * (S * sNormDist(d1,true) - X * sNormDist(d2,true));
  var prcP = Math.exp(-r * t) * (X * sNormDist(-d2,true) - S * sNormDist(-d1,true));
  
  console.log('Prc. Call: ' + prcC);
  console.log('Prc. Put: ' + prcP);
  
}

var sNormDist = (x, cdf) => {
  var n = Math.exp(-Math.pow(x,2)/2) / Math.sqrt(2 * Math.PI);
  var k = 1 / (1 + 0.2316419 * Math.abs(x));
  var fx = n * (
      (0.319381530 * k) - 
      (0.356563782 * Math.pow(k,2)) + 
      (1.781477937 * Math.pow(k,3)) - 
      (1.821255978 * Math.pow(k,4)) + 
      (1.330274429 * Math.pow(k,5))
    );
  if(cdf){if(x >= 0) {return (1-fx);} else {return fx};}
  else {return n;}
}

b76(50, 50, 0, 0.3, 1); // 50 ATM 30% vol 1yr maturity -- (put = call = 5.961771214270794)