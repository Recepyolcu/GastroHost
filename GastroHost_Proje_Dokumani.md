# PROJE GEREKSİNİM VE TEKNİK MİMARİ DOKÜMANI (PRD & TECH SPEC)

**Proje Adı:** GastroHost (Evde Özel Şef & Barmen Pazar Yeri Platformu)  
**Versiyon:** 1.0.0 (MVP)  
**Tarih:** Ağustos 2026  
**Hedef Ortam:** Antigravity / AI Agent Destekli Tam Yığın Geliştirme

---

## 1\. Proje Özeti ve Vizyon

### 1.1. Problem Tanımı

* Dışarıda fine-dining restoran ve nitelikli kokteyl barlarda yemek/içki maliyetlerinin artması ve kalabalık ortamlar.  
* İnsanların evlerinde özel kutlamalar (doğum günü, yıldönümü, arkadaş buluşması) için kişiselleştirilmiş gastronomi hizmeti almak istemesi ancak güvenilir, doğrulanmış ve şeffaf fiyatlı şef/barmen bulma zorluğu.  
* Serbest çalışan (freelance) aşçı ve barmenlerin doğrudan müşteriye ulaşabileceği, takvim ve ödeme garantisi sunan dikey bir pazar yerinin bulunmaması.

### 1.2. Çözüm & Değer Önerisi

GastroHost; ev sahipleri ile profesyonel özel şefleri ve miksolojistleri (barmenleri) konum bazlı olarak buluşturan, rezervasyon, mutfak uygunluk kontrolü, malzeme tedariki, emanet (escrow) usulü güvenli ödeme ve canlı etkinlik takibi sağlayan iki taraflı bir mobil pazar yeri platformudur.

---

## 2\. Kullanıcı Rolleri ve İzinler (RBAC)

1. **Müşteri (Customer / Host):**  
     
   * Konumuna ve etkinlik tarihine göre yakındaki şef ve barmenleri listeleme/filtreleme.  
   * Menüleri, tabak fotoğraflarını ve doğrulanmış değerlendirmeleri inceleme.  
   * Kişi sayısı, mutfak ekipman durumu ve alerjen notlarıyla rezervasyon oluşturma.  
   * Şef hizmetine ek olarak barmen/kokteyl çapraz satışı (upsell) ekleme.  
   * Güvenli ödeme (bloke/escrow) ve hizmet günü canlı süreç takibi.

   

2. **Hizmet Sağlayıcı (Provider \- Şef / Barmen):**  
     
   * Profil oluşturma, uzmanlık alanları, menüler ve kişi başı fiyatlandırma belirleme.  
   * Hizmet yarıçapı (KM) ve haftalık müsaitlik takvimini yönetme.  
   * Gelen rezervasyon taleplerini mutfak/alerjen detaylarıyla inceleme ve onaylama.  
   * Etkinlik günü durum güncellemesi (Alışverişte \-\> Yola Çıktı \-\> Mutfakta \-\> Servis Edildi).  
   * Cüzdan ve hakediş takibi (komisyon sonrası net kazanç).

   

3. **Yönetici (Admin):**  
     
   * Şef/Barmen başvuru onayları (Zorunlu Kimlik ve Adli Sicil doğrulaması; İsteğe bağlı Hijyen Eğitimi Belgesi ve Gastronomi Diploması doğrulaması ile profil rozeti verme).  
   * Pazar yeri komisyon oranları yönetimi (%10 \- %20).  
   * Uyuşmazlık, iade ve iptal yönetimi.

---

## 3\. Fonksiyonel Gereksinimler ve Modüller

### 3.1. Kimlik Doğrulama & Profil Yönetimi

