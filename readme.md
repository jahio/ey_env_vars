# ey_env_vars
A chef recipe for [Engine Yard Cloud](http://www.engineyard.com)
to:

- create an env_vars database on your db_master (PostgreSQL only) if it doesn't exist
- create the table "variables" in that database if it doesn't exist
- retrieve all records in that variables table and write them to env.custom

## Status: DEVELOPMENT - DO NOT USE
This is still in heavy development and subject to total change and overhaul.
Don't use this yet for anything you actually care about, but feel free to
screw around with stuff. Pull requests welcome (as long as they don't suck).

## Use case(s)
Say you have an app and you want to use environment variables instead of
putting your account credentials in the app or in a git repo somewhere. This
will allow you to create the database and write out a file that has all those
entries in there. However, __managing those entries is up to the developer__.
You'll have to launch the psql console to do that yourself, and write a little
SQL. That's not the kind of thing that should be in source control, so that's
why there's no facility for it here.

## Instructions
1. Copy env_vars/ into your cookbooks directory.
2. add ```include_recipe "env_vars"``` to cookbooks/main/recipes/default.rb.
3. Use the [Engine Yard Gem](http://rubygems.org/gems/engineyard) to upload
and run those recipes: ```ey recipes upload -c <acct name> -e <env name> --apply```

License: MIT.
