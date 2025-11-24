(**
 * @brief Mwc63x2 combined PRNG implementation for FreeOberon.
 * @details It is a combination of two MWC (Multiply-With-Carry) generators
 * designed to the signed 64-bit integers typical for Oberon dialects. This
 * generator doesn't use integer overflows. The algorithm is fairly robust
 * and passes (tested for C implementation):
 *
 * - TestU01 SmallCrush, Crush and BigCrush batteries.
 * - PractRand 0.94 at least up to 2 TiB.
 * - SmokeRand express, brief, default and full batteries.
 *
 * Even with bad multipliers (a0 = ...., a1 = ....) it passees TestU01 and
 * SmokeRand batteries and also PractRand 0.94 at least up to 2 TiB.
 *
 * @copyright (c) 2025 Alexey L. Voskov
 * This software is licensed under the MIT license.
 *)
MODULE Mwc63x2;
IMPORT SYSTEM, Platform;
TYPE INT64 = SYSTEM.INT64;
TYPE Mwc63x2State = RECORD
    x : ARRAY 2 OF INT64
END;

VAR
    mwc : POINTER TO Mwc63x2State; (* Global Mwc63x2 state *)

CONST
    twopow32 = 0100000000H;

PROCEDURE Time() : INTEGER;
    RETURN Platform.Time()
END Time;

(*----------------------------------------------*
 *----- Pseudorandom number generator core -----*
 *----------------------------------------------*)

(**
 * @brief Generate the next signed integer from the [0; 2^31-1] interval.
 *)
PROCEDURE Mwc63x2_Next*(obj : POINTER TO Mwc63x2State) : INTEGER;
CONST
    a0 = 1073100393;
    a1 = 1073735529;
VAR
    c0, x0, c1, x1 : INT64;
BEGIN
    (* MWC 0 iteration *)
    c0 := obj.x[0] DIV twopow32;
    x0 := obj.x[0] MOD twopow32;
    obj.x[0] := a0 * x0 + c0;
    (* MWC 1 iteration *)
    c1 := obj.x[1] DIV twopow32;
    x1 := obj.x[1] MOD twopow32;
    obj.x[1] := a1 * x1 + c1;
    (* Output function *)
    RETURN SYSTEM.SHORT( ((x0 + x1 + c0 + c1) MOD twopow32) DIV 2 )
END Mwc63x2_Next;


(**
 * @brief Intialize the generator using the user-supplied seeds. They
 * can have any value from the [0..2^31-1] interval.
 *)
PROCEDURE Mwc63x2_Init*(obj : POINTER TO Mwc63x2State; s0, s1 : INTEGER);
VAR
    i, u : INTEGER;    
BEGIN
    obj.x[0] := s0; obj.x[0] := obj.x[0] + twopow32;
    obj.x[1] := s1; obj.x[1] := obj.x[1] + twopow32;
    (* Warmup *)
    FOR i := 1 TO 16 DO
        u := Mwc63x2_Next(obj)
    END
END Mwc63x2_Init;


(*---------------------------------------*
 *----- Simplified one-threaded API -----*
 *---------------------------------------*)

PROCEDURE Next*() : INTEGER;
BEGIN
    RETURN Mwc63x2_Next(mwc)
END Next;


PROCEDURE Init*(s0 : INTEGER; s1 : INTEGER);
BEGIN
    Mwc63x2_Init(mwc, s0, s1)
END Init;


(**
 * @brief An internal self-test.
 *)
PROCEDURE SelfTest*() : BOOLEAN;
CONST
    mwc0ref  = 0123DEADBEEFH;
    mwc1ref  = 0456CAFEBABEH;
    outref   = 09248038FH;
    niterref = 1000000;
VAR
    i : INTEGER;
    u : INT64;
    obj : POINTER TO Mwc63x2State;
BEGIN
    NEW(obj);
    obj.x[0] := mwc0ref;
    obj.x[1] := mwc1ref;
    FOR i := 1 TO niterref DO
        u := Mwc63x2_Next(obj)
    END;
    RETURN u = outref DIV 2
END SelfTest;

(**
 * @brief Initialize PRNG state using current system time.
 *)
PROCEDURE Randomize*();
VAR
    t : INTEGER;
BEGIN
    t := Time();
    Init(t, (t MOD 1073741824) + 12345)
END Randomize;


BEGIN
    NEW(mwc);
    Randomize()
END Mwc63x2.
