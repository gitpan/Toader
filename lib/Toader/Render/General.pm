package Toader::Render::General;

use warnings;
use strict;
use base 'Error::Helper';
use Toader::Templates;
use Toader::Entry::Helper;
use Toader::Entry::Manage;
use Toader::Page::Helper;
use Toader::Page::Manage;
use Toader::Render::CSS;
use Toader::Render::Entry;
use Toader::Render::supportedObjects;
use Toader::pathHelper;
use File::Spec;
use Toader::Directory;
use Email::Address;
use Toader::AutoDoc;

=head1 NAME

Toader::Render::General - Renders various general stuff for Toader as well as some other stuff.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 METHODS

=head2 new

This initiates the object.

=head3 args hash ref

=head4 toader

This is the L<Toader> object.

=head4 obj

This is the L<Toader> object being worked with.

=head4 toDir

This is the path to use for getting back down to the directory.

Lets say we have rendered a single entry to it's page, then it would
be "../../", were as if we rendered a page of multiple entries it
would be "../".

The default is "../../".

=head4 dir

This is the directory that it is currently in. This can differ from the object directory
and if not defined will be set to the object directory, which is found via $args{obj}->dirGet.

    my $g=Toader::Render::General->new(\%args);
    if($g->error){
        warn('error: '.$g->error.":".$g->errorString);
    }

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
			  isatd=>Toader::isaToaderDir->new,
			  soc=>Toader::Render::supportedObjects->new,
			  toDir=>'../../',
			  };
	bless $self;

	if ( defined ( $args{toDir} ) ){
		$self->{toDir}=$args{toDir};
	}

	#make sure we have a usable Toader object
	if ( ! defined( $args{toader} ) ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='No Toader object defined';
		$self->warn;
		return $self;
	}
	if ( ref( $args{toader} ) ne 'Toader' ){
		$self->{perror}=1;
        $self->{error}=2;
        $self->{errorString}='The specified Toader object is actually a "'.ref( $args{ref} ).'"';
        $self->warn;
        return $self;
    }
	if ( ! $args{toader}->errorblank ){
		$self->{perror}=1;
        $self->{error}=3;
        $self->{errorString}='The Toader object has a permanent error set';
        $self->warn;
        return $self;
	}
	$self->{toader}=$args{toader};
	$self->{ph}=$self->{toader}->getPathHelper;
	
	#make sure we have a usable object
	if ( ! defined( $args{obj} ) ){
		$self->{perror}=1;
		$self->{error}=4;
		$self->{errorString}='No object specified for the renderable object';
		$self->warn;
		return $self;
	}
	if ( ! $self->{soc}->isSupported( $args{obj} ) ){
		$self->{perror}=1;
		$self->{error}=5;
		$self->{errorString}='"'.ref( $args{obj} ).'" does not appear to be a Toader renderable object';
		$self->warn;
		return $self;
	}
	if ( ! $args{obj}->errorblank ){
		$self->{perror}=1;
		$self->{error}=6;
		$self->{errorString}='The specified renderable object has a permanent error set';
		$self->warn;
		return $self;
	}
	$self->{obj}=$args{obj};

	#make sure the renderable object has a directory set
	$self->{odir}=$self->{obj}->dirGet;
	if ( ! defined( $self->{odir} ) ){
		$self->{perror}=1;
		$self->{error}=7;
		$self->{errorString}='The renderable object does not have a directory specified';
		$self->warn;
		return $self;
	}

	#initialize the Toader::pathHelper
	$self->{ph}=Toader::pathHelper->new( $self->{odir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=6;
		$self->{errorString}='Failed to initiate pathHelper. error="'.
			$self->{ph}->error.'" errorString="'.$self->{ph}->errorString.'"';
		$self->warn;
		return $self;
	}

	#get this once as it does not change and is likely to be used
	#gets the r2r for the object
	$self->{or2r}=$self->{ph}->relative2root( $self->{odir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=19;
		$self->{errorString}='pathHelper failed to find the relative2root path for "'.
			$self->{odir}.'"';
		$self->warn;
		return $self;
	}
	#get the b2r for the object
	$self->{ob2r}=$self->{toDir}.'/'.$self->{ph}->back2root( $self->{odir} );
	if ( $self->{ph}->error ){
		$self->{perror}=1;
		$self->{error}=20;
		$self->{errorString}='pathHelper failed to find the relative2root path for "'.
			$self->{odir}.'"';
		$self->warn;
		return $self;
	}
	#makes gets the directory to work in
	if ( defined( $args{dir} ) ){
		$self->{dir}=$args{dir};
		$self->{r2r}=$self->{ph}->relative2root( $self->{dir} );
		if ( $self->{ph}->error ){
			$self->{perror}=1;
			$self->{error}=19;
			$self->{errorString}='pathHelper failed to find the relative2root path for "'.
				$self->{dir}.'"';
			return $self;
		}
		$self->{b2r}=$self->{toDir}.'/'.$self->{toDir}.'/'.$self->{ph}->relative2root( $self->{dir} );
		if ( $self->{ph}->error ){
			$self->{perror}=1;
			$self->{error}=20;
			$self->{errorString}='pathHelper failed to find the relative2root path for "'.
				$self->{dir}.'"';
			return $self;
		}
	}else{
		$self->{dir}=$self->{odir};
		$self->{r2r}=$self->{or2r};
		$self->{b2r}=$self->{ob2r};
	}
	
	#clean up the various paths
	$self->{dir}=File::Spec->canonpath( $self->{dir} );
	$self->{r2r}=File::Spec->canonpath( $self->{r2r} );
	$self->{b2r}=File::Spec->canonpath( $self->{b2r} );
    $self->{or2r}=File::Spec->canonpath( $self->{or2r} );
    $self->{ob2r}=File::Spec->canonpath( $self->{ob2r} );


	#figures out the file directory
	$self->{toFiles}=$self->{b2r}.'/'.$self->{or2r}.'/'.$self->{obj}->filesDir;
	$self->{toFiles}=File::Spec->canonpath( $self->{toFiles} );

	#initiates the Templates object
	$self->{t}=Toader::Templates->new({ dir=>$self->{dir} });
	if ( $self->{t}->error ){
		$self->{perror}=1;
		$self->{error}=18;
		$self->{errorString}='Failed to initialize the Toader::Templates module';
		$self->warn;
		return $self;
	}

	#checks if it is at the root or not
	$self->{atRoot}=$self->{ph}->atRoot( $self->{odir} );

	return $self;
}

=head2 adlink

This generates a link to the the specified documentation file.

Three arguments are taken. The first is the relative directory to the
Toader root in which it resides, which if left undefined is the same
as the object used to initiate this object. The second is file found by
autodoc. The third is the text for the link, which if left undefined is
the same as the file.

    $g->cdlink( $directory,  $file, $text );

The template used for this is 'linkDirectory', which by default
is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed to it are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
	obj - This is the object that Toader was initiated with.

=cut

sub adlink{
	my $self=$_[0];
	my $dir=$_[1];
	my $file=$_[2];
	my $txt=$_[3];

	#blanks any previous errors
	if ( ! $self->errorblank ){
        return undef;
	}

	if ( ! defined( $dir ) ){
		$dir=$self->{r2r};
	}

	# make sure a file is specified
	if ( ! defined( $file ) ){
		$self->{error}=17;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	#make sure it does not start with ../
	if ( $file =~ /^\.\.\// ){
		$self->{error}=34;
		$self->{errorString}='File matches /^..\//';
		$self->warn;
		return undef;
	}

	#append .html for POD docs
	if ( $file =~ /\.[Pp][Oo][Dd]$/ ){
		$file=$file.'.html';
	}
	if ( $file =~ /\.[Pp][Mm]$/ ){
		$file=$file.'.html';
	}

	if ( ! defined( $txt ) ){
		$txt=$file;
	}

	my $link=$self->{b2r}.'/'.$dir.'/.autodoc/.files/'.$file;

    #renders the beginning of the authors links
    my $adlink=$self->{t}->fill_in(
        'autodocLink',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
			url=>$link,
			text=>$txt,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	return $adlink;
}

=head2 adListLink

This returns a link to the documentation list.

The template used for this is 'linkAutoDocList', which by default
is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed to it are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::General> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    obj - This is the object that Toader was initiated with.

=cut

sub adListLink{
	my $self=$_[0];
	my $text=$_[1];

    if ( ! $self->errorblank ){
        return undef;
    }

	if (! defined( $text ) ){
		$text='Documentation';
	}

	my $link=$self->{b2r}.'/'.$self->{r2r}.'/.autodoc/';

    #renders the beginning of the authors links
    my $adllink=$self->{t}->fill_in(
        'linkAutoDocList',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            url=>$link,
            text=>$text,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

    return $adllink;
}

=head2 atRoot

This returns a Perl boolean value for if the current directory
is the root L<Toader> directory or not.

    my $atRoot=$g->atRoot;
    if ( $aRoot ){
        print "At root.\n";
    }

=cut

sub atRoot{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	return $self->{atRoot};
}

=head2 authorsLink

Used for generating the author line.

This parses a From header, such as the value returned
from Toader::Entry->fromGet.

One value is requied and that is what is to be parsed and
returned as a link.

    $g->authorsLink($entry->fromGet);

=head3 Templates

=head4 authorBegin

This begins the authors link section.

The default template is blank.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 authorLink

This is a link for one of the authors.

The default template is as below.

    <a href="mailto:[== $address ==]">[== $name ==]</a>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    address - The email address of the author.
    comment - The comment portion of it.
    original - The original form for this chunk.
    name - The name of the author.

=head4 authorJoin

This is used for joining multiple authors.

The default template is as below.

    , 
    

The variables passed to it are as below.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 authorEnd

This ends the authors link section.

The default template is blank.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=cut

sub authorsLink{
	my $self=$_[0];
	my $aline=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#make sure we have a authors line
	if ( ! defined( $aline ) ){
		$self->{error}=29;
		$self->{errorString}='No author line defined';
		$self->warn;
		return undef;
	}

	#parses the address
	my @a=Email::Address->parse($aline);
	if ( ! defined( $a[0] ) ){
		$self->{error}=30;
		$self->{errorString}='The author line "'.$aline.'" could not be parsed';
		$self->warn;
		return undef;
	}

	#process each
	my $int=0;
	my @tojoin;
	while ( defined( $a[$int] ) ){
		my $rendered=$self->{t}->fill_in(
			'authorLink',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				address=>$a[$int]->address,
				comment=>$a[$int]->comment,
				original=>$a[$int]->original,
				name=>$a[$int]->name,
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}

		push( @tojoin, $rendered );

		$int++;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'authorJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the beginning of the authors links
	my $begin=$self->{t}->fill_in(
		'authorBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}


	#renders the end of the authors links
	my $end=$self->{t}->fill_in(
		'authorEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 autodocList

This a list of generates a table of the various
documents.

One argument is accepted and the directory under the l<Toader> root
directory. If not specified, it is the same as object used to initate
this object.

    $g->autodocList;

=head3 Templates

=head4 autodocListBegin

This initiates the table for the list.

The default template is as below.

    <table id="autodocList">
      <tr> <td>File</td> </tr>
    

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    dir - This is the directory relative to the root L<Toader> directory.

=head4 autodocListRow

This is the represents a row in the document table.

The default template is as below.

      <tr id="autodocList">
        <td id="autodocList">[== $g->adlink( $dir, $file ) ==]</td>
      </tr>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    dir - This is the directory relative to the root L<Toader> directory.
    file - This is the file to show.

=head4 autodocListJoin

This is used to join the table rows.

The default template is blank.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    dir - This is the directory relative to the root L<Toader> directory.

=head4 autodocListEnd

This is ends the documentation list.

The default template is as below.

    </table>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    dir - This is the directory relative to the root L<Toader> directory.

=cut

sub autodocList{
	my $self=$_[0];
	my $dir=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	if ( ! defined( $dir ) ){
		$dir=$self->{r2r};
	}

	my $fullpath=$self->{toader}->getRootDir.'/'.$dir;

	my $ad=Toader::AutoDoc->new;

	$ad->dirSet( $fullpath );
	if ( $ad->error ){
		$self->{error}=35;
		$self->{errorString}='Failed to set the directory for the Toader::AutoDoc object to "'.$fullpath.'"';
		$self->warn;
		return undef;
	}

	my @files=$ad->findDocs;
	if ( $ad->error ){
		$self->{error}=36;
		$self->{errorString}='';
		$self->warn;
		return undef;
	}
	
	#puts together the list of docs
	my $int=0;
	my @links;
	while ( defined( $files[$int] ) ){
		
		my $rendered=$self->{t}->fill_in(
			'autodocListRow',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				g=>\$self,
				file=>$files[$int],
				dir=>$dir,
			}
			);
        if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
        }
		
		push( @links, $rendered );

		$int++;
	}

	my $begin=$self->{t}->fill_in(
		'autodocListBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
			dir=>$dir,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

    my $join=$self->{t}->fill_in(
        'autodocListJoin',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            dir=>$dir,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

    my $end=$self->{t}->fill_in(
        'autodocListEnd',
        {
            toDir=>$self->{toDir},
            toFiles=>$self->{toFiles},
            obj=>\$self->{obj},
            c=>\$self->{toader}->getConfig,
            toader=>\$self->{toader},
            self=>\$self,
            g=>\$self,
            dir=>$dir,
        }
        );
    if ( $self->{t}->error ){
        $self->{error}=10;
        $self->{errorString}='Failed to fill in the template. error="'.
            $self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
        $self->warn;
        return undef;
    }

	return $begin.join($join, @links).$end;
}

=head2 b2r

This returns the current value to get back to the root.

    my $b2r=$g->b2r;

=cut

sub b2r{
	my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	return $self->{b2r};
}

=head2 cdlink

This generates a link to the current directory.

There is one option arguement. This is the text for the link.
If not specified, it defaults to ".".

    $g->cdlink( "to current directory" );

The template used for this is 'linkDirectory', which by default
is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed to it are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub cdlink{
	my $self=$_[0];
	my $text=$_[1];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text='./';
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'linkDirectory',
		{
			url=>$self->{toDir},
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 css

This renders the CSS template and returns it.

    $g->css;

For more information on the CSS template and rendering
please see 'Documentation/CSS.pod'.

=cut

sub css{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	my $renderCSS=Toader::Render::CSS->new( $self->{toader} );

	my $css=$renderCSS->renderCSS;
	if ( $renderCSS->error ){
		$self->{error}=18;
		$self->{errorString}='Failed to render the CSS. error="'.
			$renderCSS->error.'" errorString="'.
			$renderCSS->errorString.'"';
		$self->warn;
		return undef;
	}

	return $css;
}

=head2 cssLocation

This returns the relative location to a the CSS file.

    $g->cssLocation;

=cut

sub cssLocation{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	return $self->{b2r}.'/toader.css';
}

=head2 dlink

This generates a link to a different directory object.

Two arguments are taken.

The first and required one is the L<Toader> directory
to link to. This needs to be relative.

The second is the text, which if not specified will will be the
same the link.

    $g->link( "./foo/bar", "more info on foo/bar" );

The template used for this is 'linkDirectory', which by default
is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed to it are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the L<Toader> config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub dlink{
	my $self=$_[0];
	my $dir=$_[1];
	my $text=$_[2];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $dir ) ){
		$self->{error}=11;
		$self->{errorString}='No Toader directory defined';
		$self->warn;
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text=$dir;
	}

	#handles it if it is a full path
	my $dirtest;
	if ( $dir =~ /^\// ){
		$dir=$self->{toader}->getRootDir.$dir;
		$dirtest=$dir;
		$dir=$self->{ph}->relative2root( $dir );
	}else{
		$dirtest=$self->{dir}.'/'.$dir;
	}

	#make sure it is a Toader directory
	if ( ! $self->{isatd}->isaToaderDir( $dirtest ) ){
		$self->{error}=12;
		$self->{errorString}='"'.$dirtest.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#add the toDir to it
	$dir=$self->{toDir}.$dir;
	$dir=~s/\/\/*/\//g;
	
	#render it
	my $rendered=$self->{t}->fill_in(
		'linkDirectory',
		{
			url=>$dir,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 elink

This generates a link to a different directory object.

Two arguments are taken.

The first and required one is the L<Toader> directory containing
the L<Toader> object. This needs to be relative.

The second is the entry to link to.

The third is the text, which if not specified will will be the
same the link.

    $g->link( $dir, $entryID, "whatever at foo.bar" );

The template used is 'linkEntry' and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the L<Toader> config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub elink{
	my $self=$_[0];
	my $dir=$_[1];
	my $entry=$_[2];
	my $text=$_[3];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#use the object dir if not is specified
	if ( ! defined( $dir ) ){
		$self->{error}=11;
		$self->{errorString}='No Toader directory defined';
		$self->warn;
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $dir ) ){
		$self->{error}=13;
		$self->{errorString}='No Toader Entry ID defined';
		$self->warn;
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text=$entry;
	}

	#handles it if it is a full path
	my $dirtest;
	if ( $dir =~ /^\// ){
		$dir=$self->{toader}->getRootDir.$dir;
		$dirtest=$dir;
		$dir=$self->{ph}->relative2root( $dir );
	}else{
		$dirtest=$self->{dir}.'/'.$dir;
	}

	#make sure it is a Toader directory
	if ( ! $self->{isatd}->isaToaderDir( $dirtest ) ){
		$self->{error}=12;
		$self->{errorString}='"'.$dirtest.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#make sure entry exists... will also make sure it exists
	my $eh=Toader::Entry::Helper->new;
	$eh->setDir( $dirtest );
	if ( ! $eh->entryExists( $entry ) ){
		$self->{error}=14;
		$self->{errorString}='The entry ID "'.$entry.'" does not exist for the Toader directory "'.$dirtest.'"';
		$self->warn;
		return undef;
	}

	#add the toDir to it
	$dir=$self->{toDir}.$dir.'/.entries/'.$entry.'/';
	$dir=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'linkEntry',
		{
			url=>$dir,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 entryArchive

This creates the entry archive for the current directory.

No arguments are taken.

    $g->entryArchive;

=head3 Templates

=head4 entryArchiveBegin

This begins the entry archive table.

    <table id="entryArchive">
      <tr> <td>Date</td> <td>Title</td> <td>Summary</td> </tr>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 entryArchiveRow

This generates a row in the entry archive table.

The default template is as below.

      <tr id="entryArchive">
        <td id="entryArchive">[== $g->elink( "./", $date, $date ) ==]</td>
        <td id="entryArchive">[== $title ==]</td>
        <td id="entryArchive">[== $summary ==]</td>
      </tr>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.
    date - This is the entry name/date stamp.
    title - This is the title of the entyr.
    summary - This is a summary of the entry.

=head4 entryArchiveJoin

This joins the entry rows.

The default template is blank.

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the L<Toader> config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 entryArchiveEnd

This ends the authors link section.

The default template is as below.

    </table>

The variables passed to it are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a Toader object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=cut

sub entryArchive{
	my $self=$_[0];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $em=Toader::Entry::Manage->new();
	$em->setDir( $self->{odir} );
	if ( $em->error ){
		$self->{error}=25;
		$self->{errorString}='Failed to set the directory, "'.$self->{odir}.
			'", for Toader::Entry::Manage. error="'.$em->error
			.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#lists the entries for the directory
	my @entries=$em->list;
	if ( $em->error ){
		$self->{error}=25;
		$self->{errorString}='Failed to read the entries for "'.$self->{odir}.
			'". error="'.$em->error.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#return '' if there are none
	if ( ! defined( $entries[0] ) ){
		return '';
	}

	#sort and order from last to first
	@entries=sort(@entries);
	@entries=reverse(@entries);

	#process each one
	my @tojoin;
	my $int=0;
	while ( defined( $entries[$int] ) ){
		my $entry=$em->read( $entries[$int] );
		if ( $em->error ){
			$self->{error}=26;
			$self->{errorString}='Failed to read "'.$entries[$int].'" in "'
				.$self->{odir}.'". error="'.$em->error.'" errorstring="'
				.$em->errorString.'"';
			$self->warn;
			return undef;
		}

		#renders the row
		my $rendered=$self->{t}->fill_in(
			'entryArchiveRow',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				title=>$entry->titleGet,
				summary=>$entry->summaryGet,
				date=>$entry->entryNameGet,
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}		
		
		push( @tojoin, $rendered );

		$int++;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'entryArchiveJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $end=$self->{t}->fill_in(
		'entryArchiveEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $begin=$self->{t}->fill_in(
		'entryArchiveBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 entriesArchiveLink

Link to the entries directory.

One argument is taken and that is the text to use.
If not specifieid, it defaults to "Index".

	$g->entriesIndexLink;

The template is 'entriesArchiveLink' and the default is
as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables used are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub entriesArchiveLink{
	my $self=$_[0];
	my $text=$_[1];

	if ( ! defined( $text ) ){
		$text='Archive';
	}

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#creates the url and cleans it up
	my $url=$self->{toDir}.'/.entries/archive.html';
	$url=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'entriesArchiveLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 entriesLink

Link to the entries directory.

One argument is taken and that is the text to use.
If not specifieid, it defaults to "Latest".

	$g->entriesLink;

The template 'entriesLink' is used and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub entriesLink{
	my $self=$_[0];
	my $text=$_[1];

	if ( ! defined( $text ) ){
		$text='Latest';
	}

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#creates the url and cleans it up
	my $url=$self->{toDir}.'/.entries/';
	$url=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'entriesLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 flink

This generates a link to a included file for the object.

Two arguements are taken. The first and required is the file.
The second and optional is the text to use, which if not specified
is the name of the file.

    $g->flink( $file );

The template 'linkFile' is used and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub flink{
	my $self=$_[0];
	my $file=$_[1];
	my $text=$_[2];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $file ) ){
		$self->{error}=17;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	if ( ! defined( $text ) ){
		$text=$file;
	}

	#creates the URL and cleans it up
	my $url=$self->{toFiles}.'/'.$file;
	$url=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'linkFile',
		{
			url=>$self->{toFiles}.'/'.$file,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 hasDocs

This returns true if the current directory has any
documentation.

    if ( $g->hasDocs ){
        print "This directory has documentation...";
    }

=cut

sub hasDocs{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #returns true if there is a autodoc directory for the current Toader directory
    if ( -d $self->{odir}.'/.toader/autodoc/' ){
        return 1;
    }

    return 0;
}

=head2 hasEntries

Check if a entries directory exists for the
Toader directory for the current object.

A boolean value is returned.

    my $hasEntries=$g->hasEntries;

=cut

sub hasEntries{
	my $self=$_[0];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#returns true if there is a entries directory for the current Toader directory
	if ( -d $self->{odir}.'/.toader/entries/' ){
		return 1;
	}

	return 0;
}

=head2 hasAnyDirs

This returns true if there are either Toader sub directories or
it is not at root.

    if ( $g->hasAnyDirs ){
        print "Either not at root or there are Toader sub directires...";
    }

=cut

sub hasAnyDirs{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	my $subs=$self->hasSubDirs;
	if ( $self->error ){
		$self->warnString('Failed to check if the directory has any Toader sub directories');
		return undef;
	}

	#return 1 as there are directories
	if ( $subs ){
		return 1;
	}

	#if we are at root and there no Toader sub directories then this is the only Toader directory
	if ( $self->atRoot ){
		return 0;
	}

	#we are not at root then there is a directory that can be go gone to
	return 1;
}

=head2 hasSubDirs

This returns to true if the current object
directory has any Toader sub directories.

    if ( $g->hasSubDirs ){
        print "This directory has sub directories.";
    }

=cut

sub hasSubDirs{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    #gets a list of directories
	my @dirs;
	if ( ref( $self->{odir} ) eq 'Toader::Directory' ){
		@dirs=$self->{odir}->listSubToaderDirs;
		if ( $self->{odir}->error ){
			$self->{error}=22;
			$self->{errorString}='Failed to get a list of Toader sub directories. error="'
				.$self->{odir}->error.'" errorString="'.$self->{odir}->errorString.'"';
			return undef;
		}
	}else{
		my $dobj=Toader::Directory->new;
		$dobj->dirSet( $self->{odir} );
		@dirs=$dobj->listSubToaderDirs;
		if ( $dobj->error ){
			$self->{error}=22;
			$self->{errorString}='Failed to get a list of Toader sub directories. error="'
				.$dobj->error.'" errorString="'.$dobj->{odir}->errorString.'"';
			return undef;
		}
	}

	if ( defined( $dirs[0] ) ){
		return 1;
	}
	
	return 0;
}

=head2 lastEntries

This returns the last entries, post rendering each one and joining them.

There is one optional and that is number of last entries to show. If
not specified, it shows the last 15.

    $g->lastEntries;

=head3 Templates

=head4 entryListBegin

This begins the list of the last entries.

The default template is blank.

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 entryListJoin

This joins the rendered entries.

The default template is as below.

    <br>
    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=head4 entryListEnd

This ends the list of rendered entries.

The default template is as below.

    <br>


The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - This is the object that it was invoked for.
    c - The L<Config::Tiny> object containing the Toader config.
    toader - This is a L<Toader> object.
    self - This the L<Toader::Render::General> object.
    g - This the L<Toader::Render::General> object.

=cut

sub lastEntries{
	my $self=$_[0];
	my $show=$_[1];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#default to 15 to show
	if ( ! defined( $show ) ){
		$show=15;
	}
	
	my $em=Toader::Entry::Manage->new();
	$em->setDir( $self->{odir} );
	if ( $em->error ){
		$self->{error}=25;
		$self->{errorString}='Failed to set the directory, "'.$self->{odir}.
			'", for Toader::Entry::Manage. error="'.$em->error
			.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#lists the entries for the directory
	my @entries=$em->list;
	if ( $em->error ){
		$self->{error}=25;
		$self->{errorString}='Failed to read the entries for "'.$self->{odir}.
			'". error="'.$em->error.'" errorString="'.$em->errorString.'"';
		$self->warn;
		return undef;
	}

	#return '' if there are none
	if ( ! defined( $entries[0] ) ){
		return '';
	}

	#sort and order from last to first
	@entries=sort(@entries);
	@entries=reverse(@entries);

	#process each one
	my @tojoin;
	my $int=0;
	while ( defined( $entries[$int] ) ){
		my $entry=$em->read( $entries[$int] );
		if ( $em->error ){
			$self->{error}=26;
			$self->{errorString}='Failed to read "'.$entries[$int].'" in "'
				.$self->{odir}.'". error="'.$em->error.'" errorstring="'
				.$em->errorString.'"';
			$self->warn;
			return undef;
		}

		my $r=Toader::Render::Entry->new({
			obj=>$entry,
			toader=>$self->{toader},
			toDir=>$self->{toDir},
			});
		if ( $r->error ){
			$self->{error}=27;
			$self->{errorString}='Failed to initialize Toader::Render::Entry for "'.
				$entries[$int].'" in "'.$self->{odir}.'". error="'.$r->error.
				'" errorString="'.$r->errorString.'"';
			$self->warn;
			return undef;
		}

		my $rendered=$r->content;
		if ( $r->error ){
			$self->{error}=28;
			$self->{errorString}='Failed to render "'.$entries[$int].'" in "'
				.$self->{odir}.'". error="'.$r->error.'" errorString="'.$r->errorString.'"';
			$self->warn;
			return undef;
		}

		push( @tojoin, $rendered );

		$int++;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'entryListJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the begining of the end of the last entries
	my $begin=$self->{t}->fill_in(
		'entryListBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the end of the last entries
	my $end=$self->{t}->fill_in(
		'entryListEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}


	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 link

This generates a HTML link.

Two arguments are taken. The first and required one is the link.
The second is the text, which if not specified will will be the same
the link.

    $g->link( "http://foo.bar/whatever/", "whatever at foo.bar" );

The template used is 'link' and by default it is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub link{
	my $self=$_[0];
	my $link=$_[1];
	my $text=$_[2];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $link ) ){
		$self->{error}=8;
		$self->{errorString}='No link defined';
		$self->warn;
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text=$link;
	}

	#render it
	my $rendered=$self->{t}->fill_in(
		'link',
		{
			url=>$link,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			self=>\$self,
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 listDirs

This builds the side bar list of directories.

No options are taken.

    $g->listDirs;

=head3 Templates

=head4 dirListBegin

This begins the dirlist.

The template used is 'dirListBegin' and by default is blank.

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 dirListJoin

This joins items in the directory list.

The default template is 'dirListJoin' and it is as below.

    <br> 
    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 dirListLink

This is a link for a directory in the directory list.

The template is 'dirListLink' and it is by default as below.

    <a href="[== $url ==]">[== $text ==]</a>

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry>> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 dirListEnd

This ends the directory list.

The template used is 'dirListEnd' and the default is as below.

    <br> 
    

The passed variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub listDirs{
    my $self=$_[0];
	
    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'dirListJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the beginning of the dir list
	my $begin=$self->{t}->fill_in(
		'dirListBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $end=$self->{t}->fill_in(
		'dirListEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#gets a list of directories
	my @dirs;
	if ( ref( $self->{odir} ) eq 'Toader::Directory' ){
		@dirs=$self->{odir}->listSubToaderDirs;
		if ( $self->{odir}->error ){
			$self->{error}=22;
			$self->{errorString}='Failed to get a list of Toader sub directories. error="'
				.$self->{odir}->error.'" errorString="'.$self->{odir}->errorString.'"';
			return undef;
		}
	}else{
		my $dobj=Toader::Directory->new;
		$dobj->dirSet( $self->{odir} );
		@dirs=$dobj->listSubToaderDirs;
		if ( $dobj->error ){
			$self->{error}=22;
			$self->{errorString}='Failed to get a list of Toader sub directories. error="'
				.$dobj->error.'" errorString="'.$dobj->{odir}->errorString.'"';
			return undef;
		}
	}

	#return black here if there is nothing
	if ( ! defined( $dirs[0] ) ){
		return '';
	}

	#will hold it all prior to joining
	my @tojoin;

	#process it all
	my $int=0;
	while ( defined( $dirs[$int] ) ){
		#add the toDir to it
		my $dir=$self->{toDir}.$dirs[$int];
		$dir=~s/\/\/*/\//g;
	
		#render it
		my $rendered=$self->{t}->fill_in(
			'dirListLink',
			{
				url=>$dir,
				text=>$dirs[$int],
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				self=>\$self,
				toader=>\$self->{toader},
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}

		push( @tojoin, $rendered );

		$int++;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 listPages

This returns returns a list of pages.

No options are taken.

    $g->listPages;

=head3 Templates

=head4 pageListBegin

This begins the page list.

The template is 'pageListBegin' and is blank.

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 pageListJoin

This joins the items in the page list.

The template is 'pageListJoin' and is blank.

    <br>
    

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 pageListLink

This is a link to a page

The template is 'pageListLink' and is blank.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 pageListEnd

This joins the items in the page list.

The template is 'pageListJoin' and is blank.

    <br>
    

The variables passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub listPages{
	my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	#renders the begin
	my $begin=$self->{t}->fill_in(
		'pageListBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'pageListJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $end=$self->{t}->fill_in(
		'pageListEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#gets a list of pages
	my $pm=Toader::Page::Manage->new;
	$pm->setDir( $self->{odir} );
	if ( $pm->error ){
		$self->{error}=23;
		$self->{errorString}='Failed to set the directory for Toader::Page::Manage. '.
			'error="'.$pm->error.'" errorString="'.$pm->errorString.'"';
		$self->warn;
		return undef;
	}
	my @pages=$pm->list;
	if ( $pm->error ){
		$self->{error}=24;
		$self->{errorString}='Failed to get a list of pages. error="'
			.$pm->error.'" errorString="'.$pm->errorString.'"';
		$self->warn;
		return undef;
	}	

	#return blank if there pages
	if ( ! defined( $pages[0] ) ){
		return '';
	}

	#puts it together
	my $int=0;
	my @tojoin;
	while ( $pages[$int] ){
		#add the toDir to it
		my $dir=$self->{toDir}.'/.pages/'.$pages[$int].'/';
		$dir=~s/\/\/*/\//g;
	
		#render it
		my $rendered=$self->{t}->fill_in(
			'pageListLink',
			{
				url=>$dir,
				text=>$pages[$int],
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				self=>\$self,
				toader=>\$self->{toader},
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}

		push( @tojoin, $rendered );

		$int++;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 locationbar

This puts together the the location bar.

One argument is taken and that is what to use for the lcation ID.

    $g->locationbar( $locationID );

=head3 Templates

=head4 locationStart

This starts the location bar.

The template used is 'locationStart' and the default is as below.

    <h2>Location: 

The variabled passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 locationPart

This is a part of the path in the location bar.

The template used is 'locationPart' and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a> / 

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 locationEnd

This is the end of the location bar.

The template used is 'locationEnd' and the default is as below.

    [== $locationID ==]</h2>
    

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    locationID - The string to use for the end location bar.

=cut

sub locationbar{
	my $self=$_[0];
	my $locationID=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	my @parts=split( /\//, $self->{r2r} );

	#render it
	my $rendered=$self->{t}->fill_in(
		'locationStart',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			self=>\$self,
			c=>\$self->{toader}->getConfig,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#creates the url and cleans it up
	my $url=$self->{b2r};
	$url=~s/\/\/*/\//g;

	#does the initial link to the root directory
	$rendered=$rendered.$self->{t}->fill_in(
		'locationPart',
		{
			url=>$url,
			text=>'root',
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#processes each item
	my $int=0;
	my $dir=$self->{b2r}.'/';
	while ( defined( $parts[$int] ) ){

		if ( $parts[$int] ne '.' ){
			$dir=$dir.$parts[$int].'/';
			$dir=~s/\/\/*/\//g;
			$rendered=$rendered.$self->{t}->fill_in(
				'locationPart',
				{
					url=>$dir,
					text=>$parts[$int],
					toDir=>$self->{toDir},
					toFiles=>$self->{toFiles},
					obj=>\$self->{obj},
					c=>\$self->{toader}->getConfig,
					self=>\$self,
					toader=>\$self->{toader},
					g=>\$self,
				}
				);
			if ( $self->{t}->error ){
				$self->{error}=10;
				$self->{errorString}='Failed to fill in the template. error="'.
					$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
				$self->warn;
				return undef;
			}
		}

		$int++;
	}

	#gets the location ID
	if( ! defined( $locationID ) ){
		$locationID=$self->{obj}->locationID;
	}


	$rendered=$rendered.$self->{t}->fill_in(
		'locationEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			locationID=>$locationID,
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 or2r

This returns the current value to from the root directory
to directory for the object that initialized this instance
of L<Toader::Render::General>.

    my $or2r=$g->or2r;

=cut

sub or2r{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    return $self->{or2r};
}

=head2 pageSummary

This creates a summary of the pages in the current directory.

No arguments are taken.

    $g->pageSummary;

=head3 Templates

=head4 pageSummaryBegin

The begins the summary of the pages.

The template used is 'pageSummaryBegin' and the default is as below.

    <table id="pageSummary">
      <tr> <td>Name</td> <td>Summary</td> </tr>
    

The variabled passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The Toader::Entry object.
    c - The Config::Tiny object containing the Toader config.
    self - The Toader::Render::Entry object.
    toader - This is a Toader object.
    g - This is a Toader::Render::General object.

=head4 pageSummaryJoin

This joins the rows.

The template used is 'pageSummaryJoin' and by default is blank.

The variabled passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=head4 pageSummarySummary

This is a row in the table of pages.

The template used is 'pageSummarySummary' and by default is as below.

      <tr id="pageSummary">
        <td id="pageSummary"><a href="./[== $name ==]/">[== $name ==]</a></td>
        <td id="pageSummary">[== $summary ==]</td>
      </tr>

The variabled passed are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.
    name - This is the name of the page.
    summary - This is a summary of the page.

=cut

sub pageSummary{
	my $self=$_[0];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $pm=Toader::Page::Manage->new();
	$pm->setDir( $self->{odir} );
	if ( $pm->error ){
		$self->{error}=31;
		$self->{errorString}='Failed to set the directory, "'.$self->{odir}.
			'", for Toader::Page::Manage. error="'.$pm->error
			.'" errorString="'.$pm->errorString.'"';
		$self->warn;
		return undef;
	}

	#lists the entries for the directory
	my @pages=$pm->list;
	if ( $pm->error ){
		$self->{error}=32;
		$self->{errorString}='Failed to list the pages for "'.$self->{odir}.
			'". error="'.$pm->error.'" errorString="'.$pm->errorString.'"';
		$self->warn;
		return undef;
	}

	#return '' if there are none
	if ( ! defined( $pages[0] ) ){
		return '';
	}

	#sort and order from last to first
	@pages=sort(@pages);
	@pages=reverse(@pages);

	#process each one
	my @tojoin;
	my $int=0;
	while ( defined( $pages[$int] ) ){
		my $entry=$pm->read( $pages[$int] );
		if ( $pm->error ){
			$self->{error}=33;
			$self->{errorString}='Failed to read "'.$pages[$int].'" in "'
				.$self->{odir}.'". error="'.$pm->error.'" errorstring="'
				.$pm->errorString.'"';
			$self->warn;
			return undef;
		}

		#renders the row
		my $rendered=$self->{t}->fill_in(
			'pageSummaryRow',
			{
				toDir=>$self->{toDir},
				toFiles=>$self->{toFiles},
				obj=>\$self->{obj},
				c=>\$self->{toader}->getConfig,
				toader=>\$self->{toader},
				self=>\$self,
				name=>$entry->nameGet,
				summary=>$entry->summaryGet,
				g=>\$self,
			}
			);
		if ( $self->{t}->error ){
			$self->{error}=10;
			$self->{errorString}='Failed to fill in the template. error="'.
				$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
			$self->warn;
			return undef;
		}		
		
		push( @tojoin, $rendered );

		$int++;
	}

	#renders the joiner
	my $joiner=$self->{t}->fill_in(
		'pageSummaryJoin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $end=$self->{t}->fill_in(
		'pageSummaryEnd',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	#renders the end of the dir list
	my $begin=$self->{t}->fill_in(
		'pageSummaryBegin',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $begin.join( $joiner, @tojoin ).$end;
}

=head2 pageSummaryLink

This is a link to summary of the pages for directory of the object.

On argument is accepted and that is the text to use for the link. If
not specified, it defaults to 'Pages'.

    $g->pageSummaryLink;

The template used is 'pageSummaryLink' and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub pageSummaryLink{
	my $self=$_[0];
	my $text=$_[1];

	if ( ! defined( $text ) ){
		$text='Pages';
	}

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#creates the url and cleans it up
	my $url=$self->{toDir}.'/.pages/summary.html';
	$url=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'pageSummaryLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 plink

This generates a link to a different page object.

Two arguments are taken.

The first and required one is the Toader directory containing
the Toader object.

The second is the page to link to.

The third is the text, which if not specified will will be the
same the link.

    $g->plink( $dir, $page, "whatever at foo.bar" );

The template used is 'linkPage' and it is by default as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables passed are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub plink{
	my $self=$_[0];
	my $dir=$_[1];
	my $page=$_[2];
	my $text=$_[3];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $dir ) ){
		$self->{error}=11;
		$self->{errorString}='No Toader directory defined';
		$self->warn;
		return undef;
	}

	#make sure we have a link
	if ( ! defined( $page ) ){
		$self->{error}=15;
		$self->{errorString}='No Toader page defined';
		$self->warn;
		return undef;
	}

	#set the text to the same as the link if no text is defined
	if ( ! defined( $text ) ){
		$text=$page;
	}

	#handles it if it is a full path
	my $dirtest;
	if ( $dir =~ /^\// ){
		$dir=$self->{toader}->getRootDir.$dir;
		$dirtest=$dir;
		$dir=$self->{ph}->relative2root( $dir );
	}else{
		$dirtest=$self->{dir}.'/'.$dir;
	}

	#make sure it is a Toader directory
	if ( ! $self->{isatd}->isaToaderDir( $dirtest ) ){
		$self->{error}=12;
		$self->{errorString}='"'.$dirtest.'" is not a Toader directory';
		$self->warn;
		return undef;
	}

	#make sure entry exists... will also make sure it exists
	my $ph=Toader::Page::Helper->new;
	$ph->setDir( $dirtest );
	if ( ! $ph->pageExists( $page ) ){
		$self->{error}=16;
		$self->{errorString}='The Toader page "'.$page.'" does not exist for the Toader directory "'.$dirtest.'"';
		$self->warn;
		return undef;
	}

	#add the toDir to it
	$dir=$self->{toDir}.'/'.$dir.'/.pages/'.$page.'/';
	$dir=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'linkPage',
		{
			url=>$dir,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 r2r

This returns the current value to from the root directory
to current directory.

    my $r2r=$g->r2r;

=cut

sub r2r{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

    return $self->{r2r};
}

=head2 rlink

This generates a link to the root directory.

One option arguement is taken. It is the text part of the link.
If not defined it defaults to the relative path to the root
directory.

    $g->rlink("to root");

The template used is 'toRootLink' and is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The variables are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub rlink{
	my $self=$_[0];
	my $text=$_[1];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	if ( ! defined( $text ) ){
		$text='/';
	}

	#creates the url and cleans it up
	my $url=$self->{b2r};
	$url=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'toRootLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 toDir

This returns the value that was set for toDir.

    my $toDir=>$g->toDir;

=cut

sub toDir{
    my $self=$_[0];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	return $self->{toDir};
}

=head2 top

This renders the top include.

    $g->top;

The template is 'top' and the default is as below.

    <h1>[== $c->{_}->{site} ==]</h1><br>

The variables are as below.

    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub top{
	my $self=$_[0];

	#blank any previous errors
	if ( ! $self->errorblank ){
		return undef;
	}

	my $dir=$self->{b2r};

	#add the toDir to it
	$dir=$self->{toDir}.$dir;
	
	#render it
	my $rendered=$self->{t}->fill_in(
		'top',
		{
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			toader=>\$self->{toader},
			self=>\$self,
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head2 upOneDirLink

This creates a link up to the next directory.

One argument is taken and that is text to show for the link. If
not specified, it defaults to 'Up One Directory'.

    $g->upOneDirLink;

The template is 'upOneDirLink' and the default is as below.

    <a href="[== $url ==]">[== $text ==]</a>

The passed variables are as below.

    url - This is the relative URL for this.
    text - This to use for with the link.
    toDir - This is the relative back to the directory.
    toFiles - This is the relative path to the '.files' directory.
    obj - The L<Toader::Entry> object.
    c - The L<Config::Tiny> object containing the Toader config.
    self - The L<Toader::Render::Entry> object.
    toader - This is a L<Toader> object.
    g - This is a L<Toader::Render::General> object.

=cut

sub upOneDirLink{
	my $self=$_[0];
	my $text=$_[1];

    #blank any previous errors
    if ( ! $self->errorblank ){
        return undef;
    }

	if ( ! defined( $text ) ){
		$text='Up One Directory';
	}

	#creates the url and cleans it up
	my $url=$self->{toDir}.'/../';
	$url=~s/\/\/*/\//g;

	#render it
	my $rendered=$self->{t}->fill_in(
		'upOneDirLink',
		{
			url=>$url,
			text=>$text,
			toDir=>$self->{toDir},
			toFiles=>$self->{toFiles},
			obj=>\$self->{obj},
			c=>\$self->{toader}->getConfig,
			self=>\$self,
			toader=>\$self->{toader},
			g=>\$self,
		}
		);
	if ( $self->{t}->error ){
		$self->{error}=10;
		$self->{errorString}='Failed to fill in the template. error="'.
			$self->{t}->error.'" errorString="'.$self->{t}->errorString.'"';
		$self->warn;
		return undef;
	}

	return $rendered;
}

=head1 ERROR CODES

=head2 1

No L<Toader> object defined.

=head2 2

The object specified for the L<Toader> object is not really a L<Toader> object.

=head2 3

The specified L<Toader> object has a permanent error set.

=head2 4

No object specified for the renderable object.

=head2 5

The object specified for the renderable object was not defined.

=head2 6

The specified renderable object has a permanent error set.

=head2 7

The renderable object does not have a directory specified.

=head2 8

Nothing defined for the link.

=head2 9

Failed to fetch the template.

=head2 11

No Toader directory specified.

=head2 12

The specified directory is not a L<Toader> directory.

=head2 13

No L<Toader::Entry> ID defined.

=head2 14

The entry does not exist.

=head2 15

No L<Toader> page is defined.

=head2 16

The page does not exist.

=head2 17

No file specified.

=head2 18

Failed to initialize the L<Toader::Templates> object.

=head2 19

Failed to figure out the relative from root path.

=head2 20

Failed to figure out the relative to root path.

=head2 21

Failed to initialize the L<Toader::pathHelper> object.

=head2 22

Failed to get a list of L<Toader> sub direcotires for the
current directory.

=head2 23

Failed to set the directory for L<Toader::Page::Manage>.

=head2 24

Failed to get a list of pages.

=head2 25

L<Toader::Entry::Manage> could not have it's directory set.

=head2 26

Failed to read a entry.

=head2 27

Failed to initialize L<Toader::Render::Entry>.

=head2 28

Failed to render a entry.

=head2 29

No authors line specified.

=head2 30

Failed to parse the authors line.

=head2 31

L<Toader::Entry::Manage> could not have it's directory set.

=head2 32

Failed to list the pages for the directory.

=head2 33

Failed to read the page.

=head2 34

The file specified for the AutoDoc link starts with a "../".

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Render::General

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

Copyright 2011. Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader::Render::General
