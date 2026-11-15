# Biddakunzo (বিদ্যাকুঞ্জ) — Platform Architecture & Roadmap

Tagline: Pure Taste of English Literature · Domain: www.biddakunzo.com
Founder: Ripon Sen — Founder, Director & Instructor

## 1. Goals
One platform with six surfaces: public website, student portal, teacher portal, admin dashboard, online learning (live + recorded), and commerce (course payments + digital bookstore), with AI-assisted tools for learners.

## 2. Recommended stack
| Layer | Choice | Why |
|---|---|---|
| Frontend | Next.js (App Router) + TypeScript + Tailwind | SSR/SEO for public pages, one codebase for all portals |
| i18n | next-intl (en, bn) | Proper Bengali + English routing |
| API | Next.js route handlers / server actions, Zod validation | Fewer moving parts at launch |
| Database | PostgreSQL + Prisma | Relational fit for enrolments, payments, content |
| Auth | Auth.js (email+password, Google), RBAC | Roles: student, teacher, admin, super_admin |
| Storage | S3-compatible bucket (signed URLs) | Materials, e-books, recordings |
| Video | Zoom/Meet links for live; Mux/Bunny Stream for recorded | Avoid building video infra |
| Payments | SSLCommerz / bKash / Nagad (Bangladesh), card gateway optional | Local payment habits |
| Email/SMS | Transactional email + SMS OTP provider | Verification, receipts, reminders |
| AI | Claude API behind server-side routes with quotas | Study helper, quiz generator, writing feedback |
| Hosting | Vercel or VPS + managed Postgres, Cloudflare in front | Simple deploys, CDN, WAF |

(Alternative if you prefer low-code: Odoo eLearning + Website + eCommerce. Faster to launch, less flexible for AI tools and custom portals.)

## 3. Modules
1. **Public site** — Home, About Us, Courses, Departments, Online Classes, Teachers, Study Materials, Job Preparation, Blog & Articles.
2. **Student portal** — dashboard, my courses, progress, live class schedule, assignments/quizzes, certificates, orders, wishlist, AI tools.
3. **Teacher portal** — courses and batches, lesson/material upload, live class scheduling, attendance, grading, announcements.
4. **Admin dashboard** — users and roles, course/department CMS, batches, enrolments, payments and refunds, bookstore catalogue, blog CMS, reports, audit log.
5. **Online learning** — batches, live classes (link + calendar), recorded lessons with progress tracking, quizzes, assignments.
6. **AI tools** (quota per plan) — English writing feedback, grammar explainer, literature summary/essay outline helper, MCQ quiz generator for BCS/job prep, Bengali↔English practice. Always labelled AI-generated; no storing of prompts beyond usage logs unless the user saves them.
7. **Payments** — course checkout, instalments (later), coupons, invoices, webhooks with idempotency.
8. **Digital bookstore** — PDF/e-book products, secure download via expiring signed URLs, optional watermarking, order history.

## 4. Audience-to-department mapping
School · College · University · National University · English Literature · English Language · ICT · AI · Freelancing · Job Preparation (BCS, government, private). Departments and courses are CMS-managed, not hard-coded.

## 5. Role permissions (summary)
- **Visitor**: browse public pages, read published blog/materials marked public.
- **Student**: own enrolments, paid materials for enrolled courses, own orders, AI tools within quota.
- **Teacher**: only their courses/batches; cannot see payments.
- **Admin**: everything operational; **super_admin**: roles, settings, payment keys.

## 6. Security checklist
- Argon2/bcrypt hashing, email verification, rate-limited login, optional 2FA for staff.
- RBAC enforced server-side on every route; row-level ownership checks.
- Zod validation on all input; parameterised queries via Prisma; output escaping; CSP headers.
- CSRF protection, secure httpOnly cookies, SameSite.
- Payment webhooks verified by signature; amounts re-checked server-side.
- Signed, expiring URLs for paid files; no public bucket listing.
- Audit log for admin actions; daily DB backups with restore test.
- Privacy: collect minimal data; students under 18 need guardian-consent flow (decide policy).

## 7. Phased roadmap
| Phase | Scope |
|---|---|
| 0 | Content inventory, official logo files, real course list, payment gateway account |
| 1 | Public site (CMS-driven), auth, admin course/department/blog CMS |
| 2 | Enrolment + payments, student portal, materials |
| 3 | Teacher portal, batches, live classes, attendance, quizzes |
| 4 | Digital bookstore |
| 5 | AI tools, certificates, reports, mobile polish |

## 8. Content rules (from the brief)
- Bengali brand name is always written **বিদ্যাকুঞ্জ**.
- Use the official logo unmodified (slot reserved in header/footer; file needed).
- No invented credentials, results, testimonials, contact details or teacher identities. Placeholders are marked clearly until real data is supplied.

## 9. Needed from you
Official logo (SVG/PNG), real course list with fees, teacher profiles you approve, contact details, payment gateway choice, and the policy for under-18 learners.
