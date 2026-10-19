-- ====================================================================
-- SEBGO PAY - DÉCLENCHEURS ET FONCTIONS (TRIGGERS_AND_FUNCTIONS.SQL)
-- ====================================================================

-- 1. FONCTION DE CRÉATION AUTOMATIQUE DU PROFIL À L'INSCRIPTION AUTH
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, role, created_at, updated_at)
  VALUES (new.id, new.phone, 'merchant', now(), now())
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. HACHAGE AUTOMATIQUE DU CODE PIN MARCHAND (BCrypt)
CREATE OR REPLACE FUNCTION public.hash_merchant_pin()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.pin_hash IS NOT NULL AND (TG_OP = 'INSERT' OR NEW.pin_hash <> OLD.pin_hash) THEN
    IF length(NEW.pin_hash) < 50 THEN
      NEW.pin_hash := crypt(NEW.pin_hash, gen_salt('bf'));
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_hash_pin ON public.profiles;
CREATE TRIGGER trigger_hash_pin
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.hash_merchant_pin();

-- 3. MISE À JOUR AUTOMATIQUE DU CHAMP UPDATED_AT
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON public.profiles;
CREATE TRIGGER trigger_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trigger_escrow_updated_at ON public.escrow;
CREATE TRIGGER trigger_escrow_updated_at
  BEFORE UPDATE ON public.escrow
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trigger_transactions_updated_at ON public.transactions;
CREATE TRIGGER trigger_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();