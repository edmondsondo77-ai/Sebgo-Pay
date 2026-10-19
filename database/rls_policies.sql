-- ====================================================================
-- SEBGO PAY - POLITIQUES RLS / SÉCURITÉ (RLS_POLICIES.SQL)
-- ====================================================================

-- ACTIVATION DU RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow ENABLE ROW LEVEL SECURITY;

-- 1. POLITIQUES POUR PUBLIC.PROFILES
CREATE POLICY "Les marchands peuvent lire leur propre profil"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Les marchands peuvent modifier leur propre profil"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- 2. POLITIQUES POUR PUBLIC.TRANSACTIONS
CREATE POLICY "Les marchands voient uniquement leurs transactions"
  ON public.transactions FOR SELECT
  USING (auth.uid() = merchant_id);

CREATE POLICY "Les marchands peuvent insérer leurs propres transactions"
  ON public.transactions FOR INSERT
  WITH CHECK (auth.uid() = merchant_id);

-- 3. POLITIQUES POUR PUBLIC.ESCROW
CREATE POLICY "Les marchands voient leurs propres séquestres"
  ON public.escrow FOR SELECT
  USING (auth.uid() = merchant_id);

CREATE POLICY "Les marchands peuvent créer des liens séquestres"
  ON public.escrow FOR INSERT
  WITH CHECK (auth.uid() = merchant_id);

CREATE POLICY "Les marchands peuvent mettre à jour leurs séquestres"
  ON public.escrow FOR UPDATE
  USING (auth.uid() = merchant_id);