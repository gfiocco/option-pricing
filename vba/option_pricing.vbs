' ----------------------------------------------------------------------------------------------------------------------
' Bachelier Futures Spread (BFS)
' ----------------------------------------------------------------------------------------------------------------------

Function bfsPrice( undprc As Double, _
                   strike As Double, _
                   frr As Double, _
                   ivol As Double, _
                   ttm As Double, _
                   optyp As String) As Double
    
    Dim d As Double

    d = (undprc - strike) / (ivol * Sqr(ttm))
    
    If optyp = "C" Or optyp = "c" Then
    
    bfsPrice = Exp(-frr*ttm) * (WorksheetFunction.NormDist(d, 0, 1, True) * (undprc - strike) + WorksheetFunction.NormDist(d, 0, 1, False) * (ivol * Sqr(ttm)))
    
    ElseIf optyp = "P" Or optyp = "p" Then
    
    bfsPrice = Exp(-frr*ttm) * (WorksheetFunction.NormDist(-d, 0, 1, True) * (strike - undprc) + WorksheetFunction.NormDist(d, 0, 1, False) * (ivol * Sqr(ttm)))
    
    Else: MsgBox "Contract type has to be either C or P"
    
    End If
    
End Function

Function bfsVega( undprc As Double, _
                  strike As Double, _
                  frr As Double, _
                  ivol As Double, _
                  ttm As Double) As Double
    
    Dim d As Double
    d = (undprc - strike) / (ivol * Sqr(ttm))
    bfsVega = Exp(-frr * ttm) * (WorksheetFunction.NormDist(d, 0, 1, False)) * Sqr(ttm)
    
End Function

Function bfsIvolNR( undprc As Double, _
                    strike As Double, _
                    optyp As String, _
                    optprc As Double, _
                    ttm As Double, _
                    frr As Double) As Double
    
    Dim d As Double
    Dim ivol As Double
    Dim ivolega As Double
    Dim optprc0 As Double

    ivol = Sqr(2 * WorksheetFunction.Pi / ttm) * undprc / strike
    For I = 1 To 10
        optprc0 = bfsPrice(undprc,strike,frr,ivol,ttm,optyp)
        ivol = ivol - (optprc0 - optprc) / bfsVega(undprc, strike, frr, ivol, ttm)
        If Abs(optprc0 - optprc) < 1E-10 Then Exit For
    Next I
    bfsIvolNR = ivol
    
End Function

Function bfsIvolBS( undprc As Double, _
                     strike As Double, _
                     optyp As String, _
                     optprc As Double, _
                     ttm As Double, _
                     frr As Double, _
                     Optional ivololGuess As Double = 1) As Double
 
    Dim function_error As Double
    Dim ivolol_error As Double
    Dim Iteration As Integer
    Dim ivolLower As Double
    Dim ivolUpper As Double
    Dim ivolMid As Double
    
    function_error = 1E-06
    ivolol_error = 0.0001
    Iteration = 0
    ivolLower = ivololGuess * 0.1
    ivolUpper = ivololGuess * 999999
    
    ivolMid = (ivolUpper + ivolLower) / 2
    
    Do While Abs(bfsPrice(undprc, strike, frr, ivolMid, ttm, optyp) - optprc) > function_error And Abs(ivolUpper - ivolLower) > ivolol_error
      xoptprc = bfsPrice(undprc, strike, frr, ivolMid, ttm, optyp)
      Debug.Print ivolMid & " -> " & xoptprc
      If (bfsPrice(undprc, strike, frr, ivolMid, ttm, optyp) - optprc) >= 0 Then
      ivolUpper = ivolMid
      Else
      ivolLower = ivolMid
      End If
      ivolMid = (ivolLower + ivolUpper) / 2
      Iteration = Iteration + 1
      ' Debug.Print Iteration & " - " & ivolMid
    Loop

    bfsIvolBS = ivolMid

End Function


' Validation

' bfsPrice(50,50,0.01,0.2*50,1,"C") -> 3.9497273838695244
' bfsIvolNR(50,50,"C",3.9431602019637353,1,0.01) -> 9.983373075487162
' bfsIvolBS(50,50,"C",3.9431602019637353,1,0.01) -> 9.983388016893880
' bfsVega(50, 50, 0.01, 1, 1) -> 0.394972738
' bfsIvolBS(50,50,"C",3.9431602019637353,1,0,0.0)

' ----------------------------------------------------------------------------------------------------------------------
' Black-76 (B76)
' ----------------------------------------------------------------------------------------------------------------------

Function b76Price ( undprc As Double, _
                    strike As Double, _
                    frr As Double, _
                    ivol As Double, _
                    ttm As Double, _
                    optyp As String ) As Double

    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(undprc / strike) + (ivol ^ 2) * (ttm / 2)) / (ivol * Sqr(ttm))
    d2 = d1 - ivol * Sqr(t)
    
    
    If optyp = "C" Or optyp = "c" Then
    
    b76Price = Exp(-frr * ttm) * (undprc * WorksheetFunction.NormDist(d1, 0, 1, True) - strike * WorksheetFunction.NormDist(d2, 0, 1, True))
    
    ElseIf optyp = "P" Or optyp = "p" Then
    
    b76Price = Exp(-frr * ttm) * (strike * WorksheetFunction.NormDist(-d2, 0, 1, True) - undprc * WorksheetFunction.NormDist(-d1, 0, 1, True))
    
    Else: MsgBox "Contractttmype has to be either C or P"
    
    End If
    
