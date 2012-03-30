package Toader::Gallery;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::isaToaderDir;
use Config::Tiny;

=head1 NAME

Toader::Gallery - Handle image galleries.

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
	if ( $pathHelper->error ){
		$self->{error}=11;
		$self->{errorString}='Failed to initialize Toader::pathHelper';
		$self->warn;
		return undef;
	}
	$dir=$pathHelper->cleanup( $dir );

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

	if ( defined( $self->{config} ) ){
		delete( $self->{config} );
	}
	
	my $configfile=$self->{dir}.'/.toader/gallery.ini';
	if ( -f $configfile ){
		$self->{config}=Config::Tiny->read( $configfile );
		if ( ! defined( $self->{config} ) ){
			$self->{error}=3;
			$self->{errorString}='Failed to read the gallery config, "'.$configfile.'",';
			$self->warn;
			return undef;
		}
	}

	return 1;
}

=head2 init

This is initializes the config for a directory. This is automatically
called if it has not been done so for a directory.

=cut

sub init{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }   
	
	if ( defined( $self->{config} ) ){
        $self->{error}=10;
        $self->{errorString}='"'.$self->{dir}.'" has already been initialized';
        $self->warn;
        return undef;
    }

	$self->{config}=Config::Tiny->new;
	$self->writeConfig;
	if ( $self->error ){
		$self->warnString('Failed to write the config out');
		return undef;
	}

	return 1;
}

=head2 outputPathGet

This returns the output path.

    my $outputPath=$foo->outputPathGet;
    if ( $foo->error ){
        warn( 'error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub outputPathGet{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{config} ) ){
        $self->{error}=4;
        $self->{errorString}='No config for the current directory';
        $self->warn;
        return undef;
    }

    return $self->{config}->{'_'}->{'outputPath'};
}

=head2 outputPathSet

This returns the output path.

    $foo->outputPathSet( $outputPath );
    if ( $foo->error ){
        warn( 'error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub outputPathSet{
    my $self=$_[0];
	my $outputPath=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{config} ) ){
		$self->init;
		if ( $self->error ){
			$self->warnString('Failed to initialize the gallery config');
			return undef;
		}
    }

	if ( ! defined( $outputPath ) ){
		$self->{error}=8;
		$self->{errorString}='No output path specified';
	}

	$self->{config}->{'_'}->{'outputPath'}=$outputPath;

	$self->writeConfig;
	if ( $self->error ){
		$self->warnString('Failed to write the config out');
		return undef;
	}

    return 1;
}

=head2 outputURLget

This returns the output path.

    my $outputURL=$foo->outputURLget;
    if ( $foo->error ){
        warn( 'error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub outputURLget{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{config} ) ){
        $self->{error}=4;
        $self->{errorString}='No config for the current directory';
        $self->warn;
        return undef;
    }

    return $self->{config}->{'_'}->{'outputURL'};
}

=head2 outputURLset

This sets the output URL.

    my $outputURL=$foo->outputURLget;
    if ( $foo->error ){
        warn( 'error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub outputURLset{
    my $self=$_[0];
	my $outputURL=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{config} ) ){
   		$self->init;
		if ( $self->error ){
			$self->warnString('Failed to initialize the gallery config');
			return undef;
		}
    }

	if ( ! defined( $outputURL ) ){
		$self->{error}=9;
		$self->{errorString}='No output URL specified';
		$self->warn;
		return undef;
	}

	$self->{config}->{'_'}->{'outputURL'}=$outputURL;

	$self->writeConfig;
	if ( $self->error ){
		$self->warnString('Failed to write the config out');
		return undef;
	}

    return 1;
}

=head2 srcPathGet

This returns the source path.

    my $srcPath=$foo->srcPath;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub srcPathGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{config} ) ){
		$self->{error}=4;
		$self->{errorString}='No config for the current directory';
		$self->warn;
		return undef;
	}

	return $self->{config}->{'_'}->{'srcPath'};
}

=head2 srcPathSet

This sets the that to search for images.

