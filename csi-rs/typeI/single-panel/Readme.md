# Type I Single-Panel Codebook – Parameter Description

Tài liệu này giải thích ý nghĩa các tham số được sử dụng trong **Type I Single-Panel codebook**
theo 3GPP TS 38.214, phục vụ cho việc đọc spec, implement code hoặc debug PMI.

---

## 1. Tổng quan

Type I Single-Panel codebook được sử dụng khi gNB và UE làm việc với **một panel anten duy nhất**.
UE không báo cáo trực tiếp ma trận precoding mà chỉ báo **PMI (Precoding Matrix Indicator)**,
tức là các **chỉ số** để gNB tái tạo lại ma trận precoding.

---

## 2. Các tham số cấu hình cao tầng (UE không report)

### N1
- Số phần tử anten theo **chiều azimuth (ngang)** của panel
- Được cấu hình bởi gNB
- Ảnh hưởng đến độ phân giải beam theo phương ngang

### N2
- Số phần tử anten theo **chiều elevation (dọc)** của panel
- Được cấu hình bởi gNB
- Nếu `N2 = 1` → panel 1D (ULA)

---

### O1
- Hệ số oversampling theo **azimuth**
- Quyết định số lượng beam có thể quét theo phương ngang

### O2
- Hệ số oversampling theo **elevation**
- Quyết định số lượng beam theo phương dọc
- Khi `N2 = 1` thì `O2` không có ý nghĩa thực tế

---

## 3. Các tham số UE báo cáo trong PMI

PMI gồm hai nhóm chỉ số chính: **i1** và **i2**

---

## 4. Nhóm i1 – Chỉ số hướng không gian (beam direction)

### i1,1 (l)
- Chỉ số beam theo **phương azimuth**
- Biểu diễn hướng phát chính của beam trên mặt phẳng ngang
- Giá trị lớn → beam lệch nhiều hơn so với trục trung tâm

---

### i1,2 (m)
- Chỉ số beam theo **phương elevation**
- Biểu diễn độ nghiêng của beam theo chiều dọc
- Chỉ có ý nghĩa khi `N2 > 1`
- Khi `N2 = 1` thì `i12` không được báo cáo nên `i12 = 0`

---

### i1,3
- Chỉ xuất hiện khi:
- Số layer (RI) = {2, 3, 4}
- Không phải là beam mới
- Dùng để **ánh xạ logic** sang các beam phụ khi tạo nhiều layer
- Việc ánh xạ cụ thể được quy định bằng bảng `Table 5.2.2.2.1-3` và `Table 5.2.2.2.1-4` trong spec

---

## 5. Nhóm i2 – Chỉ số pha (phase index)

### i2
- Chỉ số lựa chọn **pha tương đối** giữa các beam hoặc layer
- Dùng để cải thiện khả năng phân tách layer

> Lưu ý: hệ số mạnh nhất luôn có pha mặc định, UE **không báo cáo pha cho hệ số này**

---

## 6. RI (Rank Indicator)

- RI là số **layer truyền song song**
- RI quyết định:
  - UE report bao nhiêu chỉ số trong PMI
  - Có hay không sự xuất hiện của `i1,3`
  - Cấu trúc ma trận precoding tại gNB

---

## 7. Những tham số UE KHÔNG báo cáo

UE **không trực tiếp báo cáo**:
- N1, N2
- O1, O2
- Số CSI-RS ports
- Vector beam
- Ma trận precoding

Tất cả các thông tin trên được gNB suy ra từ:
- Cấu hình cao tầng
- PMI
- RI

---

## 8. Tóm tắt nhanh

| Tham số | Ý nghĩa |
|------|-------|
| N1 | Số anten theo azimuth |
| N2 | Số anten theo elevation |
| O1 | Oversampling azimuth |
| O2 | Oversampling elevation |
| i1,1 | Chỉ số beam azimuth |
| i1,2 | Chỉ số beam elevation |
| i1,3 | Chỉ số mapping cho multi-layer |
| i2 | Chỉ số pha |
| RI | Số layer |
| PMI | Tập chỉ số để dựng precoder |

---

## 9. Thông số ví dụ

- 1 Layer:
    - N1 = 2
    - N2 = 1
    - O1 = 4
    - O2 = 2
    - $$i_{1,1}$$ = 0
    - $$i_{1,2}$$ = 0
    - $$i_{2}$$ = 0

- 2 Layer:
    - N1 = 2
    - N2 = 1
    - O1 = 4
    - O2 = 1
    - $$i_{1,1}$$ = 0
    - $$i_{1,2}$$ = 0
    - $$i_{1,3}$$ = 1
    - $$i_{2}$$ = 1

