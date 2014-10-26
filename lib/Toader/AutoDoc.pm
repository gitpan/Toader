package Toader::AutoDoc;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::isaToaderDir;

=head1 NAME

Toader::AutoDoc - Automatically build documentation from specified directories.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 METHODS

=head2 new

This initiates the object.

    my $foo = Toader::AutoDoc->new;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub new{
	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  dir=>undef,
			  };
	bless $self;

	return $self;
}

=head2 dirGet

This gets L<Toader> directory this entry is associated with.

This will only error if a permanent error is set.

This will return undef if no directory has been set.

    my $dir=$foo->dirGet;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub dirGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->{dir};
}

=head2 dirSet

This sets L<Toader> directory this entry is associated with.

One argument is taken and it is the L<Toader> directory to set it to.

    my $dir=$foo->dirSet($toaderDirectory);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub dirSet{
	my $self=$_[0];
	my $dir=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been specified
	if (!defined($dir)) {
		$self->{error}=1;
		$self->{errorString}='No directory specified.';
		$self->warn;
		return undef;
	}

	#cleans up the naming
	my $pathHelper=Toader::pathHelper->new($dir);
	$dir=$pathHelper->cleanup($dir);

        #checks if the directory is Toader directory or not
	my $isatd=Toader::isaToaderDir->new;
    my $returned=$isatd->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'" is not a Toader directory.';
		$self->warn;
		return undef;
	}

	$self->{dir}=$dir;

	return 1;
}

=head2 findDocs

Finds documentation under the specified paths.

=cut

sub findDocs{
    my $self=$_[0];
	my $cp=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{dir} ) ){
        $self->{error}=4;
        $self->{errorString}='No directory is set';
        $self->warn;
        return undef;
    }

	#gets the paths
	my @paths;
	if ( ! defined( $cp ) ){
		# get the paths
		@paths=$self->pathsGet;
		if ( $self->error ){
			$self->warnString('Failed to get the paths');
			return undef;
		}
		$cp='';
	}else{
		my $dh;
		if ( ! opendir( $dh, $self->{dir}.'/'.$cp ) ){
			$self->warnString('Failed to open the directory "'.$self->{dir}.'/'.$cp.'"');
			return undef;
		}
		@paths=grep( !/^\./, readdir( $dh ) );
		closedir( $dh );
	}
	
	#process each path
	my $int=0;
	my @toreturn;
	while( defined( $paths[$int] ) ){
		my $item=$self->{dir}.'/'.$cp.'/'.$paths[$int];

		#processes any files found
		if ( 
			( -f $item ) &&
			(
			 ( $item =~ /\/README$/ ) ||
			 ( $item =~ /\/Changes$/ ) ||
			 ( $item =~ /\/TODO$/ ) ||
			 ( $item =~ /\.pm$/ ) ||
			 ( $item =~ /\.[Pp][Oo][Dd]$/ ) ||
			 ( $item =~ /\.[Tt][Xx][Tt]$/ )
			 )
			){
			push( @toreturn, $cp.'/'.$paths[$int] );
		}
		
		#process any directories found
		if ( -d $item ){
			my @returned=$self->findDocs( $cp.'/'.$paths[$int] );
			if ( defined( $returned[0] ) ){
				push( @toreturn, @returned );
			}
		}

		$int++;
	}

	#make sure there are no //
	if ( $cp eq '' ){
		$int=0;
		while( defined( $toreturn[$int] ) ){
			$toreturn[$int]=~s/\/\//\//g;
			$toreturn[$int]=~s/^\///;

			$int++;
		}
	}

	return @toreturn;
}

=head2 pathAdd

This adds a new path.

=cut

sub pathAdd{
	my $self=$_[0];
	my $path=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{dir} ) ){
        $self->{error}=4;
        $self->{errorString}='No directory is set';
        $self->warn;
        return undef;
    }

	if ( ! defined( $path ) ){
		$self->{error}=5;
		$self->{errorString}='No path specified';
		$self->warn;
		return undef;
	}

	if ( ! $self->validPath( $path ) ){
		$self->{error}=6;
		$self->{errorString}='Invalid path specified';
		$self->warn;
		return undef;
	}

	my @paths=$self->pathsGet;
	if ( $self->error ){
		$self->warnString('Failed to get the current paths');
		return undef;
	}

	push( @paths, $path );

	$self->pathsSet( \@paths );
	if ( $self->error ){
		$self->warnString('Failed to set save the paths list');
		return undef;
	}

	return 1;
}

=head2 pathRemove

Remove a specified path.

=cut

