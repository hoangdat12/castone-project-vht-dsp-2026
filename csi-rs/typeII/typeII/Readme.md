# README – Giải thích các tham số Type-II Codebook (3GPP TS 38.214)

Tài liệu này giải thích **ý nghĩa, nguồn gốc và cách sử dụng** các tham số thường gặp khi hiện thực **Type-II CSI codebook** theo **3GPP TS 38.214 – mục 5.2.2.2.3**.

Phạm vi áp dụng cho cấu hình điển hình:

* Type-II codebook
* N1 × N2 antenna grid (ví dụ 4 × 4)
* L = numberOfBeams
* RI = 1 hoặc 2 (Type-II giới hạn RI ≤ 2)

---

## 1. Tổng quan luồng chỉ số

UE **không báo trực tiếp ma trận precoding W** mà báo các **chỉ số PMI** gồm hai nhóm:

* **i1**: chọn beam + amplitude chính
* **i2**: phase + subband amplitude

Từ các chỉ số này, gNB **tái tạo lại W**.

---

## 2. Nhóm chỉ số i1

```text
i1 = { i11, i12, i13, i14 }
```

### 2.1 i11 – Beam index theo chiều N1

**Ký hiệu trong spec**: $$i_{1,1}$$

**Miền giá trị**:

```text
0 … O1 − 1
```

**Ý nghĩa**:

* Chọn beam theo trục **N1** (horizontal / azimuth)
* Dùng để tạo chỉ số beam m1

**Công thức liên quan**:
$$m_1^{(i)} = O_1 n_1^{(i)} + q_1$$

**Lưu ý**:

* UE báo **L hoặc ν giá trị** (phụ thuộc RI)
* Không phải vị trí antenna

---

### 2.2 i12 – Beam index theo chiều N2

**Ký hiệu trong spec**: $$i_{1,2}$$

**Miền giá trị**:

$$i_{1,2} \in \{0, 1, \dots, \binom{N_1 N_2}{L} - 1\}$$

**Ý nghĩa**:

* Chọn beam theo trục **N2** (vertical / elevation)
* Dùng để tạo chỉ số beam m2

**Công thức**:
$$m_2^{(i)} = O_2 n_2^{(i)} + q_2$$

---

### 2.3 i13 – Strongest coefficient index

**Ký hiệu trong spec**: $$i_{1,3}$$

**Miền giá trị**:

```text
0 … (2L − 1)
```

**Ý nghĩa**:

* Xác định **hệ số mạnh nhất** trong tập 2L coefficients
* Với hệ số này:

  * Amplitude = 1 (mặc định)
  * Phase = 0
  * **Không được báo trong i14, i21, i22**

---

### 2.4 i14 – Amplitude coefficient indices

**Ký hiệu trong spec**: $$i_{1,4}$$

**Miền giá trị**:

```text
0 … 7
```

**Ý nghĩa**:

* Chỉ số biên độ của các coefficient còn lại
* Map sang giá trị biên độ thực theo **Table 5.2.2.2.3-2**

**Ví dụ mapping**:

| i14 | p(1) |
| --- | ---- |
| 7   | 1    |
| 6   | 1/2  |
| 5   | 1/4  |
| 4   | 1/8  |
| 0   | 0    |

**Số lượng phần tử**:

```text
2L − 1  (loại strongest coefficient)
```

**Lưu ý**:

* **Strongest coeffcient** không được báo và mặc định = 7.

---

## 3. Nhóm chỉ số i2

```text
i2 = { i21, i22 }
```

### 3.1 i21 – Phase coefficient indices

**Ký hiệu trong spec**: ( i_{2,1,l} )

**Miền giá trị**:

```text
0 … N_PSK − 1
```

**Ý nghĩa**:

* Quy định pha của mỗi coefficient

**Công thức pha**:
$$\phi = \frac{2\pi}{N_{PSK}} \cdot c$$

**Lưu ý**:

* Strongest coefficient **không có phase** (mặc định 0)
* UE báo cáo PMI cho GNB.
- Số lượng phần tử:  
$$\min(M_l, K^{(2)}) - 1$$
- Các phần tử trong nhóm này được báo cáo với **độ phân giải đầy đủ**.
- Miền giá trị của hệ số:
$$c_{l,i} \in \{0, 1, \dots, N_{PSK} - 1\}$$

- Số lượng phần tử:
$$M_l - \min(M_l, K^{(2)})$$

- Các phần tử này chỉ được báo cáo với **độ phân giải thấp hơn** nhằm giảm overhead phản hồi.
- Miền giá trị của hệ số:
$$c_{l,i} \in \{0, 1, 2, 3\}$$

- Số lượng phần tử:
$$2L - M_l$$

- Các phần tử này **không được UE báo cáo**.
- Tại phía gNB, các hệ số này được mặc định:
$$c_{l,i} = 0$$

---

### 3.2 i22 – Subband amplitude indices

**Điều kiện tồn tại**:

```text
subbandAmplitude = true
```

**Nếu subbandAmplitude = false**:
**i22** mặc định bằng 1 cho toàn bộ.

**Miền giá trị**:

```text
0 … 1
```

**Ý nghĩa**:

* Điều chỉnh biên độ phụ theo subband
* Map theo **Table 5.2.2.2.3-3**

**Amplitude cuối**:
$$a = p^{(1)} \cdot p^{(2)}$$

**Lưu ý**:

* UE báo cáo PMI cho GNB

Đối với mỗi lớp \(l\), các chỉ số nhị phân \(k_{l,i}^{(2)}\) được báo cáo theo nguyên tắc sau:

- Chỉ báo cáo:
$$\min(M_l, K^{(2)}) - 1$$
  phần tử.
- Các phần tử này tương ứng với **các hệ số mạnh nhất**, **ngoại trừ hệ số mạnh nhất tuyệt đối** có chỉ số $$i_{1,3,l}$$.

- Các phần tử được báo cáo có miền giá trị nhị phân:
$$k_{l,i}^{(2)} \in \{0, 1\}$$

- Số lượng phần tử không được báo cáo:
$$2L - \min(M_l, K^{(2)})$$

- Các phần tử này **không được UE báo cáo**.
- Tại phía gNB, các giá trị này được mặc định:
$$k_{l,i}^{(2)} = 1$$

---

## 4. Các biến nội bộ (UE không report)

### 4.1 n1, n2 – Beam position indices

* Xác định vị trí beam trong lưới N1 × N2
* Được **suy ra từ i11, i12 bằng ánh xạ tổ hợp**
* Dựa trên **Table 5.2.2.2.3-1 (Combinatorial coefficients)**

UE **không báo trực tiếp** n1, n2

---

### 4.2 m1, m2 – Beam indices thực

**Công thức**:
* $$m_1 = O_1 n_1 + q_1$$
* $$m_2 = O_2 n_2 + q_2$$

Dùng để sinh vector beam:
* $$u_{m_1,m_2}(n_1,n_2)$$

---

### 4.3 p1, p2 – Amplitude thực

* p1: từ i14 (Table 3-2)
* p2: từ i22 (Table 3-3)

**Amplitude cuối**:
$$a = p_1 \cdot p_2$$

---

## 5. Bảng tóm tắt nhanh

| Tham số | UE report | Ý nghĩa               |
| ------- | --------- | --------------------- |
| i11     | ✔         | Beam index N1         |
| i12     | ✔         | Beam index N2         |
| i13     | ✔         | Strongest coefficient |
| i14     | ✔         | Amplitude chính       |
| i21     | ✔         | Phase                 |
| i22     | ✔         | Subband amplitude     |
| n1, n2  | ✘         | Vị trí beam           |
| m1, m2  | ✘         | Beam thực             |
| p1, p2  | ✘         | Amplitude thực        |

---
## 6. UE input parameters (Type II Codebook)

* Ví dụ tập tham số CSI do UE báo cáo cho Codebook Type II:

```matlab
L = 4;          % Number of layers
NPsk = 8;       % PSK order for coefficient phase

N1 = 4; N2 = 4; % Antenna grid size
O1 = 4; O2 = 4; % Oversampling factors

% i1: Beam / basis indices
i11 = [2, 1];   % Beam index (dimension 1)
i12 = [2];      % Beam index (dimension 2)
i13 = [3, 1];   % Additional beam refinement indices
i14 = [ ...
  4, 6, 5, 0, 2, 3, 1;
  3, 2, 4, 1, 5, 6, 0
];

% i2: Coefficient indices
i21 = [ ...
  1, 3, 4, 2, 5, 7;
  2, 0, 5, 1, 4, 6
];               % Phase indices (0 … NPsk−1)

i22 = [ ...
  0, 1, 0, 1, 0;
  1, 1, 0, 0, 1
];               % Amplitude / group indices

i1 = {i11, i12, i13, i14};
i2 = {i21, i22};
```

---
## 7. Cách dùng các hàm

### validateInputs
**Mô tả**  
Kiểm tra tính hợp lệ của các tham số CSI do UE báo cáo.

**Input**
- `nLayers`: số layer truyền
- `sbAmplitude`: cấu hình biên độ theo subband
- `i1`: tập chỉ số beam `{i11, i12, i13, i14}`
- `i2`: tập chỉ số hệ số `{i21, i22}`

**Output**
- Không có (chỉ thực hiện kiểm tra)

---

### computeInputs
**Mô tả**  
Lấy các input **i11, i12, i13, i14, i21, i22** và format chuẩn để xử lý.

**Input**
- `L`: số layer
- `i1`: các chỉ số beam
- `i2`: các chỉ số hệ số

**Output**
- `i11`: chỉ số beam theo chiều N1
- `i12`: chỉ số beam theo chiều N2
- `i14`: các chỉ số beam bổ sung
- `i21`: chỉ số pha
- `i22`: chỉ số nhóm biên độ

**Example**

_Input_
```matlab
cfg = struct();

cfg.CodebookConfig.N1 = 4;
cfg.CodebookConfig.N2 = 4;
cfg.CodebookConfig.O1 = 4;
cfg.CodebookConfig.O2 = 4;

cfg.CodebookConfig.NumberOfBeams = 4;     % L
cfg.CodebookConfig.PhaseAlphabetSize = 8; % NPSK
cfg.CodebookConfig.SubbandAmplitude = true;
cfg.CodebookConfig.numLayers = 2;         % nLayers

i11 = [2, 1];
i12 = [2];
i13 = [3, 1];
i14 = [4, 6, 5, 0, 2, 3, 1 ; 3, 2, 4, 1, 5, 6, 0];
i21 = [1, 3, 4, 2, 5, 7 ; 2, 0, 5, 1, 4, 6];
i22 = [0, 1, 0, 1, 0 ; 1, 1, 0, 0, 1];

i1 = {i11, i12, i13, i14};
i2 = {i21, i22};
```

_Output_
```matlab
i11 = [2, 1]

i12 = [2]

i13 = 3

i14 = [4, 6, 5, 7, 0, 2, 3, 1;
       3, 7, 2, 4, 1, 5, 6, 0]

i21 = [1, 3, 4, 0, 0, 2, 5, 7;
       2, 0, 0, 5, 1, 4, 6, 0]

i22 = [0, 0, 1, 1, 1, 0, 1, 1;
       0, 1, 1, 0, 1, 1, 1, 1]
```

---

### computeN1N2
**Mô tả**  
Tính các chỉ số beam theo lưới anten.

**Input**
- `L`: số layer
- `N1`, `N2`: kích thước lưới anten
- `i12`: chỉ số beam theo chiều N2

**Output**
- `n1`: chỉ số beam theo chiều N1
- `n2`: chỉ số beam theo chiều N2

**Example**

_Output_
```matlab
n1 = [3, 0, 2, 3]

n2 = [2, 3, 3, 3]
```

---

### mappingAmplitudesK1K2ToP1P2
**Mô tả**  
Ánh xạ chỉ số biên độ sang hệ số biên độ.

**Input**
- `i14`: chỉ số tổ hợp beam
- `i22`: chỉ số nhóm biên độ

**Output**
- `p1_li`: hệ số biên độ nhóm 1
- `p2_li`: hệ số biên độ nhóm 2