- 1 Layer:
    - N1 = 8
    - N2 = 1
    - O1 = 4
    - O2 = 1
    - $$i_{1,1}$$ = 4
    - $$i_{1,2}$$ = 0
    - $$i_{2}$$ = 2

- 4 Layer:
    - N1 = 4
    - N2 = 2
    - O1 = 4
    - O2 = 2
    - $$i_{1,1}$$ = 2
    - $$i_{1,2}$$ = 1
    - $$i_{1,3}$$ = 0
    - $$i_{2}$$ = 0

---

## 10. Cách dùng các hàm

### validateInputs
**Mô tả**  
Kiểm tra tính hợp lệ của các tham số CSI do UE báo cáo.

**Input**
- `nPorts`: Số lượng Antenna ports
- `N1`: Số phần tử anten theo chiều ngang (horizontal dimension) của panel
- `N2`: Số phần tử anten theo chiều dọc (vertical dimension) của panel
- `O1`: Hệ số oversampling theo chiều ngang dùng cho chỉ số PMI.
- `O2`: Hệ số oversampling theo chiều dọc dùng cho chỉ số PMI.

**Output**
- Không có (chỉ thực hiện kiểm tra)

**Example**

__Input__
```matlab
% cfg.CodebookConfig.nLayers = 1;
% cfg.CodebookConfig.N1 = 2;
% cfg.CodebookConfig.N2 = 1;
% cfg.CodebookConfig.O1 = 4;
% cfg.CodebookConfig.O2 = 2; 
% cfg.CodebookConfig.nPorts = 2 * cfg.CodebookConfig.N1 * cfg.CodebookConfig.N2; % 4 ports
% cfg.CodebookConfig.codebookMode = 1;

N1 = cfg.CodebookConfig.N1;
N2 = cfg.CodebookConfig.N2;
O1 = cfg.CodebookConfig.O1;
O2 = cfg.CodebookConfig.O2;
nPorts = cfg.CodebookConfig.nPorts;
codebookMode = cfg.CodebookConfig.codebookMode;

validateInputs(nPorts, N1, N2, O1, O2);
```

--- 

### computeInputs
**Mô tả**  
Trích xuất và xác định các chỉ số CSI đầu vào từ tập chỉ số UE báo cáo, dựa trên cấu hình anten và số layer truyền.  
Các chỉ số không áp dụng sẽ được gán bằng 0.

**Input**
- `i1`: tập chỉ số beam `{i11, i12, i13}`
- `i2`: tập chỉ số hệ số `{i21, i22}`
- `N2`: số phần tử anten theo chiều dọc
- `nLayers`: số layer truyền

**Output**
- `i11`: chỉ số beam chính
- `i12`: chỉ số beam theo chiều dọc (bằng 0 nếu `N2 = 1`)
- `i13`: chỉ số beam phụ (chỉ được báo khi v = {2, 3, 4})
- `i2`: tập chỉ số hệ số (giữ nguyên)

**Example**

__Input__
```matlab
[i11, i12, i13, i2] = computeInputs(i1, i2, N2, nLayers) ;
```

__Output__
```matlab
i11 = 0;
i12 = 0;
i13 = 0;
i2  = 0;
```

---

### getBeamIndices
**Mô tả**  
Xác định các chỉ số beam hai chiều và chỉ số pha tương ứng cho **Type I Codebook – Single Panel** dựa trên chế độ codebook, số layer truyền và các chỉ số CSI do UE báo cáo.  
Hàm ánh xạ các chỉ số PMI (`i11`, `i12`, `i13`, `i2`) sang các chỉ số beam `(l, m, l′, m′, l″, m″, l‴, m‴)` theo các bảng quy định trong **3GPP TS 38.214**, tương ứng với từng cấu hình rank và codebook mode.

**Input**
- `codebookMode`: chế độ codebook (Mode 1 hoặc Mode 2)
- `nLayers`: số layer truyền
- `i11`: chỉ số beam chính
- `i12`: chỉ số beam theo chiều dọc
- `i13`: chỉ số beam phụ
- `i2`: chỉ số pha
- `N1`: số phần tử anten theo chiều ngang
- `N2`: số phần tử anten theo chiều dọc
- `O1`: hệ số oversampling theo chiều ngang
- `O2`: hệ số oversampling theo chiều dọc

