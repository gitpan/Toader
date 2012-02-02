package Toader::Entry::Manage;

use warnings;
use strict;
use Toader::isaToaderDir;
use Toader::Entry::Helper;
use Toader::Entry;
use base 'Error::Helper';

=head1 NAME

Toader::Entry::Manage - Manage entries.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 METHODS

=head2 new

This initiates the object.

After calling this, you should call setDir to set the directory to use.

    my $foo = Toader::isaToaderDir->new();

=cut

sub new{
	my $self={
			  error=>undef,
			  errorString=>'',
			  dir=>undef,
			  edir=>undef,
			  isatd=>Toader::isaToaderDir->new,
			  helper=>Toader::Entry::Helper->new,
			  };
	bless $self;

	return $self;
}

=head2 list

This lists the available entries.

    my @entries=$foo->list;
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub list{
	my $self=$_[0];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory has been set
	if (!defined($self->{dir})) {
		$self->{error}='4';
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#this will be returned
	my @entries;

	#makes sure we have a entry directory
	if (!-d $self->{edir}) {
		return @entries;
	}

	#read what is present in the directory
	my $dh;
	if (!opendir($dh, $self->{edir})) {
		$self->{error}='5';
		$self->{errorString}='Failed to open the directory "'.$self->{dir}.'"';
		$self->warn;
		return undef;
	}
	@entries=grep( { -f $self->{edir}.'/'.$_ && /$self->{helper}->{regex}/ }  readdir($dh) );
	close($dh);

	return @entries;
}

=head2 read

This reads a entry.

One argument is taken and that is the entry name.

    my $entry=$foo->read( $entryName );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorStrin );
    }

=cut

sub read{
	my $self=$_[0];
	my $entry=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a directory has been set
	if (!defined($self->{dir})) {
		$self->{error}='4';
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#make sure it is valid and exists
	my $returned=$self->{helper}->entryExists($entry);
	if (!$returned) {
		if ($self->{helper}->error){
			$self->{error}=7;
			$self->{errorString}='The entry name is not valid';
		}else {
			$self->{error}=8;
			$self->{errorString}='The entry does not exist';
		}
		$self->warn;
		return undef;
	}

	#the file that will be read
	my $file=$self->{dir}.'/.toader/entries/'.$entry;

	#reads it
	my $entryString;
	my $fh;
	if ( ! open($fh, '<', $file) ){
		$self->{error}=10;
		$self->{errorString}='Unable to open "'.$file.'" for writing';
		$self->warn;
		return undef;
	}
	$entryString=join("", <$fh>);
	close($fh);

	my $entryObj=Toader::Entry->newFromString($entryString);
	if ($entryObj->error) {
		$self->{error}=11;
		$self->{errorString}='Unable to generate a Toader::Entry object from ';
		$self->warn;
		return undef;		
	}

	#sets the directory
	$entryObj->dirSet($self->{dir});
	$entryObj->entryNameSet($entry);

	return $entryObj;
}

=head2 remove

This removes a entry.

One argument is required and it is entry name.

    $foo->remove($entry);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub remove{
	my $self=$_[0];
	my $entry=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a entry is specified
	if (!defined($entry)) {
		$self->{error}='6';
		$self->{errorString}='No entry specified';
		$self->warn;
		return undef;
	}

	#make sure a directory has been set
	if (!defined($self->{dir})) {
		$self->{error}='4';
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#make sure it is valid and exists
	my $returned=$self->{helper}->entryExists($entry);
	if (!$returned) {
		if ($self->{helper}->error){
			$self->{error}=7;
			$self->{errorString}='The entry name is not valid';
		}else {
			$self->{error}=8;
			$self->{errorString}='The entry does not exist';
		}
		$self->warn;
		return undef;
	}

	if (!unlink($self->{edir}.'/'.$entry)) {
		$self->{error}=9;
		$self->{errorString}='Failed to unlink the entry';
		$self->warn;
		return undef;		
	}

	return 1;
}

=head2 setDir

This sets the directory the module will work on.

One argument is taken and that is the path for the L<Toader> directory
in question.

    $foo->setDir($toaderDirectory)
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub setDir{
	my $self=$_[0];
	my $directory=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a directory is specified
	if (!defined($directory)) {
		$self->{error}='1';
		$self->{errorString}='No directory specified';
		$self->warn;
		return undef;
	}

	#cleans up the naming
	my $pathHelper=Toader::pathHelper->new( $directory );
	$directory=$pathHelper->cleanup( $directory );

	
	#makes sure it is a directory
	my $returned=$self->{isatd}->isaToaderDir($directory);
	if(!$returned){
        if($self->{isatd}->error){
			$self->{error}='2';
			$self->{errorString}='isaToaderDir errored. error="'.$self->{isatd}->error.'" errorString="'.$self->{isatd}->errorString.'"';
			$self->warn;
			return undef;
        }
		$self->{error}='3';
		$self->{errorString}='"'.$directory.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#it has been verified, so set it
	$self->{dir}=$directory;
	$self->{helper}->setDir($directory); #if the previous check has been worked, then this well
	$self->{edir}=$self->{helper}->entryDirectory;

	return 1;
}

=head1 ERROR CODES

=head2 1

No directory specified.

=head2 2

isaToaderDir errored.

=head2 3

Is not a L<Toader> directory.

=head2 4

No directory has been defined.

=head2 5

Failed to open the directory.

=head2 6

No entry specified.

=head2 7

The entry is not a valid name.

=head2 8

The entry does not exist.

=head2 9

Failed to unlink the entry.

=head2 10

Unable to open the entry file for reading.

=head2 11

Generating a L<Toader::Entry> object from a alredy existing entry failed.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Entry::Manage


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Toader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Toader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Toader>

=item * Search CPAN

L<http://search.cpan.org/dist/Toader/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader
