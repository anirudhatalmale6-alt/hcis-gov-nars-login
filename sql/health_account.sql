-- Give this box an account that NARS will actually accept.
--
-- NARS does not check the ROLE, it checks the GROUP. views.js:209 refuses
-- anyone whose user_group is not exactly 'Health', with the message
--
--   "This account is not in the Health Department group, so it has no access
--    to the Needs Assessment module. Please use HCIS instead."
--
-- So a super_admin signs in perfectly well and is still turned away. That is
-- correct behaviour, not a fault: the Needs Assessment module belongs to the
-- Health Department. It just means this box needs at least one Health account,
-- and it has none, because its accounts pre-date the NARS work.
--
-- This creates one, or repairs it if it already exists. Nothing else is
-- touched: no other account, no existing group, no assessment data.
--
-- psql does not substitute :'var' inside a dollar-quoted block, so the values
-- go in through set_config first and are read back with current_setting.

\set ON_ERROR_STOP on

BEGIN;

SELECT set_config('nars.usr', :'usr', true) AS _ \gset
SELECT set_config('nars.pwd', :'pwd', true) AS _ \gset

DO $$
DECLARE
  v_usr  TEXT := current_setting('nars.usr');
  v_pwd  TEXT := current_setting('nars.pwd');
  v_id   TEXT;
  v_n    INT;
BEGIN
  IF length(v_pwd) < 10 THEN
    RAISE EXCEPTION 'The password must be at least 10 characters.';
  END IF;

  SELECT count(*) INTO v_n FROM system_users WHERE lower(username) = lower(v_usr);

  IF v_n > 0 THEN
    -- Already there. Put it in the Health group, give it the assessor role,
    -- set the password and switch it on. This is the repair path.
    UPDATE system_users
       SET user_group           = 'Health',
           role                 = 'health_assessor',
           password_hash        = crypt(v_pwd, gen_salt('bf', 10)),
           status               = 'active',
           locked_until         = NULL,
           failed_attempts      = 0,
           must_change_password = FALSE
     WHERE lower(username) = lower(v_usr);
    RAISE NOTICE 'Existing account "%" moved into the Health Department group.', v_usr;
  ELSE
    -- New. display_id is NOT NULL and unique, so it has to be built - and it
    -- has to look like the ones already here rather than invent a third style.
    -- Staff accounts are U001..U044; the NARS accounts use U-NARS-XXXXX. This
    -- is a NARS account, so follow that.
    --
    -- Derived from the username, so re-running gives the same id rather than a
    -- new one each time. Then checked, because "unlikely to collide" is not the
    -- same as "cannot", and a collision here would abort on the unique index.
    v_id := 'U-NARS-' || upper(substr(md5(v_usr), 1, 5));
    IF EXISTS (SELECT 1 FROM system_users WHERE display_id = v_id) THEN
      v_id := 'U-NARS-' || upper(substr(md5(v_usr), 1, 10));
    END IF;
    IF EXISTS (SELECT 1 FROM system_users WHERE display_id = v_id) THEN
      RAISE EXCEPTION 'Could not build a free display_id for "%". Tell me and I will pick one by hand.', v_usr;
    END IF;

    INSERT INTO system_users
      (display_id, username, email, first_name, last_name,
       role, user_group, password_hash, status,
       failed_attempts, must_change_password)
    VALUES
      (v_id, v_usr, lower(v_usr) || '@databytes.sc',
       initcap(split_part(v_usr, '.', 1)),
       initcap(coalesce(NULLIF(split_part(v_usr, '.', 2), ''), 'Assessor')),
       'health_assessor', 'Health',
       crypt(v_pwd, gen_salt('bf', 10)), 'active',
       0, FALSE);
    RAISE NOTICE 'Created "%" as a Health Department assessor (%).', v_usr, v_id;
  END IF;
END $$;

COMMIT;

-- ---------------------------------------------------------------------------
-- Prove it, without calling hcis_login.
--
-- Calling the login function to check a password is a trap on this system: if
-- the JWT signing key is missing it raises, and that error looks exactly like
-- a wrong password. crypt() answers the real question and cannot be confused
-- by anything else being broken.
-- ---------------------------------------------------------------------------

\echo ''
\echo '  ---------------------------------------------------------'
\echo '  THE ACCOUNT'
\echo '  ---------------------------------------------------------'

SELECT username,
       role,
       user_group,
       status,
       CASE WHEN password_hash = crypt(:'pwd', password_hash)
            THEN 'yes - this password works'
            ELSE 'NO - the password does not match'
       END AS "password check",
       CASE WHEN user_group = 'Health'
            THEN 'yes - NARS will accept it'
            ELSE 'NO - NARS will refuse it'
       END AS "nars will accept"
  FROM system_users
 WHERE lower(username) = lower(:'usr');

\echo ''
\echo '  ---------------------------------------------------------'
\echo '  EVERY HEALTH DEPARTMENT ACCOUNT ON THIS BOX'
\echo '  ---------------------------------------------------------'

SELECT username, role, status
  FROM system_users
 WHERE user_group = 'Health'
 ORDER BY username;
