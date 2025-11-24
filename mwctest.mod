(**
 * @brief Tests for Mwc63x2 pseudorandom number generator implementation.
 * @copyright (c) 2025 Alexey L. Voskov
 * This software is licensed under the MIT license.
 *)
MODULE MwcTest;
IMPORT Mwc63x2, Out, Random;

TYPE GetRandom = PROCEDURE () : INTEGER;

(**
 * @brief Sort the array of integer using the comb sort algorithm.
 *)
PROCEDURE SortInt(VAR x : ARRAY OF INTEGER; len : INTEGER);
VAR
    i, t : INTEGER;
    is_sorted : BOOLEAN;
    gap : INTEGER;
BEGIN
    (* Comb sort passes *)
    gap := len DIV 2;
    WHILE gap > 1 DO
        FOR i := 0 TO len - gap - 1 DO
            IF x[i] > x[i + gap] THEN
                t := x[i];
                x[i] := x[i + gap];
                x[i + gap] := t;
            END
        END;
        gap := (gap * 10) DIV 13;
    END;
    (* Final bubble sort pass *)
    is_sorted := FALSE;
    WHILE ~is_sorted DO
        is_sorted := TRUE;
        FOR i := 0 TO len - 2 DO
            IF x[i] > x[i + 1] THEN
                t := x[i];
                x[i] := x[i + 1];
                x[i + 1] := t;
                is_sorted := FALSE;
            END
        END;
    END;
END SortInt;


PROCEDURE BSpaceGetNDups(VAR x : ARRAY OF INTEGER; len : INTEGER) : INTEGER;
VAR
    ndups, i : INTEGER;    
BEGIN
    ndups := 0;
    SortInt(x, len);
    FOR i := 0 TO len - 2 DO
        x[i] := x[i + 1] - x[i];
    END;
    SortInt(x, len);
    FOR i := 0 TO len - 3 DO
        IF x[i] = x[i + 1] THEN
            ndups := ndups + 1
        END
    END;
    RETURN ndups
END BSpaceGetNDups;


(**
 * @brief Birthday spacings test for pseudorandom number generator
 * @details This test was discovered by G. Marsaglia in 1980 and is
 * rather efficient against bad LCGs, additive/subtractive lagged
 * Fibonacci generators etc.
 *
 * References:
 *
 * Marsaglia, G., & Tsang, W. W. Some Difficult-to-pass Tests of Randomness. //
 * // Journal of Statistical Software. 2002. V. 7. N 3. P. 1-9.
 * https://doi.org/10.18637/jss.v007.i03
 *)
PROCEDURE BSpaceTest(next_rand : GetRandom);
CONST
    len = 4096;
    nsamples = 1000;
    lambda_theor = 8.0;
    lambda_min = 7.3; (* lambda for p ~ 1e-15 *)
    lambda_max = 8.7; (* lambda for p ~ 1 - 1e-15 *)
VAR    
    u : ARRAY len OF INTEGER;
    i, j, ndups : INTEGER;
    lambda : REAL;
    
BEGIN
    Out.String("Running birthday spacings test..."); Out.Ln();
    ndups := 0;
    FOR i := 0 TO nsamples DO
        FOR j := 0 TO len - 1 DO
            u[j] := next_rand()
        END;
        ndups := ndups + BSpaceGetNDups(u, len);
    END;
    lambda := ndups / nsamples;
    Out.String("  Real lambda:    "); Out.Real(lambda, 10); Out.Ln();
    Out.String("  Expectd lambda: "); Out.Real(lambda_theor, 10); Out.Ln();
    IF (lambda < lambda_min) OR (lambda > lambda_max) THEN
        Out.String("  Test FAILED!")
    ELSE
        Out.String("  Test passed")
    END;
    Out.Ln()

END BSpaceTest;


PROCEDURE RandomWrapper() : INTEGER;
BEGIN
    RETURN Random.Int(2147483647)
END RandomWrapper;


BEGIN
    IF Mwc63x2.SelfTest() THEN
        Out.String("Internal self-test passed");
        Out.Ln()
    ELSE
        Out.String("Internal self-test failed");
        Out.Ln()
    END;
    Out.String("Testing Mwc63x2..."); Out.Ln();
    BSpaceTest(Mwc63x2.Next);
    Out.String("Testing built-in random..."); Out.Ln();
    BSpaceTest(RandomWrapper);
    Out.Int(Mwc63x2.Next(), 10);
    Out.Ln()
END MwcTest.
