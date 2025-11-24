from sympy import *
a = 2
m = a * 10**2 - 1
x0_1, x0_2 = 1, 3
x1, x2 = x0_1, x0_2
print("{0:5d} {1:5d} {2:5d}".format(x1, x2, 0))
for i in range(1,1000):
    x1, x2 = (a * x1) % m, (a * x2) % m
    print("{0:5d} {1:5d} {2:5d}".format(x1, x2, i))
    if x1 == x0_1 or x2 == x0_1:
        break

print(isprime(m), isprime((m-1)//2))
print(n_order(10, m))