# Type I Multi-Panel Codebook – Parameter Explanation
**(3GPP TS 38.214 – Section 5.2.2.2.2)**

Tài liệu này giải thích **các tham số cấu hình và chỉ số PMI/RI** trong **Type I Multi-Panel codebook**, ngoại trừ:
- Vector beam $v_{l,m}$
- Pha $\varphi$
- Ma trận precoder $W$

---

## 1. $N_g$ (Number of Panels)

- $N_g \in \{2, 4\}$ 
- Là số lượng **panel antenna vật lý**.
- Antenna array được chia thành $N_g$ nhóm độc lập.

**Ảnh hưởng:**
- Số panel quyết định việc có cần báo cáo pha liên panel hay không.
- Quy định `codebookMode` được phép sử dụng.

**Quy tắc:**
- Nếu $N_g = 2 \to$ `codebookMode` có thể là **1** hoặc **2**.
- Nếu $N_g = 4 \to$ `codebookMode` bắt buộc là **1**.

---

## 2. $N_1, N_2$ (Panel Dimensions)

Các giá trị này được cấu hình qua tham số lớp cao `ng-n1-n2`.
- $N_1$: Số antenna theo chiều ngang (chiều 1) trong mỗi panel.
- $N_2$: Số antenna theo chiều dọc (chiều 2) trong mỗi panel.

**Tổng số CSI-RS ports:**
Công thức tính bao gồm hệ số phân cực (x2):

$$P_{CSI-RS} = 2 \times N_g \times N_1 \times N_2$$

**Các cấu hình hỗ trợ (Theo Table 5.2.2.2.2-1):**
| Số Ports | Cấu hình $(N_g, N_1, N_2)$ | Tính toán |
| :---: | :---: | :--- |
| **8** | $(2, 2, 1)$ | $2 \times 2 \times 2 \times 1 = 8$ |
| **16** | $(2, 4, 1)$ | $2 \times 2 \times 4 \times 1 = 16$ |
| **16** | $(4, 2, 1)$ | $2 \times 4 \times 2 \times 1 = 16$ |
| **32** | $(4, 2, 2)$ | $2 \times 4 \times 2 \times 2 = 32$ |

---

## 3. $O_1, O_2$ (Oversampling Factors)

- $O_1$: Hệ số oversampling theo chiều $N_1$.
- $O_2$: Hệ số oversampling theo chiều $N_2$.
- Quy định **độ mịn của beam index**.

UE không tự chọn mà giá trị này phụ thuộc cố định vào cấu hình $(N_g, N_1, N_2)$ theo **Bảng 5.2.2.2.2-1**.

**Ví dụ:**
- Nếu $(N_g, N_1, N_2) = (2, 2, 1) \to (O_1, O_2) = (4, 1)$.
- Nếu $(N_g, N_1, N_2) = (2, 2, 2) \to (O_1, O_2) = (4, 4)$.

---

## 4. codebookMode

Xác định cách sử dụng PMI cấp cao (Higher-layer parameter).

| Mode | Ý nghĩa | Điều kiện áp dụng |
| :---: | :--- | :--- |
| **1** | Cấu trúc PMI đơn giản | Áp dụng cho cả $N_g=2$ và $N_g=4$ |
| **2** | PMI linh hoạt hơn (thêm thông tin pha/biên độ) | Chỉ áp dụng khi $N_g=2$ |

---

## 5. RI (Rank Indicator) – $\nu$

- $\nu \in \{1, 2, 3, 4\}$
- Số **layer truyền** (transmission layers).
- Mỗi giá trị RI sử dụng một bảng codebook riêng biệt được quy định trong chuẩn.

**Bảng tra cứu tương ứng:**
- **RI = 1** $\to$ Table 5.2.2.2.2-3
- **RI = 2** $\to$ Table 5.2.2.2.2-4
- **RI = 3** $\to$ Table 5.2.2.2.2-5
- **RI = 4** $\to$ Table 5.2.2.2.2-6

---

## 6. PMI Structure (Cấu trúc chỉ số Precoding)

PMI bao gồm các chỉ số codebook $i_1$ và $i_2$.

### 6.1 PMI cấp 1 ($i_1$) – Wideband/Long-term
Bao gồm các thành phần:
- $i_{1,1}$: Chỉ số beam theo chiều $N_1$ ($0 \dots N_1O_1 - 1$).
- $i_{1,2}$: Chỉ số beam theo chiều $N_2$ ($0 \dots N_2O_2 - 1$).
- $i_{1,4}$: Chỉ số liên quan đến panel (pha/biên độ liên panel).

