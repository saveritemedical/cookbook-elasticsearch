if (node.elasticsearch[:ec2_path] && ! FileTest.directory?(node.elasticsearch[:ec2_path]))
  Chef::Log.info("Setting up the ElasticSearch bind-mount to EBS")

  execute "Copy ElasticSearch data to EBS for first init" do
    command "mv #{node.elasticsearch[:path][:data]} #{node.elasticsearch[:ec2_path]} && mkdir -p #{node.elasticsearch[:path][:data]}"
    not_if do
      FileTest.directory?(node.elasticsearch[:ec2_path])
    end
  end

  directory node.elasticsearch[:ec2_path] do
    owner node.elasticsearch[:user] 
		group node.elasticsearch[:user]
  end

  execute "ensure ElasticSearch data owned by ElasticSearch user" do
    command "chown -R #{node.elasticsearch[:user]}:#{node.elasticsearch[:user]} #{node.elasticsearch[:path][:data]}"
    action :run
  end

else
  Chef::Log.info("Skipping ElasticSearch EBS setup - using what is already on the EBS volume")
end

# TODO: after Chef upgrade use Chef::Util::FileEdit
bash "adding bind mount for #{node.elasticsearch[:path][:data]} to #{node.elasticsearch[:opsworks_autofs_map_file]}" do
  user 'root'
  code <<-EOC
    echo "#{node.elasticsearch[:path][:data]} -fstype=none,bind,rw :#{node.elasticsearch[:ec2_path]}" >> #{node.elasticsearch[:opsworks_autofs_map_file]}
    service autofs restart
  EOC
  not_if { ::File.read("#{node.elasticsearch[:opsworks_autofs_map_file]}").include?("#{node.elasticsearch[:path][:data]}") }
end
