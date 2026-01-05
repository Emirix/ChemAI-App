# Company Management Feature - Setup Guide

## 📋 Genel Bakış

TDS ve SDS belgelerine eklenecek tedarikçi/firma bilgilerini yönetmek için oluşturulan kapsamlı firma yönetim sistemi.

---

## 🗄️ Veritabanı Kurulumu

### Supabase SQL Migration

1. Supabase Dashboard'a gidin: https://supabase.com/dashboard
2. Projenizi seçin
3. Sol menüden **SQL Editor**'ü açın
4. `backend/migrations/001_create_companies_table.sql` dosyasının içeriğini kopyalayın
5. SQL Editor'e yapıştırın ve **Run** butonuna tıklayın

### Tablo Yapısı

```sql
companies (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  company_name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  postal_code TEXT,
  country TEXT,
  phone TEXT,
  emergency_phone TEXT,
  email TEXT NOT NULL,
  website TEXT,
  fax TEXT,
  logo_url TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

---

## 🔧 Backend API Endpoints

Tüm endpoint'ler `/api` prefix'i altındadır:

### 1. **Get All Companies**
```http
POST /api/companies
Content-Type: application/json

{
  "userId": "user-uuid"
}
```

### 2. **Get Company By ID**
```http
POST /api/companies/get
Content-Type: application/json

{
  "companyId": "company-uuid",
  "userId": "user-uuid"
}
```

### 3. **Create Company**
```http
POST /api/companies/create
Content-Type: application/json

{
  "userId": "user-uuid",
  "companyName": "Kimya Grup A.Ş.",
  "email": "info@kimyagrup.com",
  "phone": "+90 212 XXX XX XX",
  "emergencyPhone": "+90 212 XXX XX XX",
  "address": "Örnek Mahallesi, Kimya Sokak No:1",
  "city": "İstanbul",
  "postalCode": "34000",
  "country": "Türkiye",
  "website": "www.kimyagrup.com",
  "fax": "+90 212 XXX XX XX",
  "logoUrl": null,
  "isDefault": true
}
```

### 4. **Update Company**
```http
POST /api/companies/update
Content-Type: application/json

{
  "companyId": "company-uuid",
  "userId": "user-uuid",
  "companyName": "Updated Name",
  ... (diğer alanlar)
}
```

### 5. **Delete Company**
```http
POST /api/companies/delete
Content-Type: application/json

{
  "companyId": "company-uuid",
  "userId": "user-uuid"
}
```

### 6. **Set Default Company**
```http
POST /api/companies/set-default
Content-Type: application/json

{
  "companyId": "company-uuid",
  "userId": "user-uuid"
}
```

### 7. **Get Default Company**
```http
POST /api/companies/default
Content-Type: application/json

{
  "userId": "user-uuid"
}
```

---

## 📱 Flutter Kullanımı

### Company Management Screen'e Gitme

```dart
import 'package:chem_ai/screens/company_management_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';

// Navigation
NavigationUtils.pushWithSlide(
  context,
  const CompanyManagementScreen(),
);
```

### Company Service Kullanımı

```dart
import 'package:chem_ai/services/company_service.dart';
import 'package:chem_ai/models/company.dart';

final _companyService = CompanyService();
final userId = 'user-uuid';

// Get all companies
List<Company> companies = await _companyService.getCompanies(userId);

// Get default company
Company? defaultCompany = await _companyService.getDefaultCompany(userId);

// Create company
final newCompany = Company(
  userId: userId,
  companyName: 'Kimya A.Ş.',
  email: 'info@kimya.com',
  phone: '+90 212 XXX XX XX',
  address: 'Adres',
  city: 'İstanbul',
  country: 'Türkiye',
  isDefault: true,
);

Company? created = await _companyService.createCompany(newCompany);
```

---

## 🔗 TDS/SDS Entegrasyonu

### TDS ve SDS ekranlarında company seçimi eklemek için:

```dart
// Get default company
final company = await CompanyService().getDefaultCompany(userId);

if (company != null) {
  // Company bilgilerini TDS/SDS data'ya ekle
  final companyInfo = {
    'companyName': company.companyName,
    'address': company.getFullAddress(),
    'phone': company.phone,
    'emergencyPhone': company.emergencyPhone,
    'email': company.email,
    'website': company.website,
  };
  
  // PDF generation'a gönder
}
```

---

## 📝 TDS ve SDS Belgelerinde Kullanılan Firma Bilgileri

### Zorunlu Alanlar:
- ✅ Şirket Adı (Company Name)
- ✅ E-posta (Email)

### Önerilen Alanlar:
- 📞 Telefon (Phone)
- 🚨 Acil Durum Telefonu (Emergency Phone)
- 📍 Adres (Address)
- 🏙️ Şehir (City)
- 📮 Posta Kodu (Postal Code)
- 🌍 Ülke (Country)
- 🌐 Website

### Opsiyonel Alanlar:
- 📠 Fax
- 🖼️ Logo URL

---

## ✨ Özellikler

- ✅ **CRUD İşlemleri**: Tam create, read, update, delete desteği
- ✅ **Varsayılan Firma**: Bir firmayı varsayılan olarak işaretleme
- ✅ **Detaylı Form**: Tüm firma bilgileri için kapsamlı form
- ✅ **Validasyon**: Form validasyonu ve hata yönetimi
- ✅ **Dark Mode**: Tam dark mode desteği
- ✅ **Material Design**: Modern ve tutarlı UI

---

## 🎨 UI Component'leri

### CompanyManagementScreen
- Firma listesi görünümü
- Empty state
- Firma kartları (varsayılan badge ile)
- Silme, düzenleme, varsayılan yapma butonları

### CompanyFormScreen
- Yeni firma ekleme
- Mevcut firmayı düzenleme
- Kategorize edilmiş input alanları:
  - Temel Bilgiler
  - İletişim Bilgileri
  - Adres Bilgileri
- Varsayılan checkbox

---

## 🔐 Güvenlik

- Row Level Security (RLS) politikaları aktif
- User ID bazlı yetkilendirme
- Güvenli API endpoint'leri

---

## 📊 Veritabanı İndeksler

- `idx_companies_user_id`: user_id üzerinde hızlı sorgular
- `idx_companies_is_default`: Varsayılan firma için hızlı  lookup

---

## 🚀 Sonraki Adımlar

1. ✅ Supabase migration'ı çalıştırın
2. ⏭️ TDS Screen'e company seçim widget'ı ekleyin
3. ⏭️ SDS Screen'e company seçim widget'ı ekleyin
4. ⏭️ PDF generation'da company bilgilerini kullanın
5. ⏭️ Profile screen'den Company Management'a link ekleyin

---

## 📞 Test

Backend server'ı çalıştırın:
```bash
cd backend
npm run dev
```

Flutter uygulamasını çalıştırın:
```bash
flutter run
```

---

## 💡 Notlar

- Backend `companyController.js` dosyası tüm iş mantığını içerir
- Flutter `CompanyService` servisi API çağrılarını yönetir
- `Company` modeli tüm firma verilerini temsil eder
- SQL migration Supabase'de manuel olarak çalıştırılmalıdır

---

**Geliştirici**: ChemAI Team  
**Tarih**: 2026-01-04  
**Versiyon**: 1.0.0
