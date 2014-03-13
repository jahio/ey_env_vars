#
# env_vars cookbook
#
# Looks for an env_vars database, creates it if it doesn't exist.
# Next, it will check that the database has the right schema, and will
# create it if it doesn't exist.
# Finally, it will extract all environment variables and their values, then
# pop them into env.custom.
#
# WARNING: As of right now, this recipe only supports PostgreSQL on EY Cloud.

# Run this on the app master because it should have a complete Ruby environment.
if node[:instance_role] == 'app_master'
  # Start with writing a wrapper shell script that will call the right version
  # of RubyGems and install PG from inside there.
  template "/home/deploy/pgsetup.sh" do
    source "wrapper.sh.erb"
    mode   0640
    owner  "deploy"
    group  "deploy"
    variables({
      :pg_version => node[:pg_version]
    })
  end

  template "/home/deploy/pgsetup.rb" do
    source "pgsetup.rb.erb"
    mode 0640
    owner "deploy"
    group "deploy"
    variables({
      :db_username => node[:users].first["username"],
      :db_password => node[:users].first["password"],
      :db_hostname => node[:db_host]
    })
    notifies :run, "execute[install-env-vars-db]", :delayed
  end

  # Finally, run the bash wrapper script after the above have been written
  # to disk.
  execute "install-env-vars-db" do
    command "/bin/bash /home/deploy/pgsetup.sh"
    action :nothing
  end
end
