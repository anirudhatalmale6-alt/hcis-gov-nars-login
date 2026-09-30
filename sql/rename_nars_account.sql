-- Make the NARS account impossible to mistake for the real one.
--
-- evans.nars was created with a name derived from its username, so it showed
-- as "Evans Nars" - which, truncated in the corner of the screen, reads as
-- "Evans". The client signed in with it, saw an assessor view, and reasonably
-- reported his role as broken.
--
-- The username was always unique. Nobody reads the username. They read the
-- name in the corner, so that is what has to be distinct.
--
-- This changes the DISPLAYED NAME only. Not the username, not the password,
-- not the role, not the group, not the status. Signing in is unaffected.

\set ON_ERROR_STOP on

\if :{?usr}   \else \set usr   'evans.nars' \endif
\if :{?first} \else \set first 'Evans' \endif
\if :{?last}  \else \set last  '(NARS assessor)' \endif

BEGIN;

SELECT set_config('nars.usr',   :'usr',   true) AS _ \gset
SELECT set_config('nars.first', :'first', true) AS _ \gset
SELECT set_config('nars.last',  :'last',  true) AS _ \gset

DO $$
DECLARE
  v_usr   TEXT := current_setting('nars.usr');
  v_first TEXT := current_setting('nars.first');
  v_last  TEXT := current_setting('nars.last');
  v_n     INT;
BEGIN
  SELECT count(*) INTO v_n FROM system_users WHERE lower(username) = lower(v_usr);
  IF v_n = 0 THEN
    RAISE EXCEPTION 'There is no account called "%" on this box. Nothing was changed.', v_usr;
  END IF;

  -- Refuse to rename anything that is not a NARS/Health account. This script
  -- exists to relabel a second account; pointed at the wrong username it would
  -- otherwise quietly rewrite a real person's name.
  IF NOT EXISTS (SELECT 1 FROM system_users
                  WHERE lower(username) = lower(v_usr) AND user_group = 'Health') THEN
    RAISE EXCEPTION
      'Account "%" is not in the Health Department group, so this is not the NARS account. Nothing was changed.', v_usr;
  END IF;

  UPDATE system_users
     SET first_name = v_first,
         last_name  = v_last
   WHERE lower(username) = lower(v_usr);

  RAISE NOTICE 'Renamed "%" on screen to "% %".', v_usr, v_first, v_last;
END $$;

COMMIT;

\echo ''
\echo '  ---------------------------------------------------------'
\echo '  HOW THE TWO ACCOUNTS NOW LOOK ON SCREEN'
\echo '  ---------------------------------------------------------'

SELECT username,
       (first_name || ' ' || last_name) AS "shows on screen as",
       role,
       user_group,
       status
  FROM system_users
 WHERE user_group = 'Health'
    OR role = 'super_admin'
 ORDER BY user_group, username;
