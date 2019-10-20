' NOTE: this script is a work in progress

' ----------------------------------------------------------------------------------------------------------------------
' Bachelier Futures Spread (BFS)
' ----------------------------------------------------------------------------------------------------------------------

Function bfsPrice ( S As Double, _
                    X As Double, _
                    r As Double, _
                    v As Double, _
                    t As Double, _
                    contract_type As String ) As Double
    
    Dim y As Double
    Dim volSqrtT As Double
    Dim cumNorm As Double
    Dim normDensity As Double
    Dim d As Double
    
    y = S - X
    volsqrt = v * Sqr(t)
    d = y / volsqrt
    cumNorm = WorksheetFunction.NormDist(d, 0, 1, True)
    normDensity = (1 / Sqr(2 * WorksheetFunction.Pi)) * Exp((-(d) ^ 2) / 2)
    
    
    If contract_type = "C" Or contract_type = "c" Then
    
    bfsPrice = Exp(-r * t) * (y * cumNorm + volsqrt * normDensity)
    
    ElseIf contract_type = "P" Or contract_type = "p" Then
    
    bfsPrice = (Exp(-r * t) * (y * cumNorm + volsqrt * normDensity)) - Exp(-r * t) * y   'call - Exp(-r * t) * y
    
    Else: MsgBox "Contract_type has to be either C or P"
    
    End If
    
End Function

' ----------------------------------------------------------------------------------------------------------------------
' Black-76 (B76)
' ----------------------------------------------------------------------------------------------------------------------

Function b76Price ( S As Double, _
                    X As Double, _
                    r As Double, _
                    v As Double, _
                    t As Double, _
                    contract_type As String ) As Double

    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(S / X) + (v ^ 2) * (t / 2)) / (v * Sqr(t))
    d2 = d1 - v * Sqr(t)
    
    
    If contract_type = "C" Or contract_type = "c" Then
    
    b76Price = Exp(-r * t) * (S * WorksheetFunction.NormDist(d1, 0, 1, True) - X * WorksheetFunction.NormDist(d2, 0, 1, True))
    
    ElseIf contract_type = "P" Or contract_type = "p" Then
    
    b76Price = Exp(-r * t) * (X * WorksheetFunction.NormDist(-d2, 0, 1, True) - S * WorksheetFunction.NormDist(-d1, 0, 1, True))
    
    Else: MsgBox "Contract_type has to be either C or P"
    
    End If
    
End Function


Function b76Delta ( S As Double, _
                    X As Double, _
                    r As Double, _
                    v As Double, _
                    t As Double, _
                    contract_type As String ) As Double
    
    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(S / X) + (v ^ 2) * (t / 2)) / (v * Sqr(t))
    d2 = d1 - v * Sqr(t)
    
    
    If contract_type = "C" Or contract_type = "c" Then
    
    b76Delta = Exp(-r * t) * (WorksheetFunction.NormDist(d1, 0, 1, True))
    
    ElseIf contract_type = "P" Or contract_type = "p" Then
    
    b76Delta = Exp(-r * t) * (WorksheetFunction.NormDist(d1, 0, 1, True) - 1)
    
    Else: MsgBox "Contract_type has to be either C or P"
    
    End If
    
End Function


Function b76Gamma ( S As Double, _
                    X As Double, _
                    r As Double, _
                    v As Double, _
                    t As Double, _
                    contract_type As String) As Double
    
    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(S / X) + (v ^ 2) * (t / 2)) / (v * Sqr(t))
    d2 = d1 - v * Sqr(t)
    
    
    If contract_type = "C" Or contract_type = "c" Then
    
    b76Gamma = Exp(-r * t) * (WorksheetFunction.NormDist(d1, 0, 1, False)) / (S * v * Sqr(t))
    
    ElseIf contract_type = "P" Or contract_type = "p" Then
    
    b76Gamma = Exp(-r * t) * (WorksheetFunction.NormDist(d1, 0, 1, False)) / (S * v * Sqr(t))
    
    Else: MsgBox "Contract_type has to be either C or P"
    
    End If
    
End Function


Function b76Vega ( S As Double, _
                   X As Double, _
                   r As Double, _
                   v As Double, _
                   t As Double, _
                   contract_type As String ) As Double
    
    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(S / X) + (v ^ 2) * (t / 2)) / (v * Sqr(t))
    d2 = d1 - v * Sqr(t)
    
    
    If contract_type = "C" Or contract_type = "c" Then
    
    b76Vega = Exp(-r * t) * (WorksheetFunction.NormDist(d1, 0, 1, False)) * S * Sqr(t)
    
    ElseIf contract_type = "P" Or contract_type = "p" Then
    
    b76Vega = Exp(-r * t) * (WorksheetFunction.NormDist(d1, 0, 1, False)) * S * Sqr(t)
    
    Else: MsgBox "Contract_type has to be either C or P"
    
    End If
    
End Function


Function b76Theta ( S As Double, _
                    X As Double, _
                    r As Double, _
                    v As Double, _
                    t As Double, _
                    contract_type As String ) As Double
    
    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(S / X) + (v ^ 2) * (t / 2)) / (v * Sqr(t))
    d2 = d1 - v * Sqr(t)
    
    
    If contract_type = "C" Or contract_type = "c" Then
    
    b76Theta = Exp(-r * t) * ((-S * WorksheetFunction.NormDist(d1, 0, 1, False) * v) / (2 * Sqr(t))) + r * (S * WorksheetFunction.NormDist(d1, 0, 1, True) - X * WorksheetFunction.NormDist(d2, 0, 1, True))
    
    ElseIf contract_type = "P" Or contract_type = "p" Then
    
    b76Theta = Exp(-r * t) * ((-S * WorksheetFunction.NormDist(d1, 0, 1, False) * v) / (2 * Sqr(t))) + r * (S * WorksheetFunction.NormDist(-d1, 0, 1, True) - X * WorksheetFunction.NormDist(-d2, 0, 1, True))
    
    Else: MsgBox "Contract_type has to be either C or P"
    
    End If
    
End Function


Function b76Ivol ( S As Double, _
                   X As Double, _
                   contract_type As String, _
                   option_prc As Double, _
                   t As Double, _
                   r As Double, _
                   Optional volGuess As Double = 1 ) As Double
 
    Dim function_error As Double
    Dim vol_error As Double
    Dim Iteration As Integer
    Dim volLower As Double
    Dim volUpper As Double
    Dim volMid As Double
    
    function_error = 0.000001
    vol_error = 0.0001
    Iteration = 0
    volLower = volGuess * 0.0001
    volUpper = volGuess * 2
    
    volMid = (volUpper + volLower) / 2
    
    Do While Abs(BLACK76(S, X, r, volMid, t, contract_type) - option_prc) > function_error And Abs(volUpper - volLower) > vol_error
      If (BLACK76(S, X, r, volMid, t, contract_type) - option_prc) >= 0 Then
       volUpper = volMid
      Else
        volLower = volMid
      End If
      volMid = (volLower + volUpper) / 2
      Iteration = Iteration + 1
    Loop
    
    b76Ivol   = volMid
 
End Function