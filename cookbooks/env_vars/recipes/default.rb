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
# Additionally, app servers that can't utilize env.custom will not work out
# of the box; further customization will be required. That basically means
# Passenger. Unicorn should work fine, as should Puma.

# Run this only once, on either the app_master or a solo.
if ['app_master', 'solo'].include?(node[:instance_role])
  # Start with writing a wrapper shell script that will call the right version
  # of RubyGems and install PG from inside there.
  template "/home/deploy/pgsetup.sh" do
    source "wrapper.sh.erb"
    mode   0640
    owner  "deploy"
    group  "deploy"
    variables({
      :pg_gem_version => node[:pg_gem_version]
    })
  end

  template "/home/deploy/pgsetup.rb" do
    source "pgsetup.rb.erb"
    mode 0640
    owner "deploy"
    group "deploy"
    variables({
      :run_env     => node[:environment][:framework_env],
      :app_name    => node[:applications].keys.first
    })
  end

  # run the bash wrapper script after the above have been written
  # to disk.
  execute "install-env-vars-db" do
    command "/bin/bash /home/deploy/pgsetup.sh"
  end
end

# Push out the env_vars.rb script to be run with above wrapper.
# Do this on everything except db instances since they don't run code.
if ['app_master', 'app', 'solo', 'util'].include?(node[:instance_role])
  template "/home/deploy/env_vars.rb" do
    source "env_vars.rb.erb"
    mode   0640
    owner  "deploy"
    group  "deploy"
    variables({
      :app_name   =>  node[:applications].keys.first,
      :run_env    =>  node[:environment][:framework_env]
    })
  end

  # Tell the thing to run the above file to generate the env vars
  execute "write-env-vars" do
    command "sudo -u deploy /usr/bin/ruby /home/deploy/env_vars.rb"
  end
end

# Restart all application workers. Note: any other processes that need to
# source env.custom need to also be restarted here, and through a bash script
# that will source env.custom *first*. That means you need to do further
# customization of this script.
if ['app', 'app_master', 'solo'].include?(node[:instance_role])
  # Restart each app's worker pool with the 'deploy' bash script
  node[:applications].keys.each do |x|
    execute "restart-app-workers" do
      command "sudo -u deploy /engineyard/bin/app_#{x} deploy"
    end
  end
end