**Lưu ý:** Nếu $N_2 = 1$, UE không báo cáo $i_{1,2}$ (mặc định bằng 0).

---

## 6. Chi tiết cấu trúc PMI ($i_1, i_2$)

Mỗi báo cáo PMI được xác định bởi cặp chỉ số codebook $(i_1, i_2)$. Cấu trúc của các vector này thay đổi chính xác theo công thức dưới đây.

### 6.1 Vector $i_1$ (Wideband/Long-term)
Cấu trúc của $i_1$ phụ thuộc vào Rank ($\nu$) như sau:

$$
i_1 = 
\begin{cases} 
[i_{1,1}, \ i_{1,2}, \ i_{1,4}] & \text{khi } \nu = 1 \\
[i_{1,1}, \ i_{1,2}, \ i_{1,3}, \ i_{1,4}] & \text{khi } \nu \in \{2, 3, 4\}
\end{cases}
$$

**Giải thích các thành phần:**
1.  **$i_{1,1}$**: Beam index theo chiều $N_1$.
2.  **$i_{1,2}$**: Beam index theo chiều $N_2$.
3.  **$i_{1,3}$**: Chỉ số mapping layer (Có mặt trong vector khi Rank $\ge 2$).
4.  **$i_{1,4}$**: Chỉ số liên quan đến đồng pha panel (Xem mục 6.2).

### 6.2 Cấu trúc $i_{1,4}$ và $i_2$ theo codebookMode

#### Trường hợp A: codebookMode = 1
Khi `codebookMode` được đặt là '1', cấu trúc của $i_{1,4}$ phụ thuộc vào số lượng panel ($N_g$):

$$
i_{1,4} = 
\begin{cases} 
i_{1,4,1} & \text{khi } N_g = 2 \text{ (1 giá trị)} \\
[i_{1,4,1}, \ i_{1,4,2}, \ i_{1,4,3}] & \text{khi } N_g = 4 \text{ (3 giá trị)}
\end{cases}
$$

*(Trong mode này, $i_2$ thường là một giá trị đơn lẻ tùy theo bảng).*

#### Trường hợp B: codebookMode = 2
Khi `codebookMode` được đặt là '2', cấu trúc vector mở rộng như sau:

$$
\begin{aligned}
i_{1,4} &= [i_{1,4,1}, \ i_{1,4,2}] \\
i_2 &= [i_{2,0}, \ i_{2,1}, \ i_{2,2}]
\end{aligned}
$$

---

## 7. Cấu hình hạn chế (Restriction)

### 7.1 ng-n1-n2 Restriction
- Là một bitmap $a_{A_c-1}, \dots, a_0$.
- **Bit = 0**: Báo cáo PMI tương ứng bị cấm (không được dùng precoder đó).
- Tổng số bit: $A_c = N_1 O_1 N_2 O_2$.

### 7.2 ri-Restriction
- Là chuỗi bit $r_3, r_2, r_1, r_0$ tương ứng với 4 layer.
- **Bit $r_i$ = 0**: Cấm báo cáo RI = $i+1$.
- Ví dụ: Nếu $r_0 = 0 \to$ Không được báo cáo Rank 1.

---

## 8. CSI-RS Port Indexing

Các cổng antenna CSI-RS được đánh số bắt đầu từ 3000.
- Dải cổng: $3000$ đến $3000 + P_{CSI-RS} - 1$.
- Ví dụ: Với 8 ports, các cổng là $3000, 3001, \dots, 3007$.

---

## 9. Ví dụ Minh Họa Giá Trị Báo Cáo (Examples)

Dưới đây là các ví dụ cụ thể về bộ giá trị $(i_1, i_2)$ trong báo cáo thực tế, minh họa sự khác biệt giữa Mode 1 và Mode 2.

### Ví dụ 1: Cấu hình 2 Panel, Rank 1 (Mode 1)
**Cấu hình:**
- $N_g = 2$
- $N_1 = 4, N_2 = 1$
- `codebookMode` = 1
- **Rank ($\nu$) = 1**

**Giá trị báo cáo:**
- **$i_1$ (Wideband):**
    - $i_{1,1} = 1$
    - $i_{1,2} = 0$ (Mặc định do $N_2=1$)
    - **$i_{1,4} = 1$** (Chỉ 1 giá trị pha liên panel do Mode 1)
- **$i_2$ (Subband):**
    - **$i_2 = 0$** (Giá trị đơn - Scalar)

---

### Ví dụ 2: Cấu hình 4 Panel, Rank 2 (Mode 1)
**Cấu hình:**
- $N_g = 4$
- $N_1 = 2, N_2 = 1$
- `codebookMode` = 1 (Bắt buộc với $N_g=4$)
- **Rank ($\nu$) = 2**

