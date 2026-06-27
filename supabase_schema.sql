-- ============================================================
--  GEMS — Supabase Database Schema
--  Abiola Ajimobi University — Green Environment System
--  Paste this entire file into your Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── FACULTIES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS faculties (
  id                  TEXT PRIMARY KEY,        -- 'nas', 'es', 'eng', 'med'
  name                TEXT NOT NULL,
  short_name          TEXT NOT NULL,
  description         TEXT,
  color_hex           TEXT,                    -- e.g. '#D32F2F'
  green_health_score  FLOAT DEFAULT 0,
  hazard_level        TEXT DEFAULT 'low',      -- 'low','medium','high','critical'
  total_area_ha       INT,
  dean                TEXT,
  image_url           TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ── VEGETATION ZONES ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vegetation_zones (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  faculty_id  TEXT REFERENCES faculties(id),
  name        TEXT NOT NULL,
  type        TEXT NOT NULL,                   -- 'bush','grass','flowers','trees','bare'
  percentage  FLOAT NOT NULL,
  color_hex   TEXT,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── MAINTENANCE TASKS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS maintenance_tasks (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  faculty_id   TEXT REFERENCES faculties(id),
  title        TEXT NOT NULL,
  description  TEXT,
  status       TEXT DEFAULT 'pending',         -- 'pending','in_progress','completed','overdue'
  priority     TEXT DEFAULT 'medium',          -- 'low','medium','high','critical'
  task_type    TEXT,                           -- 'Bush Clearing','Grass Cutting', etc.
  assigned_to  TEXT,
  due_date     DATE,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── MONTHLY REPORTS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS monthly_reports (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  year        INT NOT NULL,
  month_num   INT NOT NULL,                    -- 1-12
  month       TEXT NOT NULL,                   -- 'Jan','Feb', etc.
  nas_score   FLOAT DEFAULT 0,
  es_score    FLOAT DEFAULT 0,
  eng_score   FLOAT DEFAULT 0,
  med_score   FLOAT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(year, month_num)
);

-- ── ISSUE REPORTS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS issue_reports (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  faculty_id   TEXT REFERENCES faculties(id),
  title        TEXT NOT NULL,
  description  TEXT,
  reported_by  TEXT,
  photo_url    TEXT,
  status       TEXT DEFAULT 'open',            -- 'open','investigating','resolved'
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── TREE REGISTRY ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tree_registry (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  faculty_id    TEXT REFERENCES faculties(id),
  species       TEXT NOT NULL,
  quantity      INT DEFAULT 1,
  date_planted  DATE,
  status        TEXT DEFAULT 'growing',        -- 'planned','growing','mature'
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── USERS ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id),
  email       TEXT,
  full_name   TEXT,
  role        TEXT DEFAULT 'staff',            -- 'admin','faculty_officer','groundskeeper','student'
  faculty_id  TEXT REFERENCES faculties(id),  -- null = admin (all faculties)
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── SEED DATA ────────────────────────────────────────────────
INSERT INTO faculties (id, name, short_name, description, color_hex, green_health_score, hazard_level, total_area_ha, dean, image_url)
VALUES
  ('nas', 'Natural & Applied Sciences', 'NAS',
   'High bush density. Urgent clearing required across lab perimeters.',
   '#D32F2F', 22, 'critical', 12, 'Prof. Adewale Okonkwo',
   'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800&q=80'),

  ('es', 'Environmental Science', 'ENV',
   'Leading campus benchmark — maintained lawns, flower beds, tree canopy.',
   '#388E3C', 78, 'low', 9, 'Prof. Ngozi Umeh',
   'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800&q=80'),

  ('eng', 'Engineering', 'ENG',
   'Dense dry bush near workshop buildings. Critical fire hazard.',
   '#E65100', 28, 'critical', 15, 'Prof. Chukwuemeka Duru',
   'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&q=80'),

  ('med', 'Medical Science', 'MED',
   'Mixed profile: hostel well-maintained, clinic perimeter bushed.',
   '#1565C0', 51, 'medium', 11, 'Prof. Funmilayo Adeleke',
   'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&q=80')
ON CONFLICT (id) DO NOTHING;

INSERT INTO monthly_reports (year, month_num, month, nas_score, es_score, eng_score, med_score) VALUES
  (2025, 1, 'Jan', 15, 70, 20, 44),
  (2025, 2, 'Feb', 16, 71, 21, 45),
  (2025, 3, 'Mar', 18, 73, 23, 47),
  (2025, 4, 'Apr', 19, 75, 25, 48),
  (2025, 5, 'May', 20, 76, 26, 49),
  (2025, 6, 'Jun', 22, 78, 28, 51)
ON CONFLICT (year, month_num) DO NOTHING;

-- ── ROW LEVEL SECURITY ───────────────────────────────────────
ALTER TABLE faculties ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_reports ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read faculties
CREATE POLICY "Authenticated users can read faculties"
  ON faculties FOR SELECT TO authenticated USING (true);

-- Allow admin to write everything (role-check via user_profiles)
CREATE POLICY "Admin can manage tasks"
  ON maintenance_tasks FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
    OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND faculty_id = maintenance_tasks.faculty_id)
  );

-- ✅ Schema ready. Run flutter pub get and update supabase_service.dart with your credentials.
