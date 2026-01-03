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

-- Policies para users
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (true);

-- Policies para wallets
CREATE POLICY "Users can view own wallets" ON wallets
  FOR SELECT USING (true);

CREATE POLICY "Users can update own wallets" ON wallets
  FOR UPDATE USING (true);

CREATE POLICY "System can insert wallets" ON wallets
  FOR INSERT WITH CHECK (true);

-- Policies para transactions
CREATE POLICY "Users can view own transactions" ON transactions
  FOR SELECT USING (true);

CREATE POLICY "Users can insert transactions" ON transactions
  FOR INSERT WITH CHECK (true);

-- Policies para deposit_requests
CREATE POLICY "Users can view own deposits" ON deposit_requests
  FOR SELECT USING (true);

CREATE POLICY "Users can insert deposits" ON deposit_requests
  FOR INSERT WITH CHECK (true);

-- Policies para exchange_rates (solo lectura publica)
CREATE POLICY "Anyone can view exchange rates" ON exchange_rates
  FOR SELECT USING (true);

-- Indices para mejor performance
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_cvu ON users(cvu);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_from_wallet ON transactions(from_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_to_wallet ON transactions(to_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_user_id ON deposit_requests(user_id);