End Function


Function b76Delta ( undprc As Double, _
                    strike As Double, _
                    frr As Double, _
                    ivol As Double, _
                    ttm As Double, _
                    optyp As String ) As Double
    
    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(undprc / strike) + (ivol ^ 2) * (ttm / 2)) / (ivol * Sqr(ttm))
    d2 = d1 - ivol * Sqr(ttm)
    
    If optyp = "C" Or optyp = "c" Then
    
    b76Delta = Exp(-frr * ttm) * (WorksheetFunction.NormDist(d1, 0, 1, True))
    
    ElseIf optyp = "P" Or optyp = "p" Then
    
    b76Delta = Exp(-frr * ttm) * (WorksheetFunction.NormDist(d1, 0, 1, True) - 1)
    
    Else: MsgBox "Contractttmype has to be either C or P"
    
    End If
    
End Function


Function b76Gamma ( undprc As Double, _
                    strike As Double, _
                    frr As Double, _
                    ivol As Double, _
                    ttm As Double, _
                    optyp As String) As Double
    
    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(undprc / strike) + (ivol ^ 2) * (ttm / 2)) / (ivol * Sqr(ttm))
    d2 = d1 - ivol * Sqr(ttm)
    
    
    If optyp = "C" Or optyp = "c" Then
    
    b76Gamma = Exp(-frr * ttm) * (WorksheetFunction.NormDist(d1, 0, 1, False)) / (undprc * ivol * Sqr(ttm))
    
    ElseIf optyp = "P" Or optyp = "p" Then
    
    b76Gamma = Exp(-frr * ttm) * (WorksheetFunction.NormDist(d1, 0, 1, False)) / (undprc * ivol * Sqr(ttm))
    
    Else: MsgBox "Contractttmype has to be either C or P"
    
    End If
    
End Function


Function b76Vega ( undprc As Double, _
                   strike As Double, _
                   frr As Double, _
                   ivol As Double, _
                   ttm As Double ) As Double
    
    Dim d1 As Double
    
    d1 = (Log(undprc / strike) + (ivol ^ 2) * (ttm / 2)) / (ivol * Sqr(ttm))
    
    b76Vega = Exp(-frr * ttm) * (WorksheetFunction.NormDist(d1, 0, 1, False)) * undprc * Sqr(ttm)
    
End Function


Function b76Theta ( undprc As Double, _
                    strike As Double, _
                    frr As Double, _
                    ivol As Double, _
                    ttm As Double, _
                    optyp As String ) As Double
    
    Dim d1 As Double
    Dim d2 As Double
    
    d1 = (Log(undprc / strike) + (ivol ^ 2) * (ttm / 2)) / (ivol * Sqr(ttm))
    d2 = d1 - ivol * Sqr(ttm)
    
    
    If optyp = "C" Or optyp = "c" Then
    
    b76Theta = Exp(-frr * ttm) * ((-undprc * WorksheetFunction.NormDist(d1, 0, 1, False) * ivol) / (2 * Sqr(ttm))) + frr * (undprc * WorksheetFunction.NormDist(d1, 0, 1, True) - strike * WorksheetFunction.NormDist(d2, 0, 1, True))
    
    ElseIf optyp = "P" Or optyp = "p" Then
    
    b76Theta = Exp(-frr * ttm) * ((-undprc * WorksheetFunction.NormDist(d1, 0, 1, False) * ivol) / (2 * Sqr(ttm))) + frr * (undprc * WorksheetFunction.NormDist(-d1, 0, 1, True) - strike * WorksheetFunction.NormDist(-d2, 0, 1, True))
    
    Else: MsgBox "Contractttmype has to be either C or P"
    
    End If
    
End Function


Function b76Ivol ( undprc As Double, _
                   strike As Double, _
                   optyp As String, _
                   optprc As Double, _
                   ttm As Double, _
                   frr As Double, _
                   Optional ivololGuess As Double = 1 ) As Double
 
    Dim function_error As Double
    Dim ivolol_error As Double
    Dim Iteration As Integer
    Dim ivolLower As Double
    Dim ivolUpper As Double
    Dim ivolMid As Double
    
    function_error = 0.000001
    ivolol_error = 0.0001
    Iteration = 0
    ivolLower = ivololGuess * 0.0001
    ivolUpper = ivololGuess * 2
    
    ivolMid = (ivolUpper + ivolLower) / 2
    
    Do While Abs(b76Price(undprc, strike, frr, ivolMid, ttm, optyp) - optprc) > function_error And Abs(ivolUpper - ivolLower) > ivolol_error
      If (b76Price(S, strike, r, ivolMid, ttm, optyp) - optprc) >= 0 Then
      ivolUpper = ivolMid
      Else
      ivolLower = ivolMid
      End If
      ivolMid = (ivolLower + ivolUpper) / 2
      Iteration = Iteration + 1
    Loop

    b76Ivol = ivolMid
 
End Function