-- Billetera Virtual - Supabase Schema COMPLETO
-- Ejecutar este script en el SQL Editor de Supabase
-- IMPORTANTE: Reemplazar 'UID_ADMIN' con el UID real de tu admin

-- =====================================================
-- TABLAS
-- =====================================================

-- Usuarios
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  cvu TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Billeteras (cada usuario tiene 2: ARS y USD)
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  currency TEXT NOT NULL CHECK (currency IN ('ARS', 'USD')),
  balance DECIMAL(15,2) DEFAULT 0.00,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, currency)
);

-- Transacciones
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_wallet_id UUID REFERENCES wallets(id),
  to_wallet_id UUID REFERENCES wallets(id),
  type TEXT NOT NULL CHECK (type IN ('transfer', 'deposit', 'withdraw', 'convert')),
  amount DECIMAL(15,2) NOT NULL,
  currency TEXT NOT NULL,
  exchange_rate DECIMAL(10,4),
  description TEXT,
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Solicitudes de deposito
CREATE TABLE IF NOT EXISTS deposit_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL,
  currency TEXT NOT NULL CHECK (currency IN ('ARS', 'USD')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  proof_url TEXT,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- Solicitudes de retiro
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL,
  currency TEXT NOT NULL CHECK (currency IN ('ARS', 'USD')),
  destination_cbu TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- Cotizacion USD
CREATE TABLE IF NOT EXISTS exchange_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buy_rate DECIMAL(10,2) NOT NULL,
  sell_rate DECIMAL(10,2) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insertar cotizacion inicial (solo si tabla vacia)
INSERT INTO exchange_rates (buy_rate, sell_rate)
SELECT 1200.00, 1250.00
WHERE NOT EXISTS (SELECT 1 FROM exchange_rates);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposit_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_rates ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLICIES USUARIOS (solo ven/editan lo suyo)
-- =====================================================

-- USERS
DROP POLICY IF EXISTS "user select own" ON users;
DROP POLICY IF EXISTS "user insert own" ON users;
CREATE POLICY "user select own" ON users
  FOR SELECT TO authenticated
  USING (firebase_uid = auth.uid()::text);
CREATE POLICY "user insert own" ON users
  FOR INSERT TO authenticated
  WITH CHECK (firebase_uid = auth.uid()::text);

-- WALLETS
DROP POLICY IF EXISTS "wallets select own" ON wallets;
DROP POLICY IF EXISTS "wallets insert own" ON wallets;
DROP POLICY IF EXISTS "wallets update own" ON wallets;
CREATE POLICY "wallets select own" ON wallets
  FOR SELECT TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text));
CREATE POLICY "wallets insert own" ON wallets
  FOR INSERT TO authenticated
  WITH CHECK (user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text));
CREATE POLICY "wallets update own" ON wallets
  FOR UPDATE TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text));

-- TRANSACTIONS
DROP POLICY IF EXISTS "tx select own" ON transactions;
DROP POLICY IF EXISTS "tx insert own" ON transactions;
CREATE POLICY "tx select own" ON transactions
  FOR SELECT TO authenticated
  USING (
    from_wallet_id IN (SELECT id FROM wallets WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text))
    OR to_wallet_id IN (SELECT id FROM wallets WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text))
  );
CREATE POLICY "tx insert own" ON transactions
  FOR INSERT TO authenticated
  WITH CHECK (
    from_wallet_id IN (SELECT id FROM wallets WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text))
    OR to_wallet_id IN (SELECT id FROM wallets WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text))
  );

-- DEPOSIT REQUESTS
DROP POLICY IF EXISTS "deposits select own" ON deposit_requests;
DROP POLICY IF EXISTS "deposits insert own" ON deposit_requests;
CREATE POLICY "deposits select own" ON deposit_requests
  FOR SELECT TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text));
CREATE POLICY "deposits insert own" ON deposit_requests
  FOR INSERT TO authenticated
  WITH CHECK (user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text));

-- WITHDRAWAL REQUESTS
DROP POLICY IF EXISTS "withdrawals select own" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawals insert own" ON withdrawal_requests;
CREATE POLICY "withdrawals select own" ON withdrawal_requests
  FOR SELECT TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text));
CREATE POLICY "withdrawals insert own" ON withdrawal_requests
  FOR INSERT TO authenticated
  WITH CHECK (user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text));

-- EXCHANGE RATES (todos pueden leer)
DROP POLICY IF EXISTS "exchange select" ON exchange_rates;
CREATE POLICY "exchange select" ON exchange_rates
  FOR SELECT TO authenticated
  USING (true);

-- =====================================================
-- POLICIES ADMIN (puede hacer TODO)
-- IMPORTANTE: Reemplazar 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82' con tu UID de admin
-- =====================================================

-- Admin en USERS
DROP POLICY IF EXISTS "admin full users" ON users;
CREATE POLICY "admin full users" ON users
  FOR ALL TO authenticated
  USING (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Admin en WALLETS
DROP POLICY IF EXISTS "admin full wallets" ON wallets;
CREATE POLICY "admin full wallets" ON wallets
  FOR ALL TO authenticated
  USING (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Admin en TRANSACTIONS
DROP POLICY IF EXISTS "admin full transactions" ON transactions;
CREATE POLICY "admin full transactions" ON transactions
  FOR ALL TO authenticated
  USING (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Admin en DEPOSIT REQUESTS
DROP POLICY IF EXISTS "admin full deposits" ON deposit_requests;
CREATE POLICY "admin full deposits" ON deposit_requests
  FOR ALL TO authenticated
  USING (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Admin en WITHDRAWAL REQUESTS
DROP POLICY IF EXISTS "admin full withdrawals" ON withdrawal_requests;
CREATE POLICY "admin full withdrawals" ON withdrawal_requests
  FOR ALL TO authenticated
  USING (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Admin en EXCHANGE RATES (puede editar cotizacion)
DROP POLICY IF EXISTS "admin full exchange" ON exchange_rates;
CREATE POLICY "admin full exchange" ON exchange_rates
  FOR ALL TO authenticated
  USING (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (auth.uid()::text = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- =====================================================
-- INDICES (mejor performance)
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_cvu ON users(cvu);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_from_wallet ON transactions(from_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_to_wallet ON transactions(to_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_user_id ON deposit_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_status ON deposit_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user_id ON withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