* E-posta/Şifre ve OAuth (Google / Apple) ile kayıt/giriş.  
* Rol seçimi (Müşteri veya Hizmet Sağlayıcı). Tek hesapla mod değiştirme (Switch Profile) desteği.  
* Sağlayıcı Doğrulama & Hibrit Güven Modeli Adımı:
  * **Zorunlu Güvenlik Doğrulamaları:** Kimlik fotoğrafı (T.C. Kimlik No/Pasaport) ve Adli Sicil Kaydı (PDF). Bu aşama şefin sisteme aktif olarak dahil edilmesi için zorunludur.
  * **İsteğe Bağlı Yetkinlik Doğrulamaları (Rozet Sistemi):** Gastronomi Diploması ve Hijyen Belgesi (PDF/Görsel) yükleme. Admin tarafından onaylandığında şef profiline "Diplomalı Şef" veya "Hijyen Sertifikalı" rozetleri eklenir. Yetkinlik belgesi sunmayan şefler/barmenler de sisteme "Onaylı Profil" olarak kayıt olabilir ve güvenilirlikleri müşteri puanları/yorumları ile sağlanır.
  * **Portfolyo Yükleme:** Şeflerin hazırladıkları tabakların/kokteyllerin fotoğraflarını içeren portfolyo görsel yüklemesi.

### 3.2. Konum Bazlı Keşif & Arama (Geo-Discovery)

* PostGIS tabanlı mesafe sorguları (`ST_DWithin`).  
* Filtreler: Mutfak türü (İtalyan, Uzak Doğu, Ege, Barbekü, Diyet), Hizmet tipi (Şef, Barmen, Kombine Paket), Tarih/Saat, Kişi Başı Bütçe, "Malzeme Dahil" filtresi.  
* Liste ve İnteraktif Harita görünümü.

### 3.3. Menü & Hizmet Kataloğu

* Şef menüleri: 3-4 aşamalı tabak yapıları (Başlangıç, Ana Yemek, Tatlı).  
* Barmen menüleri: İmza kokteyl paketleri (kişi başı X adet kokteyl veya saatlik bar servisi).  
* "Malzeme Şeften" (+Fiyat) veya "Malzeme Listesini Müşteri Alır" seçeneği.

### 3.4. Rezervasyon & Mutfak Uygunluk Sihirbazı

1. **Adım 1:** Tarih, Başlangıç Saati, Kişi Sayısı seçimi (Dinamik fiyat çarpanı).  
2. **Adım 2 (Kritik UX):** Mutfak Donanım Anketi:  
   * Ocak Tipi: \[Gazlı | İndüksiyon | Elektrikli\]  
   * Fırın: \[Var | Yok\]  
   * Blender/Mutfak Robotu: \[Var | Yok\]  
   * İsteğe bağlı mutfak fotoğrafı yükleme.  
3. **Adım 3:** Alerjen & Diyet Seçimi (Glüten, Laktoz, Kabuklu Deniz Ürünü vb.).  
4. **Adım 4 (Upsell):** "Bu yemeğin yanına özel kokteyl menüsü için Barmen ekle (+₺X)" seçeneği.  
5. **Adım 5:** Fiyat Özeti & Ön Provizyon (Escrow Ödeme).

### 3.5. Durum Makinesi & Canlı Etkinlik Takibi

Rezervasyon durumları (Booking Lifecycle): `PENDING` \-\> `ACCEPTED` \-\> `SHOPPING` \-\> `ON_THE_WAY` \-\> `IN_KITCHEN` \-\> `COMPLETED` \-\> `PAID_OUT`  
*(İptal durumları: `CANCELLED_BY_HOST`, `CANCELLED_BY_CHEF`)*

### 3.6. Gerçek Zamanlı İletişim & Bildirimler

* Rezervasyon bazlı 1:1 sohbet odası (Supabase Realtime / WebSockets).  
* FCM Anlık Bildirimleri (Yeni talep, şef yola çıktı, mesaj geldi).

### 3.7. Ödeme & Emanet (Escrow) Mimarisi

* Rezervasyon anında müşterinin kartından tutar tahsil edilir ve platform havuzunda bloke edilir.  
* Hizmet tamamlanıp müşteri onay verdiğinde (veya etkinlik bitişinden 12 saat sonra otomatik olarak):  
  * Platform Komisyonu (%15) kesilir.  
  * Kalan bakiye (%85) sağlayıcının cüzdanına / IBAN'ına aktarılır.

---

## 4\. Teknoloji Mimarisi (Tech Stack)

