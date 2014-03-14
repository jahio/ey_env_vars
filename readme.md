# ey_env_vars
A chef recipe for [Engine Yard Cloud](http://www.engineyard.com)
to:

- create an env_vars database on your db_master (PostgreSQL only) if it doesn't exist
- create the table "variables" in that database if it doesn't exist
- retrieve all records in that variables table and write them to env.custom

## Status: ALPHA - USE WITH EXTREME CAUTION
This recipe has been tested to the extent possible and while not feature
complete, is "good enough" for most purposes. Current limitations are:
- PostgreSQL only (MySQL, you're out of luck)
- Doesn't try restarting Resque or other workers
- Only works with application servers that use env.custom. This means Passenger
users are out of luck.

That said, if you want to use this, do so __at your own risk__ and with
extreme caution. Please report any issues (not feature requests) you find.

Feature requests should be accompanied by a pull request. If you want it to do
X and it doesn't do X, go write code to do X, test it as best you can, then
send a pull request.

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

### Adding new environment variables
After you've run the recipe at least once, as it creates the database 'env_vars'
database, SSH up to one of your application machines. Start by taking a quick
look at your database.yml file:

```cat /data/<appname>/shared/config/database.yml```

Use those parameters to connect to PostgreSQL:

```psql -h <hostname> -U deploy -d env_vars```

You'll be prompted for the password - copy/paste. Now you're into a PostgreSQL
database console.

Next you want to run some insert statements to create your env variables:

```sql
INSERT INTO variables (var, val) VALUES ('myvar', 'myval');
```

For example, if you wanted to specify a different location for the
[Unicorn](http://unicorn.bogomips.org) configuration path:

```sql
INSERT INTO variables (var, val) VALUES ('UNICORN_CONF', '/data/myapp/shared/config/custom_unicorn.rb');
```

Once you're done, exit the psql console: ```\q```

And then run the recipes again from your local machine:

```ey recipes apply -c <account name> -e <env name>```

When finished, your env.custom should be updated to reflect every key/value
pair inside the variables table, and your application server should be
restarted on application instances. __NOTE: You will have to restart other
things, like resque processes or other items that need that code, on your own.__
Also, be sure that their wrapper scripts are sourcing env.custom prior to
execution, or they won't have the environment variables you've created.

## Resources for the curious
- [Engine Yard Chef Docs](https://support.cloud.engineyard.com/entries/21009867-Customize-Your-Environment-with-Chef-Recipes)
- [Engine Yard Chef Best Practices](https://support.cloud.engineyard.com/entries/21406977-Custom-Chef-Recipes-Examples-Best-Practices)
- Engine Yard uses ```chef-solo``` on EY Cloud without chef-server. Just know that.
- [Chef](http://getchef.com) (formerly known as OpsCode)

License: MIT.