**Giá trị báo cáo:**
- **$i_1$ (Wideband):**
    - $i_{1,1} = 2$
    - $i_{1,2} = 0$
    - **$i_{1,3} = 0$** (Có mặt do Rank $\ge 2$ để map layer)
    - **$i_{1,4} = [1, 0, 2]$** (Vector 3 phần tử do $N_g=4$)
- **$i_2$ (Subband):**
    - **$i_2 = 1$** (Giá trị đơn - Scalar)

---

### Ví dụ 3: Cấu hình 2 Panel, Rank 2 (Mode 2 - Chi tiết cao)
*Đây là chế độ phức tạp nhất, cung cấp thông tin pha/biên độ chi tiết hơn.*

**Cấu hình:**
- $N_g = 2$
- $N_1 = 4, N_2 = 1$
- `codebookMode` = 2 (Chỉ áp dụng được khi $N_g=2$)
- **Rank ($\nu$) = 2**

**Giá trị báo cáo:**
Do Mode = 2, cả $i_{1,4}$ và $i_2$ đều chuyển thành dạng vector mở rộng.

- **$i_1$ (Wideband):**
    - $i_{1,1} = 3$
    - $i_{1,2} = 0$
    - $i_{1,3} = 1$ (Layer Mapping)
    - **$i_{1,4} = [1, 2]$** (Vector **2 phần tử** thay vì 1 như ở Mode 1)
- **$i_2$ (Subband):**
    - **$i_2 = [0, 1, 0]$** (Vector **3 phần tử** $[i_{2,0}, i_{2,1}, i_{2,2}]$ thay vì giá trị đơn)

---

## 10. Cách dùng các hàm

# generateTypeIMultiPanelPrecoder

### Mô tả
Hàm `generateTypeIMultiPanelPrecoder` tạo ma trận tiền mã hóa (precoding matrix) cho hệ thống MIMO đa bảng (Multi-Panel) theo chuẩn 5G NR (Type I Multi-Panel Codebook - 3GPP TS 38.214). Hàm tính toán các trọng số phức dựa trên cấu hình codebook, số lớp (rank), số lượng panel ($N_g$) và các chỉ số PMI ($i_1, i_2$).

### Input
* **`cfg`** (Struct): Cấu hình hệ thống.
    * `CodebookConfig.N1`: Số cổng ăng-ten ngang mỗi panel.
    * `CodebookConfig.N2`: Số cổng ăng-ten dọc mỗi panel.
    * `CodebookConfig.O1`: Hệ số lấy mẫu dư (Oversampling) ngang.
    * `CodebookConfig.O2`: Hệ số lấy mẫu dư (Oversampling) dọc.
    * `CodebookConfig.nPorts`: Tổng số cổng ăng-ten.
    * `CodebookConfig.codebookMode`: Chế độ codebook (1 hoặc 2).
* **`nLayers`** (Int): Số lớp truyền dẫn (Rank).
* **`Ng`** (Int): Số lượng panel ăng-ten.
* **`i1`** (Cell Array): Chỉ số PMI băng rộng `{i11, i12, i13, i14}`.
* **`i2`** (Vector): Chỉ số PMI băng con.

### Output
* **`W`** (Matrix): Ma trận tiền mã hóa phức (`double`), kích thước $N_{ports} \times nLayers$.

### Ví dụ sử dụng

__Input__

```matlab
cfg.CodebookConfig.N1 = 4;
cfg.CodebookConfig.N2 = 1;
cfg.CodebookConfig.O1 = 4;
cfg.CodebookConfig.O2 = 1;
cfg.CodebookConfig.nPorts = 16;
cfg.CodebookConfig.codebookMode = 2;

nLayers = 2;
Ng = 2;

i11 = 3;
i12 = 0;
i13 = 1;
i14 = [1, 2];

i2 = [0, 1, 0];

i1 = {i11, i12, i13, i14};

W = generateTypeIMultiPanelPrecoder(cfg, nLayers, Ng, i1, i2);
```

__Output__

```matlab
W = [
   0.1768 + 0.0000i   0.1768 + 0.0000i
   0.0676 + 0.1633i  -0.0676 - 0.1633i
  -0.1250 + 0.1250i  -0.1250 + 0.1250i
  -0.1633 - 0.0676i   0.1633 + 0.0676i
   0.1768 + 0.0000i  -0.1768 + 0.0000i
   0.0676 + 0.1633i   0.0676 + 0.1633i
  -0.1250 + 0.1250i   0.1250 - 0.1250i
  -0.1633 - 0.0676i  -0.1633 - 0.0676i
  -0.1768 + 0.0000i  -0.1768 + 0.0000i
  -0.0676 - 0.1633i   0.0676 + 0.1633i
   0.1250 - 0.1250i   0.1250 - 0.1250i
   0.1633 + 0.0676i  -0.1633 - 0.0676i
  -0.1768 + 0.0000i   0.1768 - 0.0000i
  -0.0676 - 0.1633i  -0.0676 - 0.1633i
   0.1250 - 0.1250i  -0.1250 + 0.1250i
   0.1633 + 0.0676i   0.1633 + 0.0676i ]
```

