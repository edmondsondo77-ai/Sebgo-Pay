# 🇧🇫 SebGo Pay - Documentation de l'Architecture Base de Données

## 📌 Présentation Globale
SebGo Pay est une plateforme de paiement mobile multi-pays conçue pour la zone **CEDEAO** (Burkina Faso, Côte d'Ivoire, etc.). L'infrastructure backend repose sur **Supabase (PostgreSQL)** avec une authentification par numéro de téléphone (SMS OTP) et une sécurité rigoureuse via **Row Level Security (RLS)**.

---

## 🗄️ Structure & Rôle des Tables

### 1. `public.profiles`
Gère l'identité des marchands connectés sur le terminal.
- `id` : Identifiant unique relié à la table d'authentification (`auth.users`).
- `phone` : Numéro de téléphone au format international (ex: `+22644085332`).
- `country_code` / `currency` : Paramètres régionaux (`BF`, `CI`, etc. / `XOF`).
- `pin_hash` : Code PIN du marchand chiffré en BCrypt en base de données.
- `is_active` / `kyc_status` : Suivi du statut opérationnel et de conformité.

### 2. `public.transactions`
Enregistre l'historique complet de toutes les opérations financières du terminal.
- `merchant_id` : Clé étrangère liant l'action au marchand propriétaire.
- `escrow_id` : Lien optionnel vers un coffre-fort/séquestre associé.
- `action_type` : Type d'opération (`p2p_transfer`, `my_qr`, `scanner_success`, `share`).
- `amount` / `currency` / `status` : Montant, devise et état (`SUCCESS`).

### 3. `public.escrow`
Gère les flux asynchrones et les liens de paiement sécurisés.
- `payment_token` : Jeton unique transmis dans l'URL de paiement partagée.
- `buyer_phone` / `buyer_country` : Coordonnées et origine de l'acheteur final.
- `status` : État du séquestre (`PENDING`, `SUCCESS`, etc.).

---

## 🔒 Sécurité & Intégrité
- **Hachage Automatique :** Le code PIN saisi par le marchand n'est jamais stocké en clair ; il est intercepté par un trigger et haché via l'extension `pgcrypto` (BCrypt).
- **Isolation RLS :** Chaque table applique une politique de sécurité basée sur `auth.uid() = merchant_id`, empêchant toute fuite de données entre marchands.
- **Suppression en Cascade :** La suppression d'un compte utilisateur supprime automatiquement ses profils, transactions et séquestres associés (`ON DELETE CASCADE`).

---

## 🧪 Configuration de Test Local
Pour éviter d'utiliser un fournisseur SMS payant en phase de développement, les numéros de test suivants sont configurés dans Supabase Auth :

| Numéro de Téléphone | Code OTP de Test |
| :--- | :--- |
| `+22644085332` | `654123` |
| `+2250546155214` | `123456` |