One argument is required and it is a path.

    $foo->srcPathSet( $srcPath );
    if ( $foo->error ){
        warn( 'error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub srcPathSet{
	my $self=$_[0];
	my $srcPath=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{config} ) ){
   		$self->init;
		if ( $self->error ){
			$self->warnString('Failed to initialize the gallery config');
			return undef;
		}
	}

	if ( ! defined( $srcPath ) ){
		$self->{error}=6;
		$self->{errorString}='No source path specified';
	}

	$self->{config}->{'_'}->{'srcPath'}=$srcPath;

	$self->writeConfig;
	if ( $self->error ){
		$self->warnString('Failed to write the config out');
		return undef;
	}

	return 1;
}

=head2 srcURLget

This gets the URL to use for the images.

    my $srcURLget=$foo->srcURLget;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub srcURLget{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{config} ) ){
        $self->{error}=4;
        $self->{errorString}='No config for the current directory';
        $self->warn;
        return undef;
    }

	return $self->{config}->{'_'}->{'srcURL'};
}

=head2 srcURLset

This sets the URL that is used for linking to the source images.

    $foo->srcURLset( $url );
    if ( $foo->error ){
        warn( 'error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub srcURLset{
    my $self=$_[0];
	my $srcURL=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{config} ) ){
   		$self->init;
		if ( $self->error ){
			$self->warnString('Failed to initialize the gallery config');
			return undef;
		}
    }

    if ( ! defined( $srcURL ) ){
        $self->{error}=7;
		$self->{errorString}='Nothing specified for the source URL';
		$self->warn;
		return undef;
    }

	$self->{config}->{'_'}->{'srcURL'}=$srcURL;

	$self->writeConfig;
	if ( $self->error ){
		$self->warnString('Failed to write the config out');
		return undef;
	}

	return 1;
}

=head2 renderUpdateDetailsGet

Returns if upon rendering it should update image details or not.

The return value is a Perl boolean.

    my $update=$foo->renderUpdateDetailsGet;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub renderUpdateDetailsGet{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{config} ) ){
        $self->{error}=4;
        $self->{errorString}='No config for the current directory';
        $self->warn;
        return undef;
    }

    if ( ! defined( $self->{config}->{'_'}->{'renderUpdateDetails'} ) ){
        return 0;
    }

    return $self->{config}->{'_'}->{'renderUpdateDetails'};
}

=head2 renderUpdateDetailsSet

This sets wether or note Toader::Render::Gallery->render should
update the details or not.

This takes a Perl boolean.

    $foo->renderUpdateDetailsGet( $update );
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub renderUpdateDetailsSet{
    my $self=$_[0];
    my $update=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $update ) ){
        $update=0;
    }

	if ( $update ){
		$update=1;
	}

    if ( ! defined( $self->{config} ) ){
        $self->{error}=4;
        $self->{errorString}='No config for the current directory';
        $self->warn;
        return undef;
    }

    $self->{config}->{'_'}->{'renderUpdateDetails'}=$update;

    return 1;
}

=head2 renderUpdateIndexesGet

Returns if upon rendering it should update the indexes or not.

The return value is a Perl boolean.

    my $update=$foo->renderUpdateIndexesGet;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub renderUpdateIndexesGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{config} ) ){
		$self->{error}=4;
		$self->{errorString}='No config for the current directory';
		$self->warn;
		return undef;
	}

	if ( ! defined( $self->{config}->{'_'}->{'renderUpdateIndexes'} ) ){
		return 0;
	}

	return $self->{config}->{'_'}->{'renderUpdateIndexes'};
}

=head2 renderUpdateIndexesSet

This sets wether or note Toader::Render::Gallery->render should
update the indexes or not.

This takes a Perl boolean.

    $foo->renderUpdateIndexesGet( $update );
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub renderUpdateIndexesSet{
	my $self=$_[0];
	my $update=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $update ) ){
		$update=0;
	}

	if ( $update ){
		$update=1;
	}

	if ( ! defined( $self->{config} ) ){
		$self->{error}=4;
		$self->{errorString}='No config for the current directory';
		$self->warn;
		return undef;
	}

	$self->{config}->{'_'}->{'renderUpdateIndexes'}=$update;

	return 1;
}

=head2 renderUpdateScaledGet

