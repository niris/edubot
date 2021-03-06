-- prevent created FUNCTION to be public by default

ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
-- auth table + roles (anon, admin, user)
\ir _auth.sql
-- auth rpc (/rpc/login, /rpc/register, /rpc/logout)
\ir _auth_jwt.sql

DROP TABLE IF EXISTS public.lesson;
CREATE TABLE public.lesson (
	"id" int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, -- SERIAL type would've required a "sequence" table
	"draft" boolean DEFAULT FALSE,
	"title" text,
	"icon" varchar,
	"tags" varchar[],
	"created" timestamp NOT NULL DEFAULT NOW(),
	"content" text,
	"owner" name DEFAULT current_user REFERENCES auth.users(id) ON DELETE CASCADE
);
grant SELECT ON TABLE public.lesson TO "user", "anon";
grant ALL    ON TABLE public.lesson TO "admin";
ALTER TABLE public.lesson ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lesson_policy" ON public.lesson;
CREATE POLICY "lesson_policy" ON public.lesson
  USING (("draft" = FALSE) OR ("owner" = current_user)) -- visibility rule
  WITH CHECK ("owner" = current_user); -- mutation rule

DROP TABLE IF EXISTS public.user;
CREATE TABLE public.user (
  "id" name DEFAULT current_user PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
	"name" text,
	"birth" date,
  "progress" JSON
);
grant SELECT ON TABLE public.user TO "anon";
grant ALL    ON TABLE public.user TO "user", "admin";
ALTER TABLE public.user ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_policy" ON public.user;
CREATE POLICY "user_policy" ON public.user
  USING ("id" = current_user) -- visibility rule
  WITH CHECK ("id" = current_user); -- mutation rule

-- debug dataset for role debugging
insert into auth.users ("id","pass","role") values ('admin','admin','admin') ON CONFLICT DO NOTHING;
insert into auth.users ("id","pass","role") values ('user' ,'user' ,'user' ) ON CONFLICT DO NOTHING;
insert into auth.users ("id","pass","role") values ('root' ,'root' ,'root' ) ON CONFLICT DO NOTHING;
--do not deploy dataset as we want to see the empty lesson page by default
--insert into public.lesson ("title","draft","owner") values ('public',FALSE,'admin') ON CONFLICT DO NOTHING;
--insert into public.lesson ("title","draft","owner") values ('draft',TRUE,'admin') ON CONFLICT DO NOTHING;
-- CREATE VIEW u AS SELECT "id", "role", "progress" FROM auth.users;

NOTIFY pgrst, 'reload schema';