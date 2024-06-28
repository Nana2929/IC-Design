

## Time Spent
- 禮拜四：兩小時
- 禮拜六：10:46 -13:00, 23:00 - 23:50
- 禮拜一：15:00 - 21:00
- 禮拜三：20:30 - 23:30
- 禮拜四：1 hr （過 Pre-sim）


## Notes
- `Quartus` 在跑 Synthesis 時，timing constraint 會影響 Placement 和 Routing 的速度，宜先行調整 SDC 後再進行 Synthesis。
- Be sure to initialize all signals at "RESET" state; this could affect the simulation result.

## Pseudo code
https://hackmd.io/@5HlvW0J1QTmqg6azf_URYQ/Hy_lj5a6p
Note that the pseudo-code is implemented using 1-indexed, but mine is 0-indexed.
A : heap array

MAX-HEAPIFY(A, i)
```
MAX-HEAPIFY(A, i)
    l = 2 * i
    r = 2 * i + 1
    if l <= n and A[l] > A[i]
        largest = l
    else largest = i
    if r <= n and A[r] > A[largest]
        largest = r
    if largest != i
        exchange A[i] with A[largest]
        MAX-HEAPIFY(A, largest)
```
BUILD-QUEUE(A)
```
BUILD-QUEUE(A)
    for i = ⌊n/2⌋ downto 1
        MAX-HEAPIFY(A, i)
```
EXTRACT-MAX(A)
```
EXTRACT-MAX(A)
    if A.heap-size < 1
        error "heap underflow"
    max = A[1]
    A[1] = A[A.heap-size]
    A.heap-size = A.heap-size - 1
    MAX-HEAPIFY(A, 1)
    return max
```
INCREASE-VALUE(A, index, value)
```
INCREASE-VALUE(A, index, value)
    if value < A[index]
        error "new value is smaller than current value"
    A[index] = value
    while index > 1 and A[PARENT(index)] < A[index]
        exchange A[index] with A[PARENT(index)]
        index = PARENT(index)
```
INSERT_DATA(A, value)
```
INSERT-DATA(A, value)
    A.heap-size = A.heap-size + 1
    A[A.heap-size] = -∞
    INCREASE-VALUE(A, A.heap-size, value)
```
input : 一連串數字 eg: [2,5,7,9,100,50,250,21,54,6,79,80]，輸入結束後須進行一次 BUILD-QUEUE 使RAM中資料符合 Max-heap 特性，而後輸入 EXTRACT-MAX、INCREASE-VALUE、INSERT-DATA 與 write 五個指令