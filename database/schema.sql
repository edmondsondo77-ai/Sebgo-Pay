-- ====================================================================
-- SEBGO PAY - SCHÉMA DE LA BASE DE DONNÉES (SCHEMA.SQL)
-- Zone CEDEAO / PostgreSQL - Supabase
-- ====================================================================

-- 1. EXTENSIONS REQUISES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. TABLE : PUBLIC.PROFILES (Marchands & Utilisateurs)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    phone TEXT UNIQUE NOT NULL,
    country_code VARCHAR(5) DEFAULT 'BF',
    currency VARCHAR(5) DEFAULT 'XOF',
    role TEXT DEFAULT 'merchant',
    pin_hash TEXT,
    is_active BOOLEAN DEFAULT true,
    kyc_status TEXT DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. TABLE : PUBLIC.ESCROW (Coffre-fort & Liens de paiement)
CREATE TABLE IF NOT EXISTS public.escrow (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(5) DEFAULT 'XOF',
    status TEXT DEFAULT 'PENDING',
    action_type TEXT DEFAULT 'PAYMENT_LINK',
    payment_token TEXT UNIQUE,
    channel TEXT,
    buyer_phone TEXT,
    buyer_country TEXT,
    paid_amount NUMERIC(12, 2),
    paid_currency VARCHAR(5),
    payment_method TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. TABLE : PUBLIC.TRANSACTIONS (Journal des transactions)
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    escrow_id UUID REFERENCES public.escrow(id) ON DELETE SET NULL,
    amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(5) DEFAULT 'XOF',
    status TEXT DEFAULT 'SUCCESS',
    action_type TEXT NOT NULL, -- ex: 'p2p_transfer', 'my_qr', 'scanner_success', 'share'
    channel TEXT,
    payment_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);