| Katman | Teknoloji | Gerekçe / Detay |
| :---- | :---- | :---- |
| **Mobil İstemci** | **Flutter (Dart)** | iOS & Android tek kod tabanı, Riverpod State Management, 60fps akıcı UI. |
| **Web & Admin Panel** | **Next.js (React) \+ Tailwind CSS \+ shadcn/ui** | SEO uyumlu landing page, hızlı ve zengin yönetim paneli. |
| **Backend & BaaS** | **Supabase (PostgreSQL \+ PostGIS)** | Konum sorguları, Row Level Security (RLS), Realtime WebSocket, Edge Functions. |
| **Harita & Konum** | **Google Maps Platform** | Places API (Adres tamamlama), Maps SDK, Distance Matrix. |
| **Ödeme (Escrow)** | **iyzico Pazaryeri API / Stripe Connect** | İki taraflı pazar yeri alt üye işyeri ve bloke/çözüm akışları. |
| **Bildirimler** | **Firebase Cloud Messaging (FCM)** | Arka plan ve anlık push bildirimleri. |
| **Medya Depolama** | **Cloudflare R2 / Supabase Storage** | Tabak fotoğrafları, mutfak kontrol görselleri, doğrulama belgeleri. |

---

## 5\. Veritabanı Şeması (PostgreSQL \+ PostGIS DDL)

\-- PostGIS Eklentisi

CREATE EXTENSION IF NOT EXISTS postgis;

\-- 1\. Kullanıcılar Tablosu

CREATE TABLE profiles (

    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,

    email TEXT UNIQUE NOT NULL,

    full\_name TEXT NOT NULL,

    phone TEXT,

    avatar\_url TEXT,

    role TEXT CHECK (role IN ('customer', 'chef', 'bartender', 'admin')) DEFAULT 'customer',

    created\_at TIMESTAMPTZ DEFAULT NOW()

);

\-- 2\. Sağlayıcı (Şef / Barmen) Profilleri

CREATE TABLE provider\_profiles (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,

    provider_type TEXT CHECK (provider_type IN ('chef', 'bartender', 'both')) NOT NULL,

    bio TEXT,

    experience_years INT DEFAULT 1,

    service_radius_km INT DEFAULT 15,

    location GEOGRAPHY(Point, 4326), \-- PostGIS Konum Noktası

    is_verified BOOLEAN DEFAULT FALSE, \-- Zorunlu Kimlik ve Adli Sicil onay durumunu belirtir.

    verification_badges JSONB DEFAULT '{"hygiene_cert": false, "diploma": false}'::jsonb, \-- İsteğe bağlı yetkinlik rozetlerinin durumları.

    rating\_avg NUMERIC(3, 2\) DEFAULT 5.00,

    total\_reviews INT DEFAULT 0,

    created\_at TIMESTAMPTZ DEFAULT NOW()

);

CREATE INDEX idx\_provider\_location ON provider\_profiles USING GIST(location);

\-- 3\. Menüler ve Paketler

CREATE TABLE menus (

    id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

    provider\_id UUID REFERENCES provider\_profiles(id) ON DELETE CASCADE,

    title TEXT NOT NULL,

    description TEXT,

    category TEXT NOT NULL, \-- 'italian', 'asian', 'cocktail\_bar', 'bbq', etc.

    price\_per\_person NUMERIC(10, 2\) NOT NULL,

    min\_guests INT DEFAULT 2,

    max\_guests INT DEFAULT 20,

    ingredients\_included BOOLEAN DEFAULT TRUE,

    courses JSONB NOT NULL, \-- \[{'type': 'starter', 'name': '...'}, {'type': 'main', 'name': '...'}\]

    images TEXT\[\] DEFAULT '{}',

    is\_active BOOLEAN DEFAULT TRUE,

    created\_at TIMESTAMPTZ DEFAULT NOW()

);

\-- 4\. Rezervasyonlar (Bookings)

CREATE TABLE bookings (

    id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

    customer\_id UUID REFERENCES profiles(id),

    provider\_id UUID REFERENCES provider\_profiles(id),

    menu\_id UUID REFERENCES menus(id),

    event\_date DATE NOT NULL,

    event\_time TIME NOT NULL,

    guest\_count INT NOT NULL,

    total\_price NUMERIC(10, 2\) NOT NULL,

    platform\_fee NUMERIC(10, 2\) NOT NULL,

    provider\_earnings NUMERIC(10, 2\) NOT NULL,

    status TEXT CHECK (status IN (

        'pending', 'accepted', 'shopping', 'on\_the\_way', 

        'in\_kitchen', 'completed', 'cancelled'

    )) DEFAULT 'pending',

    kitchen\_details JSONB, \-- {'stove\_type': 'gas', 'has\_oven': true, 'photos': \[\]}

    allergies JSONB, \-- \['gluten', 'peanuts'\]

    event\_address TEXT NOT NULL,

    event\_location GEOGRAPHY(Point, 4326),

    created\_at TIMESTAMPTZ DEFAULT NOW()

);