sub pathRemove{
    my $self=$_[0];
	my $path=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{dir} ) ){
        $self->{error}=4;
        $self->{errorString}='No directory is set';
        $self->warn;
        return undef;
    }

	if ( ! defined( $path ) ){
		$self->{error}='5';
		$self->{errorString}='No path specified';
		$self->warn;
		return undef;
	}

    my @paths=$self->pathsGet;
    if ( $self->error ){
        $self->warnString('Failed to get the current paths');
        return undef;
    }

	#
	my $int=0;
	my @newpaths;
	while ( defined( $paths[$int] ) ){
		if ( $paths[$int] ne $path ){
			push( @newpaths, $paths[$int] );
		}

		$int++;
	}

    $self->pathsSet( \@newpaths );
    if ( $self->error ){
        $self->warnString('Failed to set save the paths list');
        return undef;
    }

	return 1;
}

=head2 pathsGet

This gets the list of what is to by handled.

No arguments are taken.

The returned value is a list. Each item in the
list is a path to recursively search.

    my @paths=$foo->pathsGet;

=cut

sub pathsGet{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

	if ( ! defined( $self->{dir} ) ){
		$self->{error}=4;
		$self->{errorString}='No directory is set';
		$self->warn;
		return undef;
	}

	my $file=$self->{dir}.'/.toader/autodoc/dirs';

	#it does not exist... no directories to search
	if ( ! -f $file ){
		return;
	}

	#read the file
	my $fh;
	if ( ! open( $fh, '<', $file ) ){
		$self->{error}=3;
		$self->{errorString}='Failed to open "'.$file.'"';
		$self->warn;
		return undef;
	}
	my $line=<$fh>;
	my @data;
	while( defined( $line ) ){
		chomp( $line );
		if ( $line ne '' ){
			push( @data, $line );
		}

		$line=<$fh>;
	}
	close $fh;

	return @data;
}

=head2 pathsSet

This sets the AutoDoc paths for a directory.

One argument is required and that is a array ref of
relative paths.

    $foo->pathsSet( \@paths );

=cut

sub pathsSet{
	my $self=$_[0];
	my @paths;
	if ( defined( $_[1] ) ){
		@paths=@{ $_[1] };
	}

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{dir} ) ){
        $self->{error}=4;
        $self->{errorString}='No directory is set';
        $self->warn;
        return undef;
    }

	my $dir=$self->{dir}.'/.toader/autodoc/';
    my $file=$self->{dir}.'/.toader/autodoc/dirs';

	#try to create to autodoc config directory
	if ( ! -e $dir ){
		if ( ! mkdir( $dir ) ){
			$self->{error}=7;
			$self->{errorString}='Failed to create to Autodoc configuration directory, "'.$dir.'",';
			$self->warn;
			return undef;
		}
	}

	my $data=join("\n", @paths)."\n";
	
	#open and write it
	my $fh;
    if ( ! open( $fh, '>', $file ) ){
        $self->{error}=3;
        $self->{errorString}='Failed to open "'.$file.'"';
        $self->warn;
        return undef;
    }
	print $fh $data;
    close $fh;

	return 1;
}

=head2 validPath

This verifies that a path is valid.

It makes sure it defined and does not match any thing below.

    ^..\/
    \/..\/
	\/..$

=cut

sub validPath{
	my $path=$_[1];

	if ( ! defined( $path ) ){
		return 0;
	}

	if ( $path =~ /^\.\.\// ){
		return 0;
	}

	if ( $path =~ /\/\.\.\// ){
		return 0;
	}

	if ( $path =~ /\/.\.$/ ){
		return 0;
	}

	return 1;
}

=head1 REQUIRED RENDERING METHODS

=head2 filesDir

This returns the file directory for the object.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

=cut

sub filesDir{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return $self->renderDir.'/.files';
}

=head2 locationID

This returns the location ID.

This one requires the object to be initialized.

=cut

sub locationID{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return 'Documentation';
}

=head2 renderDir

This is the directory that it will be rendered to.

The base directory that will be used for rendering.

=cut

sub renderDir{
	return '.autodoc';
}

=head2 renderUsing

This returns the module to use for rendering.

    my $module=$foo->renderUsing;

=cut

sub renderUsing{
    return 'Toader::Render::AutoDoc';
}

=head2 toaderRenderable

This method returns true and marks it as being L<Toader>
renderable.

=cut

sub toaderRenderable{
	return 1;
}

=head2 toDir

This returns the relative path to the object.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

=cut

sub toDir{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    return $self->renderDir;
}

=head1 ERROR CODES

=head2 1

No directory specified.

=head2 2

The directory is not a Toader directory.

=head2 3

Failed to open the paths file.

=head2 4

No directory set.

=head2 5

No path specified.

=head2 6

Invalid path.

=head2 7

The AutoDoc configuration directory could not be created.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::AutoDoc


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

1; # End of Toader::AutoDoc