---

# computeInputs

### Mô tả
Hàm phụ trợ dùng để trích xuất và chuẩn hóa các thành phần chỉ số PMI từ cấu trúc dữ liệu đầu vào. Hàm xử lý logic gán giá trị mặc định (bằng 0) cho các chỉ số không được sử dụng dựa trên cấu hình anten ($N_2$) và số lớp truyền dẫn (Rank).

### Input
- `nLayers`: Số lượng lớp truyền dẫn (Transmission Rank, $\nu$).
- `i1`: Cell array chứa các chỉ số PMI wideband, cấu trúc `{i11, i12, i13, i14}`.
- `i2`: Chỉ số hoặc vector chỉ số PMI subband.
- `N2`: Số phần tử anten theo chiều dọc (vertical dimension) của panel.

### Output
- `i11`: Chỉ số trực giao nhóm tia thứ nhất ($i_{1,1}$).
- `i12`: Chỉ số trực giao nhóm tia thứ hai ($i_{1,2}$). Trả về **0** nếu $N_2 = 1$.
- `i13`: Chỉ số ánh xạ lớp ($i_{1,3}$). Trả về **0** nếu `nLayers` = 1.
- `i14`: Hệ số đồng pha giữa các panel ($i_{1,4}$), lấy từ phần tử thứ 4 của `i1`.
- `i2`: Chỉ số subband ($i_2$), giữ nguyên từ đầu vào.

### Ví dụ sử dụng

__Input__

```matlab
cfg.CodebookConfig.N2 = 1;

nLayers = 2;
Ng = 2;

i11 = 3;
i12 = 0;
i13 = 1;
i14 = [1, 2];

i2 = [0, 1, 0];

i1 = {i11, i12, i13, i14};

[i11, i12, i13, i14, i2] = computeInputs(nLayers, i1, i2, N2);
```

__Output__

```matlab
i11 = 3

i12 = 0

i13 = 1

i14 = [1     2]

i2 = [0     1     0]
```

---

# validateInputs

### Mô tả
Hàm `validateInputs` thực hiện kiểm tra tính hợp lệ của toàn bộ các tham số cấu hình hệ thống, cấu trúc codebook và các chỉ số PMI ($i_1, i_2$) đầu vào. Hàm này đảm bảo các giá trị nằm trong phạm vi cho phép theo chuẩn 3GPP TS 38.214 trước khi thực hiện tính toán tiền mã hóa. Nếu có tham số không hợp lệ, hàm sẽ trả về lỗi.

### Input
* **`codebookMode`** (Int): Chế độ codebook (1 hoặc 2).
* **`nLayers`** (Int): Số lượng lớp truyền dẫn (Rank).
* **`Ng`** (Int): Số lượng panel ăng-ten.
* **`N1`** (Int): Số cổng ăng-ten ngang mỗi panel.
* **`N2`** (Int): Số cổng ăng-ten dọc mỗi panel.
* **`O1`** (Int): Hệ số lấy mẫu dư ngang.
* **`O2`** (Int): Hệ số lấy mẫu dư dọc.
* **`i11`** (Int): Chỉ số chùm tia $i_{1,1}$.
* **`i12`** (Int): Chỉ số chùm tia $i_{1,2}$.
* **`i13`** (Int): Chỉ số tập hợp chùm tia $i_{1,3}$ (Mode 2).
* **`i14`** (Vector): Chỉ số đồng pha băng rộng $i_{1,4}$.
* **`i2`** (Vector): Các chỉ số PMI băng con/đồng pha.
* **`nPorts`** (Int): Tổng số cổng ăng-ten.

### Output
* **Không có giá trị trả về (Void)**: Hàm sẽ thực hiện im lặng nếu tất cả dữ liệu đều hợp lệ. Nếu phát hiện lỗi (ví dụ: chỉ số index vượt quá giới hạn, sai kích thước vector), hàm sẽ ném ra lỗi (throw error) và dừng chương trình.

### Ví dụ sử dụng

__Input__