Returns if upon rendering it should update the scaled images or not.

The return value is a Perl boolean.

    my $update=$foo->renderUpdateIndexesGet;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub renderUpdateScaledGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{config} ) ){
		$self->{error}=4;
		$self->{errorString}='No config for the current directory';
		$self->warn;
		return undef;
	}

	if ( ! defined( $self->{config}->{'_'}->{'renderUpdateScaled'} ) ){
		return 0;
	}

	return $self->{config}->{'_'}->{'renderUpdateScaled'};
}

=head2 renderUpdateScaledSet

This sets wether or note Toader::Render::Gallery->render should
update the scaled images or not.

This takes a Perl boolean.

    $foo->renderUpdateIndexesGet( $update );
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub renderUpdateScaledSet{
	my $self=$_[0];
	my $update=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $update ) ){
		$update=0;
	}

	if ( $update ){
		$update=1;
	}

	if ( ! defined( $self->{config} ) ){
		$self->{error}=4;
		$self->{errorString}='No config for the current directory';
		$self->warn;
		return undef;
	}

	$self->{config}->{'_'}->{'renderUpdateScaled'}=$update;

	return 1;
}

=head2 resolutionSmallGet

Returns the small resolution.

    my $smallRes=$foo->resolutionSmallGet;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub resolutionSmallGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{config} ) ){
		$self->{error}=4;
		$self->{errorString}='No config for the current directory';
		$self->warn;
		return undef;
	}

	if ( ! defined( $self->{config}->{'_'}->{'smallResolution'} ) ){
		return 200;
	}

	if ( $self->{config}->{'_'}->{'smallResolution'} !~ /^[0123456789]*$/ ){
		$self->{error}=5;
		$self->{errorString}='"'.$self->{config}->{'_'}->{'smallResolution'}.'" is not numeric';
		$self->warn;
		return undef;
	}

	return $self->{config}->{'_'}->{'smallResolution'};
}

=head2 resolutionSmallSet

Sets the small resolution.

One argument is taken and that is the maximum resolution for a
image. If not specified, it resets it to 200.

    my $smallRes=$foo->resolutionSmallSet( $resolution );
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub resolutionSmallSet{
	my $self=$_[0];
	my $res=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{config} ) ){
   		$self->init;
		if ( $self->error ){
			$self->warnString('Failed to initialize the gallery config');
			return undef;
		}
	}

	if ( ! defined( $res ) ){
		$res=200;
	}

	if ( $self->{config}->{'_'}->{'smallResolution'} !~ /^[0123456789]*$/ ){
		$self->{error}=5;
		$self->{errorString}='"'.$self->{config}->{'_'}->{'smallResolution'}.'" is not numeric';
		$self->warn;
		return undef;
	}

	$self->{config}->{'_'}->{'smallResolution'}=$res;

	$self->writeConfig;
	if ( $self->error ){
		$self->warnString('Failed to write the config out');
		return undef;
	}

	return 1;
}

=head2 resolutionLargeGet

Returns the larg resolution.

    my $largeRes=$foo->resolutionLargeGet;
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub resolutionLargeGet{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{config} ) ){
		$self->{error}=4;
		$self->{errorString}='No config for the current directory';
		$self->warn;
		return undef;
	}

	if ( ! defined( $self->{config}->{'_'}->{'smallResolution'} ) ){
		return 1024;
	}

	if ( $self->{config}->{'_'}->{'smallResolution'} !~ /^[0123456789]*$/ ){
		$self->{error}=5;
		$self->{errorString}='"'.$self->{config}->{'_'}->{'smallResolution'}.'" is not numeric';
		$self->warn;
		return undef;
	}

	return $self->{config}->{'_'}->{'smallResolution'};
}

=head2 resolutionLargeSet

Returns the larg resolution.

