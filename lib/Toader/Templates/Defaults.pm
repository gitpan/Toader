package Toader::Templates::Defaults;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

Toader::Templates::Defaults - This provides the default templates for Toader.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

    use Toader::Templates::Defaults;

    #initiates the object
    my $foo = Toader::Templates::Defaults->new;
    
    #fetches the css template
    my $template=$foo->getPage('css');
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=head1 METHODS

=head2 new

This initiates the object.

This method does not error.

    my $foo=Toader::Template::Defaults->new;

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self={
		error=>undef,
		errorString=>'',
		templates=>{},
	};
	bless $self;

	$self->{templates}{'link'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'linkDirectory'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'linkEntry'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'linkPage'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'linkFile'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'linkDirectoryFile'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'linkEntryFile'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'linkPageFile'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'entriesLink'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'entriesArchiveLink'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'upOneDirLink'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'dirListLink'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'pageListLink'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'authorLink'}='<a href="mailto:[== $address ==]">[== $name ==]</a>';
	$self->{templates}{'pageSummaryLink'}='<a href="[== $url ==]">[== $text ==]</a>';
	$self->{templates}{'toRootLink'}='<a href="[== $url ==]">[== $text ==]</a>';

	$self->{templates}{'dirListEnd'}='';
	$self->{templates}{'dirListJoin'}='<br>'."\n";
	$self->{templates}{'dirListEnd'}='<br>'."\n";

	$self->{templates}{'pageListBegin'}='';
	$self->{templates}{'pageListJoin'}='<br>'."\n";
	$self->{templates}{'pageListEnd'}='<br>'."\n";

	$self->{templates}{'entryListBegin'}='';
	$self->{templates}{'entryListJoin'}='<br>'."\n";
	$self->{templates}{'entryListEnd'}='<br>'."\n";

	$self->{templates}{'authorEnd'}='';
	$self->{templates}{'authorJoin'}=", \n";
	$self->{templates}{'authorEnd'}="\n";

	$self->{templates}{'css'}='div{
  border: 0px solid;
  padding:2px;
  width: 100%;
 }
div#sidebar{
  width: auto;
  float:left;
  border: 1px solid;
 }
div#maincontent{
  width: auto;
  float:left;
 }
div#location{
  width: 100%;
  border: 1px solid;
 }
div#header{
  width: 100%;
  border: 1px solid;
 }
div#content{
  width: 100%;
  border: 1px solid;
 }
div#copyright{
  width: auto;
  text-align: center;
 clear: left;
}
body{
  background: black;
  color: white;
 }
a:link{
  color: grey;
 }
a:visited{
  color: lightgreen;
 }
a:hover{
  color: green;
 }
table#entryArchive{
  border: 1px solid;
 }
td#entryArchive{
  border: 1px solid;
 }
table#pageSummary{
  border: 1px solid;
 }
td#pageSummary{
  border: 1px solid;
 }
';

	$self->{templates}{'page'}='<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>

  <head>
	<title> [== $c->{_}->{siteTitle} ==] </title>
    <LINK href="[== $g->cssLocation ==]" rel="stylesheet" type="text/css">
  </head>

  <body>

	<div id="header" >
	  [== $g->top ==]
	</div>

	<div id="location" >
	  [== $g->locationbar( $locationID ) ==]
	</div>

	<div>

	  <div id="sidebar" >
		[==
		  if ( ! $g->hasEntries ){
		    return "";
		  }
	      return "		<h3>Entries</h3>\n".
		  "		".$g->entriesLink." <br>\n".
		  "		".$g->entriesArchiveLink." <br>\n".
		  "		<hr>\n";
		==]
		[==
		  my $pages=$g->listPages;
		  if ( ( ! defined( $pages ) ) || ( $pages eq "" ) ){
		    return "";
		  }
		  return "		<h3>".$g->pageSummaryLink."</h3>\n".$pages."\n		<hr>\n";
		==]
		<h3>Directories</h3>
		[== 
			if ( $g->atRoot ){
				return "";
			}
			return $g->rlink("Go To The Root")."		<br>\n		";
			       $g->upOneDirLink."		<br>\n		<br>";
		==]

		[== $g->listDirs ==]
	  </div>

	  <div id="maincontent" >
		[== $content ==]
	  </div>

	</div>
	
	<br><br><br>
	
	<div id="copyright">
	  [==
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
        $year=$year+1900;
        return "Copyright ".$year." ".$c->{_}->{owner};
      ==]
	</div>

  </body>
</html>

';

	$self->{templates}{'dirContent'}='[== $body ==]';


	$self->{templates}{'pageContent'}='[== $body ==]';

	$self->{templates}{'entryContent'}='<div id="content">
  <h4>[== $g->elink( $g->or2r, $date, $title ) ==]</h4>
  Date: [== $year.$month.$day."-".$hour.":".$min ==] <br>
  Author: [== $g->authorsLink( $from ) ==]<br>
  <div id="content">
    [== $body ==]
  </div>
</div>
';

	$self->{templates}{'entryIndex'}='[== $g->lastEntries( $c->{_}->{last} ) ==]';

	$self->{templates}{'entryArchive'}='[== $g->entryArchive ==]';

	$self->{templates}{'entryArchiveBegin'}='<table id="entryArchive">
  <tr> <td>Date</td> <td>Title</td> <td>Summary</td> </tr>
';
	$self->{templates}{'entryArchiveRow'}='  <tr id="entryArchive">
    <td id="entryArchive">[== $g->elink( "./", $date, $date ) ==]</td>
    <td id="entryArchive">[== $title ==]</td>
    <td id="entryArchive">[== $summary ==]</td>
  </tr>
';
	$self->{templates}{'entryArchiveJoin'}='';
	$self->{templates}{'entryArchiveEnd'}='</table>';

	$self->{templates}{'pageSummary'}='[== $g->pageSummary ==]';

	$self->{templates}{'pageSummaryBegin'}='<table id="pageSummary">
  <tr> <td>Name</td> <td>Summary</td> </tr>
';
	$self->{templates}{'pageSummaryRow'}='  <tr id="pageSummary">
    <td id="pageSummary"><a href="./[== $name ==]/">[== $name ==]</a></td>
    <td id="pageSummary">[== $summary ==]</td>
  </tr>
';
	$self->{templates}{'pageSummaryJoin'}='';
	$self->{templates}{'pageSummaryEnd'}='</table>';

	$self->{templates}{'locationStart'}='<h2>Location: ';
	$self->{templates}{'locationPart'}='<a href="[== $url ==]">[== $text ==]</a> / ';
	$self->{templates}{'locationEnd'}='[== $locationID ==]</h2>
';

	$self->{templates}{'top'}='<h1>[== $c->{_}->{site} ==]</h1><br>';

	return $self;
}

=head2 getTemplate

This returns a default template.

One argument is required and it is the template name.

There is no need to do error checking, if one is certian
the template exists.

    my $template=$foo->getTemplate( $name );
    if ( $foo->error ){
        warn( 'Error:'.$foo->error.': '.$foo->errorString );
    }

=cut

sub getTemplate{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ){
		$self->{error}=1;
		$self->{errorString}='No template specified';
		$self->warn;
		return undef;
	}

	if ( ! defined( $self->{templates}{$name}  ) ){
		$self->{error}=2;
		$self->{errorString}='"'.$name.'" is not a default template';
		$self->warn;
		return undef;
	}

	return $self->{templates}{$name};
}

=head1 ERROR CODES

=head2 1

No template name specified.

=head2 2

No such template.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::Templates::Defaults


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