```matlab
% cfg.CodebookConfig.N1 = 4;
% cfg.CodebookConfig.N2 = 1;
% cfg.CodebookConfig.O1 = 4;
% cfg.CodebookConfig.O2 = 1;
% cfg.CodebookConfig.nPorts = 16;
% cfg.CodebookConfig.codebookMode = 2;

N1 = cfg.CodebookConfig.N1;
N2 = cfg.CodebookConfig.N2;
O1 = cfg.CodebookConfig.O1;
O2 = cfg.CodebookConfig.O2;
nPorts = cfg.CodebookConfig.nPorts;
codebookMode = cfg.CodebookConfig.codebookMode;

nLayers = 2;
Ng = 2;

i11 = 3;
i12 = 0;
i13 = 1;
i14 = [1, 2];

i2 = [0, 1, 0];

i1 = {i11, i12, i13, i14};

[i11, i12, i13, i14, i2] = computeInputs(nLayers, i1, i2, N2)

validateInputs(codebookMode, nLayers, Ng, N1, N2, O1, O2, i11, i12, i13, i14, i2, nPorts);
```

---

# computeBeam

### Mô tả  
Tính toán vector beam hai chiều cho **Type I Codebook – Single Panel** dựa trên các chỉ số beam theo chiều ngang và chiều dọc.  
Hàm tạo vector steering cho từng chiều và kết hợp chúng bằng phép tích Kronecker để thu được vector beam hoàn chỉnh.

### Input
- `l`: chỉ số beam theo chiều ngang
- `m`: chỉ số beam theo chiều dọc
- `N1`: số phần tử anten theo chiều ngang
- `N2`: số phần tử anten theo chiều dọc
- `O1`: hệ số oversampling theo chiều ngang
- `O2`: hệ số oversampling theo chiều dọc
- `phaseFactor`: hệ số pha (±1) dùng trong biểu thức tạo beam

### Output
- `v`: vector beam phức có kích thước `(N1 × N2) × 1`

### Ví dụ sử dụng

__Input__

```matlab
v_lm = computeBeam(l, m, N1, N2, O1, O2, 2);
```

__Output__

```matlab
v_lm = [
   1.0000 + 0.0000i
   0.3827 + 0.9239i
  -0.7071 + 0.7071i
  -0.9239 - 0.3827i ]
```

---

# calcWMatrixMultiPanel

### Mô tả
Hàm `calcWMatrixMultiPanel` tính toán một vector cột cụ thể (hoặc một phần của vector) cho ma trận tiền mã hóa trong cấu hình Multi-Panel. Hàm này thực hiện việc kết hợp vector chùm tia DFT ($v_{lm}$) với các hệ số pha (co-phasing) tương ứng với cấu trúc phân cực và vị trí của các panel ăng-ten để tạo ra các trọng số phức cuối cùng.

### Input
* **`p`** (Scalar/Complex): Hệ số đồng pha (co-phasing coefficient) hoặc chỉ số pha tương ứng.
* **`n`** (Int): Tham số chỉ số (thường liên quan đến panel hiện tại hoặc chỉ số phân cực).
* **`n_g`** (Int): Tổng số lượng panel ăng-ten ($N_g$).
* **`idx1`** (Int): Tham số cấu hình nội bộ 1 (ví dụ: chỉ số phân cực hoặc nhóm).
* **`idx2`** (Int): Tham số cấu hình nội bộ 2 (ví dụ: chỉ số thứ tự panel).
* **`v_lm`** (Vector): Vector chùm tia DFT (Discrete Fourier Transform) cơ sở.
* **`nPorts`** (Int): Tổng số cổng ăng-ten hệ thống.

### Output
* **`w_idx1`** (Vector): Vector cột trọng số phức (`double complex`).
    * Kích thước: `nPorts` $\times$ 1.
    * Đại diện cho một cột (hoặc một thành phần) của ma trận tiền mã hóa $W$.

### Ví dụ sử dụng

__Input__

```matlab
w_idx1 = calcWMatrixMultiPanel(p, n, n_g, 1, 2, v_lm, nPorts);
```

__Output__

```matlab
w_idx1 = [
   0.2500 + 0.0000i
   0.0957 + 0.2310i
  -0.1768 + 0.1768i
  -0.2310 - 0.0957i
   0.2500 + 0.0000i
   0.0957 + 0.2310i
  -0.1768 + 0.1768i
  -0.2310 - 0.0957i
  -0.2500 + 0.0000i
  -0.0957 - 0.2310i
   0.1768 - 0.1768i
   0.2310 + 0.0957i
  -0.2500 + 0.0000i
  -0.0957 - 0.2310i
   0.1768 - 0.1768i
   0.2310 + 0.0957i ]
```