# 🍽️ GastroHost - Evde Özel Şef & Barmen Pazar Yeri Platformu

GastroHost, ev sahipleri ile profesyonel özel şefleri ve miksolojistleri (barmenleri) konum bazlı olarak buluşturan, rezervasyon, mutfak uygunluk kontrolü, malzeme tedariki ve güvenli ödeme yönetimi sunan iki taraflı bir dikey pazar yeri platformudur.

---

## 📁 Proje Yapısı

Bu proje bir **Monorepo** yapısına sahiptir:

```text
GastroHost/
├── apps/
│   ├── mobile/         # Flutter tabanlı mobil uygulama (iOS & Android)
│   └── web/            # Next.js 15 tabanlı web ve admin yönetim paneli
├── GastroHost_Proje_Dokumani.md # PRD ve Teknik Mimari Dokümanı
└── README.md           # Proje genel kurulum rehberi
```

---

## 🛠️ Kullanılan Teknolojiler

| Katman | Teknoloji / Kütüphaneler |
| :--- | :--- |
| **Mobil Uygulama** | Flutter (Dart), Riverpod, GoRouter, Supabase Flutter SDK, Google Maps SDK, Geolocator |
| **Web & Admin** | Next.js 15, React 19, TypeScript, Tailwind CSS, shadcn/ui, Supabase JS Client |
| **Backend & BaaS** | Supabase (PostgreSQL, Auth, Storage, Realtime) |

---

## 📋 Ön Gereksinimler

Projeyi yerel ortamınızda çalıştırmak için sisteminizde aşağıdaki araçların yüklü olması gerekir:

- [Node.js](https://nodejs.org/) (v18 veya üzeri) & `npm`
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.6.0`)
- [Git](https://git-scm.com/)

---

## 🚀 Kurulum ve Çalıştırma Rehberi

### 1. Repoyu Klonlayın

```bash
git clone https://github.com/Recepyolcu/GastroHost.git
cd GastroHost
```

---

### 2. Web Uygulamasının Kurulumu (`apps/web`)

Web panelini (Next.js) çalıştırmak için:

1. Web klasörüne gidin:
   ```bash
   cd apps/web
   ```

2. Bağımlılıkları yükleyin:
   ```bash
   npm install
   ```

3. `apps/web` dizininde bir `.env.local` dosyası oluşturun ve Supabase bilgilerinizi ekleyin:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://YOUR_SUPABASE_PROJECT_ID.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

4. Geliştirme sunucusunu başlatın:
   ```bash
   npm run dev
   ```
   Web uygulaması varsayılan olarak `http://localhost:3000` adresinde çalışacaktır.

---

### 3. Mobil Uygulamanın Kurulumu (`apps/mobile`)

Flutter mobil uygulamasını çalıştırmak için:

1. Mobil klasörüne gidin:
   ```bash
   cd apps/mobile
   ```

2. Flutter paketlerini indirin:
   ```bash
   flutter pub get
   ```

3. Uygulamayı bir emülatörde veya bağlı cihazda çalıştırın:
   ```bash
   flutter run
   ```

---

## 📌 Yapılması Gerekenler & Yol Haritası (Roadmap)

Projeyi canlı ortama hazırlamak için tamamlanması gereken aşamalar:

- [ ] **Supabase Veritabanı & RLS Kurulumu**: Kullanıcı profilleri, menüler, rezervasyonlar ve konum tabanlı PostGIS fonksiyonlarının Supabase üzerinde yapılandırılması.
- [ ] **Kimlik & Hizmet Sağlayıcı Doğrulaması**: Şef ve barmen başvuruları için Kimlik/Adli Sicil doğrulama ve rozet (Hijyen/Diploma) mekanizmasının entegrasyonu.
- [ ] **Emanet (Escrow) Ödeme Entegrasyonu**: iyzico Pazaryeri veya Stripe Connect kullanarak rezervasyon tutarının bloke edilmesi ve hizmet sonrası şefe aktarılması akışı.
- [ ] **Canlı Durum Makinesi & Push Bildirimleri**: Firebase Cloud Messaging (FCM) ile rezervasyon durum güncellemelerinin (`Alışverişte`, `Yola Çıktı`, `Mutfakta`, `Tamamlandı`) anlık iletilmesi.
- [ ] **1:1 Canlı Sohbet (Realtime Chat)**: Müşteri ve Şef arasındaki özel sohbet odasının Supabase Realtime ile aktif edilmesi.

---

## 📄 Dokümantasyon

Detaylı gereksinimler, veritabanı şeması ve yetki/rol mimarisi için proje kök dizinindeki [GastroHost_Proje_Dokumani.md](file:///c:/Users/hp/Desktop/Coding/getir_chef/GastroHost_Proje_Dokumani.md) dosyasını inceleyebilirsiniz.

---

## 📝 Lisans

Bu proje özel bir mülkiyettir. İzinsiz kopyalanamaz veya dağıtılamaz.