**Example**

_Output_
```matlab
p1_li = [
    0.3536    0.7071    0.5000    1.0000         0    0.1768    0.2500    0.1250;
    0.2500    1.0000    0.1768    0.3536    0.1250    0.5000    0.7071         0
]

p2_li = [
    0.7071    0.7071    1.0000    1.0000    1.0000    0.7071    1.0000    1.0000;
    0.7071    1.0000    1.0000    0.7071    1.0000    1.0000    1.0000    1.0000
]
```

---

### computePhi
**Mô tả**  
Tính giá trị pha cho các hệ số precoding.

**Input**
- `i14`: chỉ số beam
- `i21`: chỉ số pha
- `L`: số layer
- `NPSK`: bậc PSK

**Output**
- `phi`: ma trận pha của các hệ số precoding

**Example**

_Output_
```matlab
phi = [
    0.7071 + 0.7071i, -0.7071 + 0.7071i, -1.0000 + 0.0000i,  1.0000 + 0.0000i, ...
    1.0000 + 0.0000i,  0.0000 + 1.0000i, -0.7071 - 0.7071i, -0.0000 - 1.0000i;

    0.0000 + 1.0000i,  1.0000 + 0.0000i,  1.0000 + 0.0000i, -0.7071 - 0.7071i, ...
    0.0000 + 1.0000i, -1.0000 + 0.0000i, -0.0000 - 1.0000i,  1.0000 + 0.0000i
]
```

### computePrecodingMatrix

**Mô tả** Tạo ra ma trận đơn vị W_l

**Input**
- `L`: Số lượng layers (lớp truyền dẫn).
- `N1, N2`: Số lượng cổng antenna theo chiều ngang và chiều dọc.
- `O1, O2`: Hệ số oversampling tương ứng cho $N_1$ và $N_2$.
- `n1, n2`: Các chỉ số quay pha hoặc chỉ số beam cơ sở.
- `q1, q2`: Các chỉ số beam bổ trợ.
- `p1_li, p2_li`: Ma trận hệ số biên độ (Likelihood matrices).
- `phi`: Ma trận pha đã tính toán từ hàm `computePhi`.

**Output**
- `W`: Ma trận Precoding (Complex Matrix) dùng cho bộ tạo tín hiệu.

**Example**

_Output_
```matlab
W_l = [
   0.0628 + 0.1030i
   0.0558 - 0.0449i
   0.0284 - 0.0201i
  -0.0340 - 0.0974i
   0.1575 - 0.0687i
  -0.0666 - 0.1455i
  -0.0912 + 0.0059i
  -0.0929 + 0.0603i
  -0.0343 - 0.3944i
  -0.4038 - 0.0558i
  -0.1575 + 0.3032i
   0.1564 + 0.2878i
  -0.2060 - 0.2144i
  -0.2506 + 0.1718i
   0.0628 + 0.2286i
   0.2089 + 0.0929i
  -0.0343 - 0.0343i
  -0.0449 + 0.0186i
  -0.0000 + 0.0486i
   0.0449 + 0.0186i
  -0.0343 + 0.0486i
   0.0317 + 0.0503i
   0.0586 - 0.0101i
   0.0131 - 0.0580i
  -0.0142 - 0.0343i
  -0.0372 + 0.0000i
  -0.0142 + 0.0343i
   0.0263 + 0.0263i
  -0.0829 + 0.0000i
  -0.0317 + 0.0766i
   0.0586 + 0.0586i
   0.0766 - 0.0317i
]
```

### generateTypeIIPrecoder

**Mô tả** Hàm chính thực hiện quy trình tạo ma trận Precoding Type II Codebook theo tiêu chuẩn 5G NR. Hàm này giải mã các chỉ số từ UE phản hồi (CSI feedback) và kết hợp các thành phần không gian (spatial), biên độ (amplitude) và pha (phase) để tạo ra ma trận trọng số tối ưu.

**Input**
- `cfg`: Cấu trúc cấu hình hệ thống (System configuration) bao gồm:
  - `N1, N2`: Số cổng anten (horizontal/vertical).
  - `O1, O2`: Hệ số quá mẫu (oversampling factors).
  - `L`: Số lớp truyền dẫn (layers).
