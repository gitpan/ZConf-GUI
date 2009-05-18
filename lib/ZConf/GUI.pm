package ZConf::GUI;

use warnings;
use strict;
use Module::List qw(list_modules);

=head1 NAME

ZConf::GUI - A GUI backend chooser.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ZConf::GUI;

    my $zg = ZConf::GUI->new();
    ...

=head1 FUNCTIONS

=head2 new

This initiates it.

=head3 hash args

=head2 autoinit

If this is set to true, it will automatically call
init the set and config. If this is set to false or
not defined, besure to check '$zg->{init}' to see
if the config/module has been initiated or not.

If it is not specified, it will default to true.

=head4 set

This specifies the initial set. It defaults
to the default if not specified.

=head4 zconf

A already initialized ZConf object.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>undef};
	bless $self;

	#this sets the set to 1 if it is not defined
	if (!defined($args{autoinit})) {
		$self->{autoinit}=1;
	}else {
		$self->{autoinit}=$args{set};
	}

	#this sets the set to undef if it is not defined
	if (!defined($args{set})) {
		$self->{set}=undef;
	}else {
		$self->{set}=$args{set};
	}

	if (!defined($args{zconf})) {
		use ZConf;
		$self->{zconf}=ZConf->new();
		if(defined($self->{zconf}->{error})){
			warn("ZConf-GUI new:1: Could not initiate ZConf. It failed with '"
				 .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'");
			$self->{error}=1;
			$self->{errorString}="Could not initiate ZConf. It failed with '"
			                     .$self->{zconf}->{error}."', '".
			                     $self->{zconf}->{errorString}."'";
			return $self;
		}
	}else {
		$self->{zconf}=$args{zconf};
	}

	#create the config if it does not exist
	#if it does exist, make sure the set we are using exists
    $self->{init} = $self->{zconf}->configExists("gui");
	if($self->{zconf}->{error}){
		warn("ZConf-GUI new:1: Could not check if the config 'gui' exists.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="Could not check if the config 'gu'i exists.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return $self;
	}

	#this checks to make sure the set exists, if init is already 1
	if ($self->{init}) {
		$self->{init}=$self->{zconf}->defaultSetExists('gui', $self->{set});

		if($self->{zconf}->{error}){
			warn("ZConf-GUI new:1: Could not check if the config 'gui' exists.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=1;
			$self->{errorString}="Could not check if the config 'gu'i exists.".
			                     " It failed with '".$self->{zconf}->{error}."', '"
								 .$self->{zconf}->{errorString}."'";
			return $self;
		}
	}

	#if it is not inited, check to see if it needs to do so
	if ((!$self->{init}) && $self->{autoinit}) {
		$self->init($self->{set});
		if ($self->{error}) {
			warn('ZConf-GUI new: Autoinit failed.');
		}else {
			#if init works, it is now inited and thus we set it to one
			$self->{init}=1;
		}
		#we don't set any error stuff here even if the above action failed...
		#it will have been set any ways by init methode
		return $self;
	}

	#checks wether the specified set exists or not
	$self->{init}=$self->{zconf}->setExists('gui', $self->{set});
	if($self->{zconf}->{error}){
		warn("ZConf-GUI new:2: defaultSetExists failed for 'gui'.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="defaultSetExists failed for 'gui'.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return $self;
	}

	#the first one does this if the config has not been done yet
	#this one does it if the set has not been done yet
	#if it is not inited, check to see if it needs to do so
	if (!$self->{init} && $self->{autoinit}) {
		$self->init($self->{set});
		if ($self->{error}) {
			warn('ZConf-GUI new:4: Autoinit failed.');
		}else {
			#if init works, it is now inited and thus we set it to one
			$self->{init}=1;
		}
		#we don't set any error stuff here even if the above action failed...
		#it will have been set any ways by init methode
		return $self;
	}

	#reads it if it does not need to be initiated
	if ($self->{init}) {
		$self->{zconf}->read({set=>$self->{set}, config=>'gui'});
	}

	return $self;
}

=head2 getPreferred

This gets the preferred for a module.

    my @prefs=$zg->getPreferred('ZConf::Runner');
    if($zg->{error}){
        print "Error!\n";
    }

=cut

sub getPreferred{
	my $self=$_[0];
	my $module=$_[1];

	if (!defined($module)) {
		warn('ZConf-GUI setPreferred:2: No module specified');
		$self->{error}=2;
		$self->{errorString}='No module specified';
		return undef;
	}

	#the change it for fetching the info
	my $module2=$module;
	$module2=~s/\:\:/\//g;

	#fetch the preferences for the module
	my %vars=$self->{zconf}->regexVarGet('gui', '^modules/'.quotemeta($module2).'$');
	if($self->{zconf}->{error}){
		warn('ZConf-GUI getPreferred:1: regexVarGet errored '.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error listing sets for the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	#if we don't get it, try the default
	if (!defined($vars{'modules/'.$module2})) {
		%vars=$self->{zconf}->regexVarGet('gui', '^default$');
		if($self->{zconf}->{error}){
			warn('ZConf-GUI getPreferred:1: regexVarGet errored '.
				 ' ZConf error="'.$self->{zconf}->{error}.'" '.
				 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
			$self->{error}=1;
			$self->{errorString}='ZConf error listing sets for the config "gui".'.
			                     ' ZConf error="'.$self->{zconf}->{error}.'" '.
								 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
			return undef;
		}

		#if the default does not exist
		if (!defined($vars{default})) {
			warn('ZConf-GUI getPreferred:5: No preferences for "'.$module.'" and there is no default');
			$self->{error}=5;
			$self->{errorString}='No preferences for "'.$module.'" and there is no default';
			return undef;
		}

		return split(/:/, $vars{default});
	}

	return split(/:/, $vars{'modules/'.$module2});
}

=head2 getSet

This gets what the current set is.

    my $set=$zg->getSet;
    if($zg->{error}){
        print "Error!\n";
    }

=cut

sub getSet{
	my $self=$_[0];

	#blanks any previous errors
	$self->errorblank;

	my $set=$self->{zconf}->getSet('gui');
	if($self->{zconf}->{error}){
		warn('ZConf-GUI getSet:1: ZConf error getting the loaded set the config "gui".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error getting the loaded set the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	return $set;
}

=head2 getUseX

This fetches if X should be used or not for a module.

    $zcgui->getUseX('ZConf::Runner');
    if($zcgui->{error}){
        print "Error!";
    }

=cut

sub getUseX{
	my $self=$_[0];
	my $module=$_[1];

	$self->errorblank;

	if (!defined($module)) {
		warn('ZConf-GUI getUseX:2: No module specified');
		$self->{error}=2;
		$self->{errorString}='No module specified';
		return undef;
	}

	#the change it for fetching the info
	my $module2=$module;
	$module2=~s/\:\:/\//g;

	#fetch the preferences for the module
	my %vars=$self->{zconf}->regexVarGet('gui', '^useX/'.quotemeta($module2).'$');
	if($self->{zconf}->{error}){
		warn('ZConf-GUI getUseX:1: regexVarGet errored '.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error listing sets for the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	#if we don't get it, try the default
	if (!defined($vars{'modules/'.$module2})) {
		return 1;
	}

	return $vars{'modules/'.$module2};
}

=head2 hasPreferred

This checks to make sure a module has any prefences or not. The
returned value is a perl bolean value.

    my $returned=$zg->hasPreferred("ZConf::BGSet");

=cut

sub hasPreferred{
	my $self=$_[0];
	my $module=$_[1];

	if (!defined($module)) {
		warn('ZConf-GUI setPreferred:2: No module specified');
		$self->{error}=2;
		$self->{errorString}='No module specified';
		return undef;
	}

	my %vars=$self->{zconf}->regexVarGet('gui', '^modules/'.quotemeta($module).'$');
	if($self->{zconf}->{error}){
		warn('ZConf-GUI getPreferred:1: regexVarGet errored '.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error listing sets for the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	if (!defined($vars{'modules/'.$module})) {
		return undef;
	}

	return 1;
}

=head2 init

This initializes it or a new set.

If the specified set already exists, it will be reset.

One arguement is required and it is the name of the set. If
it is not defined, ZConf will use the default one.

    #creates a new set named foo
    $zcw->init('foo');
    if($zg->{error}){
        print "Error!\n";
    }

    #creates a new set with ZConf choosing it's name
    $zg->init();
    if($zg->{error}){
        print "Error!\n";
    }

=cut

sub init{
	my $self=$_[0];
	my $set=$_[1];

	#blanks any previous errors
	$self->errorblank;

	my $returned = $self->{zconf}->configExists("gui");
	if(defined($self->{zconf}->{error})){
		warn("ZConf-GUI init:1: Could not check if the config 'gui' exists.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="Could not check if the config 'gui' exists.".
		                     " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	#create the config if it does not exist
	if (!$returned) {
		$self->{zconf}->createConfig("gui");
		if ($self->{zconf}->{error}) {
			warn("ZConf-GUI init:1: Could not create the ZConf config 'gui'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=1;
			$self->{errorString}="Could not create the ZConf config 'gui'.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return undef;
		}
	}

	#create the new set
	$self->{zconf}->writeSetFromHash({config=>"gui", set=>$set},{default=>"GTK:Curses"});
	
	#error if the write failed
	if ($self->{zconf}->{error}) {
		warn("ZConf-GUI init:1: writeSetFromHash failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="writeSetFromHash failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	#now that it is initiated, load it
	$self->{zconf}->read({config=>'gui', set=>$set});
	if ($self->{zconf}->{error}) {
		warn("ZConf-GUI init:1: read failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="read failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	return 1;
}

=head2 listAvailable

This is the available GUI modules for a module.

    my @available=$zg->listAvailable('ZConf::Runner');

=cut

sub listAvailable{
	my $self=$_[0];
	my $module=$_[1];

	$self->errorblank;

	if (!defined($module)) {
		warn('ZConf-GUI listAvailable:2: No module specified');
		$self->{error}=2;
		$self->{errorString}='No module specified';
		return undef;
	}

	#this is what will be checked for and scrubbed upon return
	my $check=$module.'::GUI::';

	my $modules=list_modules($check,{ list_modules => 1});
	#testing shows this should not happen, but in case it does, handle it
	if (!defined($modules)) {
		warn('ZCong-GUI listAvailable:6: list_modules failed');
		$self->{error}=6;
		$self->{errorString}='list_modules failed';
		return undef;
	}

	my @mods=keys(%{$modules});

	my $int=0;
	while ($mods[$int]) {
		$mods[$int]=~s/^$check//;
		$int++;
	}

	return @mods;
}

=head2 listModules

This lists configured modules.

    my @modules=$zg->listModules;
    if($zg->{error}){
        print "Error!\n";
    }

=cut

sub listModules{
	my $self=$_[0];

	my @modules=$self->{zconf}->regexVarSearch('gui', '^modules');
	if ($self->{zconf}->{error}) {
		warn("ZConf-GUI listModules:1: regexVarSearch failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="regexVarSearch failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}	

	my $int=0;
	#removes leading /^modules\//
	#also make sure that the ZConf var stuff is replaced with ::
	while (defined($modules[$int])) {
		$modules[$int]=~s/^modules\///;
		$modules[$int]=~s/\//\:\:/g;

		$int++;
	}

	return @modules;
}

=head2 listSets

This lists the available sets.

    my @sets=$zg->listSets;
    if($zg->{error}){
        print "Error!";
    }

=cut

sub listSets{
	my $self=$_[0];

	#blanks any previous errors
	$self->errorblank;

	my @sets=$self->{zconf}->getAvailableSets('gui');
	if($self->{zconf}->{error}){
		warn('ZConf-GUI listSets:1: ZConf error listing sets for the config "gui".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error listing sets for the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	return @sets;
}

=head2 readSet

This reads a specific set. If the set specified
is undef, the default set is read.

    #read the default set
    $zg->readSet();
    if($zg->{error}){
        print "Error!\n";
    }

    #read the set 'someSet'
    $zg->readSet('someSet');
    if($zg->{error}){
        print "Error!\n";
    }

=cut

sub readSet{
	my $self=$_[0];
	my $set=$_[1];

	
	#blanks any previous errors
	$self->errorblank;

	$self->{zconf}->read({config=>'gui', set=>$set});
	if ($self->{zconf}->{error}) {
		warn('ZConf-GUI readSet:1: ZConf error reading the config "gui".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error reading the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	return 1;
}

=head2 rmPreferred

This removes a the preferences for a module.

    $zg->rmPreferred('ZConf::BGSet');
    if($zg->{error}){
        print "Error:".$self->{error}.":".$self->{errorString};
    }

=cut

sub rmPreferred{
	my $self=$_[0];
	my $module=$_[1];

	if (!defined($module)) {
		$self->{errorString}='No module specified';
		$self->{error}=2;
		warn('ZConf-GUI rmPreferred:2: '.$self->{error});
		return undef;
	}

	#remove any specifical characters that have been passed
	my $safemodule=quotemeta($module);

	my @deleted=$self->{zconf}->regexVarDel('gui', '^modules/'.$safemodule.'$');
	if ($self->{zconf}->{error}) {
		warn('ZConf-GUI rmPreferred:1: regexVarDel "gui".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error reading the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;	
	}

	#only one will be matched so we just need to check the first
	if ($deleted[0] ne 'modules/'.$module) {
		$self->{errorString}='"'.$module.' not matched"';
		$self->{error}=7;
		warn('ZConf-GUI rmPreferred:7: '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 setPreferred

This sets the preferred GUI back ends. The first arguement is the module.
The second is a array reference of the prefences.

    my @prefs=('GUI', 'Curses');
    #set it for ZConf::BGSet
    my $zg->setPreferred('ZConf::BGSet', \@prefs);

=cut

sub setPreferred{
	my $self=$_[0];
	my $module=$_[1];
	my $prefs;
	if (defined($_[2])) {
		$prefs=$_[2];
	}

	if (!defined($module)) {
		warn('ZConf-GUI setPreferred:2: No module specified');
		$self->{error}=2;
		$self->{errorString}='No module specified';
		return undef;
	}

	if (!defined(@{$prefs}[0])) {
		warn('ZConf-GUI setPreferred:3: No prefs specified');
		$self->{error}=3;
		$self->{errorString}='No prefs specified';
		return undef;
	}

	my $int=0;
	while (defined(@{$prefs}[$int])){
		if (@{$prefs}[$int] =~ /:/) {
			warn('ZConf-GUI setPreferred:4: "'.@{$prefs}[$int].'" matched /:/');
			$self->{error}=4;
			$self->{errorString}='"'.@{$prefs}[$int].'" matched /:/';
			return undef;
		}

		$int++;
	}

	$module=~s/::/\//g;

	my $joinedprefs=join(':', @{$prefs});

	$self->{zconf}->setVar('gui', 'modules/'.$module, $joinedprefs);
	if($self->{zconf}->{error}){
		warn('ZConf-GUI listSets:1: setvar errored '.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error listing sets for the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	$self->{zconf}->writeSetFromLoadedConfig({config=>'gui'});

	return 1;
}

=head2 setUseX

This determines if X should be used or not. This only affects terminal
related modules that respect this.

    $zcgui->setUseX('ZConf::Runner', '1');
    if($zcgui->{error}){
        print "Error!";
    }

=cut

sub setUseX{
	my $self=$_[0];
	my $module=$_[1];
	my $useX=$_[2];

	$self->errorblank;

	if (!defined($module)) {
		warn('ZConf-GUI setUseX:2: No module specified');
		$self->{error}=2;
		$self->{errorString}='No module specified';
		return undef;
	}

	if (!defined($useX)) {
		warn('ZConf-GUI setUseX:3: No prefs specified');
		$self->{error}=3;
		$self->{errorString}='No prefs specified';
		return undef;
	}

	$module=~s/::/\//g;

	$self->{zconf}->setVar('gui', 'useX/'.$module, $useX);
	if($self->{zconf}->{error}){
		warn('ZConf-GUI setUseX:1: setvar errored '.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=1;
		$self->{errorString}='ZConf error listing sets for the config "gui".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	$self->{zconf}->writeSetFromLoadedConfig({config=>'gui'});

	return 1;
}

=head2 termAvailable

This checks to see if a terminal is available. It checks
if $ENV{TERM} is set or not. If this is not set, it was most
likely not ran from with a terminal.

    if($zg->termAvailable){
        print "a terminal is available";
    }else{
        print "no terminal is available";
    }

=cut

sub termAvailable{
	my $self=$_[0];

	if (!defined($ENV{TERM})) {
		return undef;
	}

	return 1;
}

=head2 Xavailable

This checks if X is available. This is checked for by trying to run
'/bin/sh -c \'xhost 2> /dev/null > /dev/null\'' and is assumed if a
non-zero exit code is returned then it failed and thus X is not
available.

There is no reason to ever check $zcr->{error} with
this as this function will not set it. It just returns
a boolean value.

    if($zg->Xavailable()){
        print "X is available\n";
    }

=cut

sub Xavailable{
	my $self=$_[0];

	#if this is defined, the next one definitely will not work
	if (!defined($ENV{DISPLAY})) {
		return undef;
	}

	#exists non-zero if it fails
	my $command='/bin/sh -c \'xhost 2> /dev/null > /dev/null\'';
	system($command);
	#if xhost exits with a non-zero then X is not available
	my $exitcode=$? >> 8;
	if ($exitcode ne '0'){
		return undef;
	}

	return 1;
}

=head2 useX

This checks to see if a terminal interface should try to use X or not by
trying to spawn a X terminal.

This calls getUseX and if it is true, it calls Xavailable and returns it's
value.

    my $useX=$zcgui->useX('ZConf::Runner');

=cut

sub useX{
	my $self=$_[0];
	my $module=$_[1];

	$self->errorblank;

	if (!defined($module)) {
		my $error='No module specified.';
		$self->{error}=2;
		$self->{errorString}=$error;
		warn('ZConf-GUI useX:2: '.$error);
		return undef;
	}

	#get if X should be used
	my $useX=$self->getUseX($module);

	#if it should be used, make sure it is available
	if ($useX) {
		return $self->Xavailable;
	}

	return 0;
}

=head2 which

This chooses which should be used. This returns all available
backends in order of preference.

    my @choosen=$zg->which('ZConf::BGSet');
    if($zg->{error}){
        print "Error!";
    }

    print 'The primary preferred module is "'.$choosen[0].'"';

=cut

sub which{
	my $self=$_[0];
	my $module=$_[1];

	if (!defined($module)) {
		warn('ZConf-GUI which:2: No module specified');
		$self->{error}=2;
		$self->{errorString}='No module specified';
		return undef;
	}

	my @prefs=$self->getPreferred($module);

	#checks if X and/or a terminal is available
	my $Xavailable=$self->Xavailable();
	my $termAvailable=$self->termAvailable();

	#gets usable modules
	my @available=$self->listAvailable($module);

	my @usable;

	my $int=0;
	while (defined($available[$int])) {
		if (($available[$int]=~/^Curses/) || ($available[$int]=~/^Term/)) {
			push(@usable, $available[$int]);
		}else {
			if ($Xavailable) {
				push(@usable, $available[$int]);
			}
		}
		
		$int++;
	}

	return @usable;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head2 ERROR CODES

=head3 1

ZConf error. Check $self->{zconf}->{error}.

=head3 2

No module specified.

=head3 3

No preferences specified.

=head3 4

A preference matched /:/.

=head3 5

No preferences for the listed module.

=head3 6

'list_modules' failed.

=head3 7

The specified module does not exist.

=head1 ZConf Keys

These are stored in config 'gui'.

Each preference is stored as a string for a module. Each preference is seperated
as by ':'. The order of the preferred go from favorite to least favorite.

=head2 default

This is the default to use if nothing is setup for a module. The default value is
'GTK:Curses'.

=head2 modules/*

This contains the a list of preferences for a module.

The module name is converted to a ZConf variable name by replacing '::' with '/'.

=head2 useX/*

This is if a cuses module should use X or not. If it is true, it will pass 

If if is not defined, it is set to true.

The module name is converted to a ZConf variable name by replacing '::' with '/'.

=head1 USING ZConf::GUI

A backend is considered to be any thing directly under <module>::GUI. How to call it
or etc is directly up to the calling module though.

Any module using this, should have it's widgets and dialogs use a single hash for all it's
arguements. This is currently not a requirement, but will be in future versions for future
automated calling.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-gui at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-GUI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::GUI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-GUI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-GUI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-GUI>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-GUI>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::GUI
