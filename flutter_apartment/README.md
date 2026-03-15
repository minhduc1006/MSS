# Skyline Heights Flutter

Ban Flutter day duoc chuyen tu du an React/Vite trong `apartment.zip`.

## Co gi trong ban nay
- Dang nhap 3 vai tro: Resident, Staff, Admin
- Giao dien quan tri, cu dan, nhan vien
- Drawer va bottom navigation
- Dark mode
- Snackbar, modal, form, bo loc
- Tai file thuc cho cac chuc nang download/export bang `file_saver`
- Da co scaffold platform cho Android, iOS, Web, Windows, Linux, macOS

## Chay du an
1. Cai Flutter SDK ban on dinh moi nhat
2. Khoi dong backend microservices truoc.
3. Chay:
   ```bash
   flutter pub get
   flutter run
   ```
4. Neu can doi host backend, truyen cac `--dart-define` nhu:
   ```bash
   flutter run --dart-define=API_HOST=http://10.0.2.2
   ```

## Ghi chu
- Ung dung hien chi dung du lieu that tu backend microservices.
- Neu backend khong chay hoac sai `API_HOST`, man hinh se bao loi thay vi roi ve mock data.