- `i1`: Tập hợp các chỉ số băng rộng (wideband indices) như `i11`, `i12`, `i13`, `i14`.
- `i2`: Tập hợp các chỉ số băng hẹp/phụ (subband indices) như `i21`, `i22`.

**Output**
- `W`: Ma trận Precoding cuối cùng (thường có kích thước $P \times L$, với $P$ là tổng số cổng anten).

**Example**

_Input_
```matlab
cfg = struct();

cfg.CodebookConfig.N1 = 4;
cfg.CodebookConfig.N2 = 4;
cfg.CodebookConfig.O1 = 4;
cfg.CodebookConfig.O2 = 4;

cfg.CodebookConfig.NumberOfBeams = 4;     % L
cfg.CodebookConfig.PhaseAlphabetSize = 8; % NPSK
cfg.CodebookConfig.SubbandAmplitude = true;
cfg.CodebookConfig.numLayers = 2;         % nLayers

i11 = [2, 1];
i12 = [2];
i13 = [3, 1];
i14 = [4, 6, 5, 0, 2, 3, 1 ; 3, 2, 4, 1, 5, 6, 0];
i21 = [1, 3, 4, 2, 5, 7 ; 2, 0, 5, 1, 4, 6];
i22 = [0, 1, 0, 1, 0 ; 1, 1, 0, 0, 1];

i1 = {i11, i12, i13, i14};
i2 = {i21, i22};
```

_Output_
```matlab
W = [
   0.0444 + 0.0728i   0.1286 + 0.0000i
   0.0394 - 0.0317i   0.0369 - 0.1485i
   0.0201 - 0.0142i  -0.1231 - 0.0588i
  -0.0240 - 0.0689i  -0.0891 + 0.0615i
   0.1114 - 0.0486i   0.0588 + 0.0909i
  -0.0471 - 0.1029i   0.0768 - 0.0318i
  -0.0645 + 0.0042i   0.0227 - 0.0604i
  -0.0657 + 0.0426i  -0.0594 - 0.0738i
  -0.0243 - 0.2789i   0.0000 + 0.1740i
  -0.2855 - 0.0394i   0.1311 + 0.0789i
  -0.1114 + 0.2144i   0.1552 - 0.0909i
   0.1106 + 0.2035i  -0.0543 - 0.1905i
  -0.1457 - 0.1516i  -0.0588 + 0.0909i
  -0.1772 + 0.1215i   0.0492 + 0.1188i
   0.0444 + 0.1616i   0.1513 - 0.0227i
   0.1477 + 0.0657i   0.0072 - 0.1362i
  -0.0243 - 0.0243i  -0.0643 - 0.0748i
  -0.0317 + 0.0131i  -0.1024 + 0.0098i
  -0.0000 + 0.0343i  -0.0302 + 0.1211i
   0.0317 + 0.0131i   0.1090 + 0.0532i
  -0.0243 + 0.0343i  -0.0984 + 0.0302i
   0.0224 + 0.0356i  -0.0307 + 0.0937i
   0.0415 - 0.0071i   0.0909 + 0.0804i
   0.0093 - 0.0410i   0.1003 - 0.0742i
  -0.0101 - 0.0243i   0.1070 - 0.0643i
  -0.0263 + 0.0000i  -0.0394 - 0.1147i
  -0.0101 + 0.0243i  -0.0984 - 0.0075i
   0.0186 + 0.0186i  -0.0655 + 0.0793i
  -0.0586 + 0.0000i  -0.0075 - 0.1211i
  -0.0224 + 0.0542i  -0.1234 - 0.0184i
   0.0415 + 0.0415i  -0.0482 + 0.0909i
   0.0542 - 0.0224i   0.0445 + 0.0880i
]
```

---
## 8. Tài liệu tham chiếu

* 3GPP TS 38.214

  * Section 5.2.2.2.3 – Type-II Codebook
  * Tables 5.2.2.2.3-1 → 5.2.2.2.3-5

---
