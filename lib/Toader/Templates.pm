package Toader::Templates;

use warnings;
use strict;
use Toader::isaToaderDir;
use Cwd 'abs_path';
use base 'Error::Helper';
use Text::Template;
use Toader::Templates::Defaults;

=head1 NAME

Toader::Templates - This handles fetching Toader templates.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

For information on the storage and rendering of entries,
please see 'Documentation/Templates.pod'.

=head1 METHODS

=head2 new

=head3 args hash ref

=head4 dir

This is the directory to intiate in.

    my $foo = Toader::Templates->new();

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  isatd=>Toader::isaToaderDir->new(),
			  dir=>undef,
			  defaults=>Toader::Templates::Defaults->new,
			  };
	bless $self;

	if ( defined( $args{dir} ) ){
		if ( ! $self->{isatd}->isaToaderDir( $args{dir} ) ){
			$self->{perror}=1;
			$self->{error}=1,
			$self->{errorString}='The specified directory is not a Toader directory';
			$self->warn;
			return $self;
		}
		$self->{dir}=$args{dir};
	}



	return $self;
}

=head2 dirGet

This gets L<Toader> directory this entry is associated with.

This will only error if a permanent error is set.

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

    $foo->dirSet($toaderDirectory);
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

	#checks if the directory is Toader directory or not
    my $returned=$self->{isatd}->isaToaderDir($dir);
	if (! $returned ) {
		$self->{error}=1;
		$self->{errorString}='"'.$dir.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	$self->{dir}=$dir;

	return 1;
}

=head2 fill_in

This fills in a template that has been passed to it.

Two arguments are taken. The first is the template name.
The second is a hash reference. 

The returned string is the filled out template.

    my $rendered=$foo->fill_in( $templateName, \%hash );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub fill_in{
	my $self=$_[0];
	my $name=$_[1];
	my %hash;
	if ( defined( $_[2] ) ){
		%hash=%{ $_[2] };
	}

	if( ! $self->errorblank ){
		return undef;
	}

	#make sure a template name is specified
	if ( ! defined( $name ) ){
		$self->{error}=9;
		$self->{errorString}='No template name specified';
		$self->warn;
		return undef;
	}

	#gets the template
	my $template=$self->getTemplate( $name );
	if ( $self->error ){
		return undef;
	}

	return $self->fill_in_string( $template, \%hash );
}

=head2 fill_in_string

This fills in a template that has been passed to it.

Two arguments are required and the first is the template string to use and
second it is the hash to pass to it.

The returned string is the filled out template.

    my $rendered=$foo->fill_in_string( $templateString, \%hash );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub fill_in_string{
	my $self=$_[0];
	my $string=$_[1];
	my %hash;
	if ( defined( $_[2] ) ){
		%hash=%{ $_[2] };
	}

	if( ! $self->errorblank ){
		return undef;
	}

	if ( ! defined( $string ) ){
		$self->{error}=8;
		$self->{errorString}='No template string specified';
		$self->warn;
		return undef;
	}

	my $template = Text::Template->new(
		TYPE => 'STRING',
		SOURCE => $string,
		DELIMITERS=>[ '[==', '==]' ],
		);

	my $rendered=$template->fill_in(
		HASH=>\%hash,
		);

	if ( ! defined ( $rendered ) ){
		$self->{error}=7;
		$self->{errorString}='Error encountered filling in the template';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 findTemplate

This finds a specified template.

One arguement is taken and it is the name of the template.

A return of undef can mean either a error or it was not found.
If there was an error, the method error will return true.

    my $templateFile=$foo->findTemplate($templateName);
    if( !defined( $templateFile ) ){
        if($foo->error){
            warn('Error:'.$foo->error.': '.$foo->errorString);
        }else{
            print("Not found\n");
        }
    }else{
        print $templateFile."\n";
    }

=cut

sub findTemplate{
	my $self=$_[0];
	my $name=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been set
	if (!defined( $self->{dir} )) {
		$self->{error}=2;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;		
	}

	#checks if the name is valid
	my $returned=$self->templateNameCheck($name);
	if (! $returned ) {
		$self->{error}=4;
		$self->{errorString}='"'.$name.'" is not a valid template name';
		$self->warn;
		return undef;
	}

	#checks if the directory is Toader directory or not
    $returned=$self->{isatd}->isaToaderDir( $self->{dir} );
	if (! $returned ) {
		$self->{error}=3;
		$self->{errorString}='"'.$self->{dir}.'" is no longer a Toader directory';
		$self->warn;
		return undef;
	}

	#initial stuff to check
	my $dir=$self->{dir};
	my $template=$dir.'/.toader/templates/'.$name;

	#checks if the template exists
	if (-f $template) {
		return $template;
	}

	#recurse down trying to find the last one
	$dir=abs_path($dir.'/..');
	#we will always find something below so it is just set to 1
	while (1) {
		#we hit the FS root...
		#if he hit this, something is definitely wrong
		if ($dir eq '/') {
			return undef;
		}

		#make sure
		$returned=$self->{isatd}->isaToaderDir($dir);
		if (!$returned) {
			return undef;
		}

		#check if it exists
		$template=$dir.'/.toader/templates/'.$name;
		if (-f $template) {
			return $template;
		}

		#check the next directory
		$dir=abs_path($dir.'/..');
	}
}

=head2 getTemplate

This finds a template and then returns it.

The method findTemplate will be used and if that fails the default
template will be returned.

One arguement is required and it is the template name.

    my $template=$foo->getTemplate($templateName);
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getTemplate{
	my $self=$_[0];
	my $name=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a template name is specified
    if ( ! defined( $name ) ){
        $self->{error}=9;
        $self->{errorString}='No template name specified';
        $self->warn;
        return undef;
    }

	#try to find it as a file
	#also allow this to do the error checking as it is the same
	my $file=$self->findTemplate($name);
	if ($self->error) {
		$self->warnString('findTemplate errored');
		return undef;
	}

	#the contents of the template to be returned
	my $template;

	#if we found a file, read it and return it
	if (defined($file)) {
		my $fh;
		if ( ! open( $fh, '<', $file ) ) {
			$self->{error}=5;
			$self->{errorString}="Unable to open '".$file."'";
			$self->warn;
			return undef;
		}
		$template=join('',<$fh>);
		close $fh;
		return $template;
	}

	#tries to fetch the default template
	$template=$self->{defaults}->getTemplate($name);
	if ( ! defined( $template ) ) {
			$self->{error}=6;
			$self->{errorString}='No default template';
			$self->warn;
			return undef;
	}

	return $template;
}

=head2 listTemplates

This lists the various themes in the directory.

    my @templates=$foo->listTemplates;
    if($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub listTemplates{
	my $self=$_[0];

	if (!$self->errorblank){
		return undef;
	}

	#make sure a directory has been set
	if (!defined( $self->{dir} )) {
		$self->{error}=2;
		$self->{errorString}='No directory has been set yet';
		$self->warn;
		return undef;
	}

	#checks if the directory is Toader directory or not
    my $returned=$self->{isatd}->isaToaderDir( $self->{dir} );
	if (! $returned ) {
		$self->{error}=3;
		$self->{errorString}='"'.$self->{dir}.'" is no longer a Toader directory';
		$self->warn;
		return undef;
	}

	#the directory to list
	my $dir=$self->{dir}.'/.toader/templates/';

	#makes sure the template exists and if it does not, return only having the default
	if (! -d $dir) {
		return ['default'];
	}

	#lists each theme
	my $dh;
	if (opendir($dh, $dir )) {
		$self->{error}='4';
		$self->{errorString}='Failed to open the directory "'.$dir.'"';
		$self->warn;
		return undef;
	}
	my @templates=grep( { -f $dir.'/'.$_ } readdir($dh) );
	close($dh);
	
	return @templates;
}

=head2 templateNameCheck

This makes sure checks to make sure a template name is valid.

    my $returned=$foo->templateNameCheck($name);
    if ($returned){
        print "Valid\n";
    }

=cut

sub templateNameCheck{
	my $self=$_[0];
	my $name=$_[1];

	if (!$self->errorblank){
		return undef;
	}

	if (!defined($name)) {
		return 0;
	}
	if ($name =~ /^ /) {
		return 0;
	}
	if ($name =~ /\t/) {
		return 0;
	}
	if ($name =~ /\n/) {
		return 0;
	}
	if ($name =~ / $/) {
		return 0;
	}

	return 1;
}

=head1 ERROR CODES

=head2 1

The specified directory is not a L<Toader> directory.

=head2 2

No directory has been specified yet.

=head2 3

The directory in question is no longer a toader directory.

=head2 4

Not a valid template name.

=head2 5

Unable to open the template file.

=head2 6

Unable to fetch the default template. It does not exist.

=head2 7

Errored filling out the template string.

=head2 8

Nothing specified for the template string.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Templates


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
