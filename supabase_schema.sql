-- Billetera Virtual - Supabase Schema
-- Ejecutar este script en el SQL Editor de Supabase

-- Usuarios (sincronizado con Firebase Auth)
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
  currency TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  proof_url TEXT,
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

-- Insertar cotizacion inicial
INSERT INTO exchange_rates (buy_rate, sell_rate) VALUES (1050.00, 1100.00);

-- Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposit_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_rates ENABLE ROW LEVEL SECURITY;

-- Limpieza de politicas previas
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;
DROP POLICY IF EXISTS "Users can view own wallets" ON wallets;
DROP POLICY IF EXISTS "Users can update own wallets" ON wallets;
DROP POLICY IF EXISTS "System can insert wallets" ON wallets;
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert transactions" ON transactions;
DROP POLICY IF EXISTS "Users can view own deposits" ON deposit_requests;
DROP POLICY IF EXISTS "Users can insert deposits" ON deposit_requests;
DROP POLICY IF EXISTS "Anyone can view exchange rates" ON exchange_rates;

-- UID de admin (reemplazar con tu UID de Firebase si quieres acceso total)
-- SELECT 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82';

-- Policies para users (por UID de Firebase enviado en x-firebase-uid)
CREATE POLICY "user select own" ON users
  FOR SELECT TO anon
  USING (firebase_uid = current_setting('request.headers.x-firebase-uid', true));

CREATE POLICY "user insert own" ON users
  FOR INSERT TO anon
  WITH CHECK (firebase_uid = current_setting('request.headers.x-firebase-uid', true));

CREATE POLICY "admin full users" ON users
  FOR ALL TO anon
  USING (current_setting('request.headers.x-firebase-uid', true) = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (current_setting('request.headers.x-firebase-uid', true) = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Policies para wallets (solo billeteras del usuario)
CREATE POLICY "wallets select own" ON wallets
  FOR SELECT TO anon
  USING (user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)));

CREATE POLICY "wallets insert own" ON wallets
  FOR INSERT TO anon
  WITH CHECK (user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)));

CREATE POLICY "wallets update own" ON wallets
  FOR UPDATE TO anon
  USING (user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)));

CREATE POLICY "admin full wallets" ON wallets
  FOR ALL TO anon
  USING (current_setting('request.headers.x-firebase-uid', true) = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (current_setting('request.headers.x-firebase-uid', true) = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Policies para transactions (solo donde el usuario participa)
CREATE POLICY "tx select own" ON transactions
  FOR SELECT TO anon
  USING (
    from_wallet_id IN (SELECT id FROM wallets WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)))
    OR to_wallet_id IN (SELECT id FROM wallets WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)))
  );

CREATE POLICY "tx insert own" ON transactions
  FOR INSERT TO anon
  WITH CHECK (
    from_wallet_id IN (SELECT id FROM wallets WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)))
    OR to_wallet_id IN (SELECT id FROM wallets WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)))
  );

CREATE POLICY "admin full txs" ON transactions
  FOR ALL TO anon
  USING (current_setting('request.headers.x-firebase-uid', true) = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (current_setting('request.headers.x-firebase-uid', true) = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Policies para deposit_requests (solo del usuario)
CREATE POLICY "deposits select own" ON deposit_requests
  FOR SELECT TO anon
  USING (user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)));

CREATE POLICY "deposits insert own" ON deposit_requests
  FOR INSERT TO anon
  WITH CHECK (user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.headers.x-firebase-uid', true)));

CREATE POLICY "admin full deposits" ON deposit_requests
  FOR ALL TO anon
  USING (current_setting('request.headers.x-firebase-uid', true) = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82')
  WITH CHECK (current_setting('request.headers.x-firebase-uid', true) = 'Bcd4Lan0p4Yt4LqmXcUNM0ryaV82');

-- Policies para exchange_rates (solo lectura publica)
CREATE POLICY "exchange select" ON exchange_rates
  FOR SELECT TO anon
  USING (true);

-- Indices para mejor performance
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_cvu ON users(cvu);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_from_wallet ON transactions(from_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_to_wallet ON transactions(to_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_user_id ON deposit_requests(user_id);
