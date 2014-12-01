use strict vars;
use Test::More;
use Test::Exception;
use Config::Simple;
use JSON;
use Data::Dumper;
use UUID;

my($cfg, $url, );

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
	die "can not create Config object";
    pass "using $ENV{KB_DEPLOYMENT_CONFIG} for configs";
}
else {
    $cfg = new Config::Simple(syntax=>'ini');
    $cfg->param('workspace.service-host', '127.0.0.1');
    $cfg->param('workspace.service-port', '7125');
    pass "using hardcoded Config values";
}

$url = "http://" . $cfg->param('workspace.service-host') . 
	  ":" . $cfg->param('workspace.service-port');

ok(system("curl -h > /dev/null 2>&1") == 0, "curl is installed");
ok(system("curl $url > /dev/null 2>&1") == 0, "$url is reachable");

BEGIN {
	use_ok( Bio::P3::Workspace::WorkspaceClient );
	use_ok( Bio::P3::Workspace::WorkspaceImpl );
}

can_ok("Bio::P3::Workspace::WorkspaceClient", qw(
		create_workspace
		save_objects
		create_upload_node
		get_objects
		get_objects_by_reference
		list_workspace_contents
		list_workspace_hierarchical_contents
		list_workspaces
		search_for_workspaces
		search_for_workspace_objects
		create_workspace_directory
		copy_objects
		move_objects
		delete_workspace
		delete_objects
		delete_workspace_directory
		reset_global_permission
		set_workspace_permissions
		list_workspace_permissions

   )
);

# create a client
my $obj;
isa_ok ($obj = Bio::P3::Workspace::WorkspaceClient->new(), Bio::P3::Workspace::WorkspaceClient);

# create a workspace for each permission value
my $perms = {'w' => 'write', 'r' => 'read', 'a' => 'admin', 'n' => 'none' };
foreach my $perm (sort keys %$perms) {

	my $create_workspace_params = {
        	workspace => new_uuid(),
        	permission => $perm,
        	metadata => {'owner' => 'brettin'},
	};

	my $output;
	ok($output = $obj->create_workspace($create_workspace_params), "can create workspace with $perm permission");

	my $list_workspaces_params = {owned_only => 1, no_public => 1};
	ok($output = $obj->list_workspaces($list_workspaces_params), "can list owned_only, no_public workspaces perm=$perm");
	print_wsmeta($output);

	$list_workspaces_params = {owned_only => 1, no_public => 0};
	ok($output = $obj->list_workspaces($list_workspaces_params), "can list owned_only workspaces perm=$perm");
	print_wsmeta($output);

	$list_workspaces_params = {owned_only => 0, no_public => 1};
	ok($output = $obj->list_workspaces($list_workspaces_params), "can list no_public workspaces perm=$perm");
	print_wsmeta($output);

	$list_workspaces_params = {owned_only => 0, no_public => 0};
	ok($output = $obj->list_workspaces($list_workspaces_params), "can list workspace perm=$perm");
	print_wsmeta($output);

	# delete workspace
	my $delete;
	my $delete_workspace_params = {'WorkspaceName' => $create_workspace_params->{'workspace'}};
	ok($delete = $obj->delete_workspace($delete_workspace_params), "can delete workspace");
}






# add an object to a workspace


# delete an object from a workspace


# delete a workspace




done_testing();

sub new_uuid {

	# create a random workspace name
	my($uuid, $string);
	UUID::generate($uuid);
	UUID::unparse($uuid, $string);
	return 'brettin-' . $string;
}


sub print_wsmeta {
  my $output = shift;
  print ref($output), "\n";
  foreach my $mt (@{$output}) {
        print "WorkspaceID: $mt->[0]\n";
        print "WorkspaceName: $mt->[1]\n";
        print "Username: $mt->[2]\n";
        print "timestamp: $mt->[3]\n";
        print "num_objects: $mt->[4]\n";
        print "user_permission: ", $mt->[5], "\n";
        print "global_permission: ", $mt->[6], "\n";
        print "num_directories: $mt->[7]\n";
        print "UserMetadata: $mt->[8]\n";
  }
  print "\n";
}