One argument is taken is the maximum resolution to use.
If not specified, it resets it to the default, 1024.

    $foo->resolutionLargeSet( $res );
    if ( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub resolutionLargeSet{
	my $self=$_[0];
	my $res=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if ( ! defined( $self->{config} ) ){
   		$self->init;
		if ( $self->error ){
			$self->warnString('Failed to initialize the gallery config');
			return undef;
		}
	}

	if ( ! defined( $res ) ){
		$res=1024;
	}

	if ( $self->{config}->{'_'}->{'smallResolution'} !~ /^[0123456789]*$/ ){
		$self->{error}=5;
		$self->{errorString}='"'.$self->{config}->{'_'}->{'smallResolution'}.'" is not numeric';
		$self->warn;
		return undef;
	}

	$self->{config}->{'_'}->{'smallResolution'}=$res;

	$self->writeConfig;
	if ( $self->error ){
		$self->warnString('Failed to write the config out');
		return undef;
	}

	return 1;
}

=head2 usable

This checks if the this object is usable for rendering or not.

It does not check if the directories exist, other than the settings are
specified.

    if ( ! $foo->usable ){
        print "This is not a renderable object currently... something is missing...\n";
    }

=cut

sub usable{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

	if ( ! defined( $self->{config} ) ){
		return undef;
	}

	if ( ! defined( $self->{outputPath} ) ) {
		return undef;
	}

	if ( ! defined( $self->{outputURL} ) ) {
		return undef;
	}

	if ( ! defined( $self->{srcPath} ) ) {
		return undef;
	}

	if ( ! defined( $self->{srcURL} ) ) {
		return undef;
	}

	if ( defined( $self->{smallResolution} ) ) {
		if ( $self->{smallResolution} !~ /^[0123456789]*/ ){
			return undef;
		}
	}

	if ( defined( $self->{largeResolution} ) ) {
		if ( $self->{largeResolution} !~ /^[0123456789]*/ ){
			return undef;
		}
	}

	return 1;
}

=head2 writeConfig

This writes the config out.

=cut

sub writeConfig{
    my $self=$_[0];
    my $res=$_[1];

    if (!$self->errorblank){
        return undef;
    }

    if ( ! defined( $self->{config} ) ){
        $self->{error}=4;
        $self->{errorString}='No config for the current directory';
        $self->warn;
        return undef;
    }

	if ( ! $self->{config}->write( $self->{dir}.'/.toader/gallery.ini' ) ){
		$self->{error}=11;
		$self->{errorString}='Failed to write the config out to "'.$self->{dir}.'/.toader/gallery.ini"';
		$self->warn;
		return undef;
	}
	
	return 1;
}

=head1 REQUIRED RENDERING METHODS

The ones listed below are useless and are just included for
compatibility reasons.

    filesDir
    renderDir
    toDir

=head2 filesDir

This returns the file directory for the object.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

This returns '' as it is not used by this module. As for rendering,
fullURL is set for L<Toader::Render::General>.

=cut

sub filesDir{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	return '';
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

	return 'Gallery';
}

=head2 renderDir

This is the directory that it will be rendered to.

The base directory that will be used for rendering.

This returns '' as it is not used by this module. As for rendering,
fullURL is set for L<Toader::Render::General>.

=cut

sub renderDir{
	return '';
}

=head2 renderUsing

This returns the module to use for rendering.

    my $module=$foo->renderUsing;

=cut

sub renderUsing{
    return 'Toader::Render::Gallery';
}

=head2 toaderRenderable

This method returns true and marks it as being L<Toader>
renderable.

=cut

sub toaderRenderable{
	return 1;
}

=head2 toDir

This returns the directory that will return the directory
that contains where this object should be rendered to.

This is not a full path, but a partial path that should
be appended the directory current directory being outputted to.

This returns '' as it is not used by this module. As for rendering,
fullURL is set for L<Toader::Render::General>.

=cut

sub toDir{
    my $self=$_[0];

    if (!$self->errorblank){
        return undef;
    }

    return '';
}

=head1 ERROR CODES

=head2 1

No directory specified.

=head2 2

The directory is not a Toader directory.

=head2 3

Failed to read the gallery config.

=head2 4

No config for this directory.

=head2 5

The specified resolution is non-numeric.

=head2 6

No source path specified.

=head2 7

No source URL specified.

=head2 8

No output path specified.

=head2 9

No output URL specified.

=head2 10

The directory has already been initialized.

=head2 11

Failed to initialize Toader::pathHelper.

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

1; # End of Toader::Gallery
