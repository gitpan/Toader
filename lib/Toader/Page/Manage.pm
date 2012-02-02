package Toader::Page::Manage;

use warnings;
use strict;
use Toader::isaToaderDir;
use Toader::Page::Helper;
use Toader::Page;
use base 'Error::Helper';
use Toader::pathHelper;

=head1 NAME

Toader::Page::Manage - Manage pages for a specified Toader directory.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Toader::Page::Manage;


=head1 METHODS

=head2 new

This initiates the object.

After calling this, you should call setDir to set the directory to use.

    my $foo = Toader::Page::Manage->new();

=cut

sub new{
	my $self={
			  error=>undef,
			  errorString=>'',
			  dir=>undef,
			  pdir=>undef,
			  isatd=>Toader::isaToaderDir->new,
			  helper=>Toader::Page::Helper->new,
			  };
	bless $self;

	return $self;
}

=head2 list

This lists the available pages.

    my @pages=$foo->list;
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
	my @pages;

	#makes sure we have a entry directory
	if ( ! -d $self->{pdir}) {
		return @pages;
	}

 	#read what is present in the directory
	my $dh;
	if (! opendir( $dh, $self->{pdir} ) ) {
		$self->{error}='5';
		$self->{errorString}='Failed to open the directory "'.$self->{dir}.'"';
		$self->warn;
		return undef;
	}
	@pages=grep( { -f $self->{pdir}.'/'.$_ }  readdir($dh) );
	close($dh);

	my @toreturn;
	my $int=0;
	while( defined( $pages[$int] ) ){
		if ( $self->{helper}->validPageName( $pages[$int] ) ){
			push( @toreturn, $pages[$int] );
		}

		$int++;
	}

	return @toreturn;
}

=head2 read

This reads a page.

One argument is required and it is entry name.

The returned value is a L<Toader::Page> object.

    my $page=$foo->read($pageName);
    if($foo->error){
        warn('error: '.$foo->error.":".$foo->errorString);
    }

=cut

sub read{
	my $self=$_[0];
	my $page=$_[1];

 	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a directory is specified
	if (!defined($page)) {
		$self->{error}='6';
		$self->{errorString}='No pagespecified';
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
	my $returned=$self->{helper}->pageExists($page);
	if (!$returned) {
		if ($self->{helper}->error){
			$self->{error}=7;
			$self->{errorString}='The page name is not valid';
		}else {
			$self->{error}=8;
			$self->{errorString}='The page does not exist';
		}
		$self->warn;
		return undef;
	}

	#figure out the file will be
	my $file=$self->{dir}.'/.toader/pages/'.$page;

	#reads it
	my $pageString;
	my $fh;
	if ( ! open($fh, '<', $file) ){
		$self->{error}=10;
		$self->{errorString}='Unable to open "'.$file.'" for reading';
		$self->warn;
		return undef;
	}
	$pageString=join("", <$fh>);
	close($fh);

	my $pageObj=Toader::Page->newFromString($pageString);
	if ($pageObj->error) {
		$self->{error}=11;
		$self->{errorString}='Unable to generate a Toader::Page object from ';
		$self->warn;
		return undef;
	}

	#sets the directory
	$pageObj->dirSet($self->{dir});

	return $pageObj;
}

=head2 remove

This removes a page.

One argument is required and it is page name.

    $foo->remove($page);
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

	#makes sure a directory is specified
	if (defined($entry)) {
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

	if (!unlink($self->{pdir}.'/'.$entry)) {
		$self->{error}=9;
		$self->{errorString}='Failed to unlink the entry';
		$self->warn;
		return undef;		
	}

	return 1;
}

=head2 setDir

This sets the directory the module will work on.

One argument is taken and that is the path for the Toader directory
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
	$self->{pdir}=$self->{helper}->pageDirectory;

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

Unable to open the page file for reading.

=head2 11

Unable to generate a L<Toader::Page> object from the file.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Page::Manage


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