**Output**
- `l`, `m`: chỉ số beam của layer thứ nhất
- `lp`, `mp`: chỉ số beam của layer thứ hai
- `lpp`, `mpp`: chỉ số beam của layer thứ ba
- `lppp`, `mppp`: chỉ số beam của layer thứ tư
- `p`: chỉ số beam bổ sung (áp dụng cho một số cấu hình nhiều layer)
- `n`: chỉ số pha tương ứng với beam

**Example**

__Input__
```matlab
[l, m, lp, mp, lpp, mpp, lppp, mppp, p, n] = getBeamIndices(codebookMode, nPorts, nLayers, i11, i12, i13, i2, N1, N2, O1, O2);
```

__Output__
```matlab
l    = 0;
m    = 0;
lp   = 0;
mp   = 0;
lpp  = 0;
mpp  = 0;
lppp = 0;
mppp = 0;
p    = 0;
n    = 0;
```

---

### getK1K2
**Mô tả**  
Xác định các độ lệch chỉ số beam `(k1, k2)` dùng để tạo các beam phụ cho **Type I Codebook – Single Panel**, dựa trên số layer truyền, cấu hình anten và chỉ số PMI `i13` do UE báo cáo.  
Hàm ánh xạ `i13` sang các giá trị `(k1, k2)` theo các bảng quy định trong **3GPP TS 38.214**, áp dụng cho báo cáo CSI từ 2 đến 4 layer.

**Input**
- `layers`: số layer truyền
- `i13`: chỉ số beam phụ do UE báo cáo
- `N1`: số phần tử anten theo chiều ngang
- `N2`: số phần tử anten theo chiều dọc
- `O1`: hệ số oversampling theo chiều ngang
- `O2`: hệ số oversampling theo chiều dọc

**Output**
- `k1`: độ lệch chỉ số beam theo chiều ngang
- `k2`: độ lệch chỉ số beam theo chiều dọc

### computeBeam
**Mô tả**  
Tính toán vector beam hai chiều cho **Type I Codebook – Single Panel** dựa trên các chỉ số beam theo chiều ngang và chiều dọc.  
Hàm tạo vector steering cho từng chiều và kết hợp chúng bằng phép tích Kronecker để thu được vector beam hoàn chỉnh.

**Input**
- `l`: chỉ số beam theo chiều ngang
- `m`: chỉ số beam theo chiều dọc
- `N1`: số phần tử anten theo chiều ngang
- `N2`: số phần tử anten theo chiều dọc
- `O1`: hệ số oversampling theo chiều ngang
- `O2`: hệ số oversampling theo chiều dọc
- `phaseFactor`: hệ số pha (±1) dùng trong biểu thức tạo beam

**Output**
- `v`: vector beam phức có kích thước `(N1 × N2) × 1`

**Example**

__Input__
```matlab
v_lm = computeBeam(l, m, N1, N2, O1, O2, 2);
```

__Output__
```matlab
v_lm = [1
        1]
```

--- 

### generateTypeISinglePanelPrecoder
**Mô tả**  
Sinh ma trận tiền mã hóa (precoding matrix) cho **Type I Codebook – Single Panel** dựa trên số layer truyền và các chỉ số CSI do UE báo cáo.  
Hàm thực hiện toàn bộ chuỗi xử lý từ kiểm tra tham số, trích xuất chỉ số PMI, xác định chỉ số beam, tạo vector beam và kết hợp chúng để tạo ma trận precoder theo các bảng quy định trong **3GPP TS 38.214**.

**Input**
- `nLayers`: số layer truyền
- `i1`: tập chỉ số beam `{i11, i12, i13}`
- `i2`: chỉ số pha do UE báo cáo

**Output**
- `W`: ma trận tiền mã hóa có kích thước `(nPorts × nLayers)`

**Example**

__Input__
```matlab
cfg.CodebookConfig.nLayers = 1;
cfg.CodebookConfig.N1 = 2;
cfg.CodebookConfig.N2 = 1;
cfg.CodebookConfig.O1 = 4;
cfg.CodebookConfig.O2 = 2; 
cfg.CodebookConfig.nPorts = 2 * cfg.CodebookConfig.N1 * cfg.CodebookConfig.N2; % 4 ports
cfg.CodebookConfig.codebookMode = 1;

i1 = {0, 0, 0, 0}; 
i2 = 0;

W = generateTypeISinglePanelPrecoder(cfg, cfg.CodebookConfig.nLayers, i1, i2);
```

__Output__
```matlab
W = [
    0.5000
    0.5000
    0.5000
    0.5000]
```

---

## 11. Tài liệu tham khảo

- 3GPP TS 38.214  
  Section 5.2.2.2.1 – Type I Single-Panel Codebook