\-- 5\. Ödemeler (Payments & Escrow)

CREATE TABLE payments (

    id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

    booking\_id UUID REFERENCES bookings(id) ON DELETE CASCADE,

    amount NUMERIC(10, 2\) NOT NULL,

    escrow\_status TEXT CHECK (escrow\_status IN ('held', 'released', 'refunded')) DEFAULT 'held',

    provider\_transaction\_id TEXT,

    created\_at TIMESTAMPTZ DEFAULT NOW()

);

\-- 6\. Değerlendirmeler (Reviews)

CREATE TABLE reviews (

    id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

    booking\_id UUID REFERENCES bookings(id) ON DELETE CASCADE,

    customer\_id UUID REFERENCES profiles(id),

    provider\_id UUID REFERENCES provider\_profiles(id),

    rating\_food INT CHECK (rating\_food BETWEEN 1 AND 5),

    rating\_hygiene INT CHECK (rating\_hygiene BETWEEN 1 AND 5),

    rating\_presentation INT CHECK (rating\_presentation BETWEEN 1 AND 5),

    rating\_overall NUMERIC(3, 2\) GENERATED ALWAYS AS ((rating\_food \+ rating\_hygiene \+ rating\_presentation) / 3.0) STORED,

    comment TEXT,

    photos TEXT\[\] DEFAULT '{}',

    created\_at TIMESTAMPTZ DEFAULT NOW()

);

---

## 6\. API ve Servis Sözleşmeleri (API Contracts)

### PostGIS Mesafe Filtreleme Fonksiyonu (Supabase RPC)

CREATE OR REPLACE FUNCTION get\_nearby\_providers(

    user\_lat DOUBLE PRECISION,

    user\_lng DOUBLE PRECISION,

    target\_type TEXT DEFAULT 'chef'

)

RETURNS TABLE (

    provider\_id UUID,

    full\_name TEXT,

    provider\_type TEXT,

    rating\_avg NUMERIC,

    distance\_km DOUBLE PRECISION

) AS $$

BEGIN

    RETURN QUERY

    SELECT 

        p.id,

        pr.full\_name,

        p.provider\_type,

        p.rating\_avg,

        ROUND((ST\_Distance(p.location, ST\_SetSRID(ST\_MakePoint(user\_lng, user\_lat), 4326)::geography) / 1000.0)::numeric, 1)::double precision AS distance\_km

    FROM provider\_profiles p

    JOIN profiles pr ON pr.id \= p.user\_id

    WHERE (p.provider\_type \= target\_type OR p.provider\_type \= 'both')

      AND ST\_DWithin(p.location, ST\_SetSRID(ST\_MakePoint(user\_lng, user\_lat), 4326)::geography, p.service\_radius\_km \* 1000\)

    ORDER BY distance\_km ASC;

END;

$$ LANGUAGE plpgsql;

---

## 7\. Geliştirme Yol Haritası (Milestones)

* **Milestone 1 (Veri & Auth Altyapısı):**  
  * Supabase projesi kurulumu, PostGIS ve RLS kurallarının uygulanması.  
  * Kullanıcı ve Sağlayıcı kayıt/giriş akışları.  
* **Milestone 2 (Keşif & Menü Yönetimi):**  
  * Şeflerin menü ve müsaitlik takvimi ekleme arayüzü.  
  * Müşteri tarafında konum bazlı listeleme ve filtreleme (Flutter).  
* **Milestone 3 (Rezervasyon Sihirbazı & Escrow Ödeme):**  
  * Mutfak uygunluk anketi ve alerjen adımı.  
  * iyzico / Stripe pazar yeri ön provizyon (escrow) entegrasyonu.  
* **Milestone 4 (Canlı Takip, Chat & Tamamlama):**  
  * Sipariş durum makinesi ve FCM push bildirimleri.  
  * Etkinlik günü canlı durum takibi ve değerlendirme sistemi.
