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

# Run this on an app or util because it should have a complete Ruby environment.
if ['app', 'app_master', 'util'].include?(node[:instance_role])
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
      :db_hostname => node[:db_host],
      :app_name    => node[:applications].keys.first
    })
  end

  # run the bash wrapper script after the above have been written
  # to disk.
  execute "install-env-vars-db" do
    command "/bin/bash /home/deploy/pgsetup.sh"
  end
end

if ['app', 'app_master'].include?(node[:instance_role])
  # tell the EY bash script to restart the application workers
  app_name = node[:applications].keys.first
  execute "restart-app-workers" do
    command "sudo -u deploy /engineyard/bin/app_#{app_name} deploy"
  end
end
