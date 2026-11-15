-- Biddakunzo (বিদ্যাকুঞ্জ) — PostgreSQL schema, phase 1-4 core
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

CREATE TYPE user_role AS ENUM ('student','teacher','admin','super_admin');
CREATE TYPE enrol_status AS ENUM ('pending','active','completed','cancelled');
CREATE TYPE pay_status AS ENUM ('pending','paid','failed','refunded');
CREATE TYPE post_status AS ENUM ('draft','published','archived');
CREATE TYPE access_level AS ENUM ('public','enrolled','paid');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email CITEXT UNIQUE,
  phone TEXT UNIQUE,
  password_hash TEXT,
  role user_role NOT NULL DEFAULT 'student',
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  locale TEXT NOT NULL DEFAULT 'bn' CHECK (locale IN ('bn','en')),
  email_verified_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE teacher_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  title TEXT,
  bio_bn TEXT, bio_en TEXT,
  is_public BOOLEAN NOT NULL DEFAULT FALSE  -- show on site only after admin approval
);

CREATE TABLE departments (
  id SERIAL PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  name_bn TEXT NOT NULL, name_en TEXT NOT NULL,
  description_bn TEXT, description_en TEXT,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  department_id INT REFERENCES departments(id),
  slug TEXT UNIQUE NOT NULL,
  title_bn TEXT NOT NULL, title_en TEXT NOT NULL,
  summary_bn TEXT, summary_en TEXT,
  level TEXT,                       -- school/college/university/job...
  price_bdt NUMERIC(10,2) NOT NULL DEFAULT 0,
  thumbnail_url TEXT,
  status post_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE course_teachers (
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  teacher_id UUID REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (course_id, teacher_id)
);

CREATE TABLE modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL, sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  video_ref TEXT,                   -- provider asset id, not a public URL
  content TEXT,
  duration_sec INT,
  is_preview BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id),
  name TEXT NOT NULL,
  starts_on DATE, ends_on DATE, capacity INT
);

CREATE TABLE live_classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  teacher_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL, duration_min INT NOT NULL,
  join_url TEXT, recording_ref TEXT
);

CREATE TABLE enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES users(id),
  course_id UUID NOT NULL REFERENCES courses(id),
  batch_id UUID REFERENCES batches(id),
  status enrol_status NOT NULL DEFAULT 'pending',
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (student_id, course_id, batch_id)
);

CREATE TABLE lesson_progress (
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ,
  PRIMARY KEY (student_id, lesson_id)
);

CREATE TABLE attendance (
  live_class_id UUID REFERENCES live_classes(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  present BOOLEAN NOT NULL,
  PRIMARY KEY (live_class_id, student_id)
);

CREATE TABLE quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL, category TEXT   -- e.g. BCS, literature
);
CREATE TABLE quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  body TEXT NOT NULL, options JSONB NOT NULL, correct_index INT NOT NULL, explanation TEXT
);
CREATE TABLE quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id),
  student_id UUID NOT NULL REFERENCES users(id),
  score INT NOT NULL, taken_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID REFERENCES courses(id),
  department_id INT REFERENCES departments(id),
  title_bn TEXT, title_en TEXT NOT NULL,
  file_key TEXT NOT NULL,            -- object-storage key; served via signed URL
  access access_level NOT NULL DEFAULT 'enrolled',
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title_bn TEXT, title_en TEXT NOT NULL,
  author TEXT, price_bdt NUMERIC(10,2) NOT NULL,
  cover_url TEXT, file_key TEXT NOT NULL,
  status post_status NOT NULL DEFAULT 'draft'
);

CREATE TABLE coupons (
  code TEXT PRIMARY KEY,
  percent_off INT CHECK (percent_off BETWEEN 1 AND 100),
  amount_off NUMERIC(10,2),
  expires_at TIMESTAMPTZ, max_uses INT, used INT NOT NULL DEFAULT 0
);

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  total_bdt NUMERIC(10,2) NOT NULL,
  coupon_code TEXT REFERENCES coupons(code),
  status pay_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id),
  book_id UUID REFERENCES books(id),
  price_bdt NUMERIC(10,2) NOT NULL,
  CHECK ((course_id IS NOT NULL) <> (book_id IS NOT NULL))
);
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id),
  gateway TEXT NOT NULL,             -- sslcommerz / bkash / nagad ...
  gateway_txn_id TEXT UNIQUE,        -- idempotency for webhooks
  amount_bdt NUMERIC(10,2) NOT NULL,
  status pay_status NOT NULL DEFAULT 'pending',
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE blog_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title_bn TEXT, title_en TEXT,
  body_bn TEXT, body_en TEXT,
  author_id UUID REFERENCES users(id),
  category TEXT,
  status post_status NOT NULL DEFAULT 'draft',
  published_at TIMESTAMPTZ
);

CREATE TABLE job_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,            -- BCS, govt, private, freelancing
  title_bn TEXT, title_en TEXT NOT NULL,
  material_id UUID REFERENCES materials(id),
  quiz_id UUID REFERENCES quizzes(id)
);

CREATE TABLE ai_usage (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  tool TEXT NOT NULL,                -- writing_feedback, quiz_gen, ...
  tokens_in INT, tokens_out INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  actor_id UUID REFERENCES users(id),
  action TEXT NOT NULL, entity TEXT, entity_id TEXT, meta JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ON enrollments (student_id);
CREATE INDEX ON live_classes (starts_at);
CREATE INDEX ON payments (order_id);
CREATE INDEX ON blog_posts (status, published_at DESC);
