package KeyValueTree;

use strict;
use Exporter;
use File::Path qw(make_path);
use Tie::File;;
use Fcntl qw(O_RDONLY O_RDWR O_CREAT);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$VERSION	= '0.00';
@ISA 		= qw(Exporter);
@EXPORT		= ();
@EXPORT_OK	= qw(new);

sub new {
	my ($class_name) = shift;
	my %params = @_; 

	if (!$params{'PATH'}) { die 'No PATH given'; }
	if (!-e $params{'PATH'} or !-x $params{'PATH'}) { die $params{'PATH'}.' does not exist or not accessible'; }

	my $self = {};
	bless($self, $class_name);
	$self->{'created'} = 1;
	$self->{'PATH'} = $params{'PATH'};
	$self->{'PATH'} =~ s/\/+$//;
	$self->{'PATH'}.= '/';

	if (!-e $self->{'PATH'}.'/kvt.path') { die $self->{'PATH'}.'/kvt.path does not exist'; }
	
	return $self;
}

sub get {
	my ($self, $key) = @_;
	$key = $self->_valid_key($key);
	if ($key eq '') { die('invalid key ('.$key.') in get'); }

	my $path = $self->_path_for_key($key);

	my $data_path = $self->{'PATH'}.$path;
	if (-r $data_path) {
		eval {
			tie my @lines, 'Tie::File', $data_path, mode => O_RDONLY;
			my @list = grep { /^$key\t([0-9.]{7,15})$/ } @lines;
			my $value;
			if (@list > 0) {
				@list = split /\t/, $list[0];
				$value = $list[1];
			}
			untie @lines;
			return $value;
		};
	}
}

sub set {
	my ($self, $key, $value) = @_;

	$key = $self->_valid_key($key);
	if ($key eq '') { die('invalid key ('.$key.') in set'); }

	my $path = $self->_path_for_key($key);

	# create path unless exists
	if (!-e $self->{'PATH'}.$path) { $self->_mkdir_recursive($path); }

	eval {
		tie my @lines, 'Tie::File', $self->{'PATH'}.$path, mode => O_RDWR | O_CREAT;; 
		my @list = grep { /^$key\t([0-9.]{7,15})$/ } @lines;
		my $old_value = '';
		if (@list > 0) {
			@list = split /\t/, $list[0];
			$old_value = $list[1];
		}      
		if ($old_value && $old_value ne "") {
			map { s/^($key)\t([0-9.]{7,15})$/$1\t$value/; } @lines;
		} else {
			push @lines, "$key\t$value";
		}
		untie @lines;
	};
}

sub _mkdir_recursive {
	my ($self, $path) = @_;

	# separate file from dir path
	my $dir_path = $path;
	if ($dir_path =~ /^[a-z0-9_]{1,3}\.stor$/) { return; }
	$dir_path =~ s/\/[a-z0-9_]{1,3}\.stor$//;

	if ($dir_path ne "") {
		make_path($self->{'PATH'}.'/'.$dir_path, { 'verbose' => 0 });
	}
}


sub _valid_key {
	my ($self, $key) = @_;

	$key = lc($key);
	$key =~ s/[^a-z0-9.-]/-/g;
	if ($key !~ /^[a-z0-9.-]{4,100}$/) {
		return '';
	}
	
	$key =~ s/\./_/g;

	return $key;
}

sub _path_for_key {
	my ($self, $key) = @_;
	
	$key =~ s/[^a-z0-9]//g;
	my @key = split //, $key;

	my $path = '';
	for (my $i = 0; $i < 2 && $#key > 0; $i++) {
		$path .= shift(@key);
		if ($#key >= 0) { $path.= shift(@key); }
		$path .= '/';
	}
	$path =~ s/\/$/\.stor/;

	return $path;
}

__END__

=head1 NAME 

KeyValueTree.pm - a quick module to store data in multiple files across a directory tree

=head1 SYNOPSIS

  Setup:
  use KeyValueTree;
  my $kvt = KeyValueTree->new( PATH => '/tmp/kvt/' );
  (make sure that /tmp/kvt includes a file "kvt.path" and that it is otherwise empty)

  Basic usage:
  $kvt->set("key", "value");
  my $value = $kvt->get("key");

=head1 DESCRIPTION

KeyValueTree is a quick solution to store a lot of small Key-Value pairs in a directory tree. The idea was to get small files and directories that are still usable (not filled with thousands of files).

=head1 AUTHOR

Mario Witte, <mario.witte@chengfu.net>

=head1 COPYRIGHT

Copyright 2013 by  Mario Witte

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

=cut
