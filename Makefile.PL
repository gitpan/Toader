use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Toader',
	AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM        => 'lib/Toader.pm',
	ABSTRACT_FROM       => 'lib/Toader.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
	 ? ('LICENSE'=> 'perl')
	 : ()),
	PL_FILES            => {},
	INST_SCRIPT => 'bin',
	PREREQ_PM => {
		'Test::More'=>0,
		'Cwd'=>0,
		'Config::Tiny'=>0,
		'Email::MIME'=>0,
		'File::MimeInfo'=>0,
		'Error::Helper'=>0,
		'Module::List'=>0,
		'Text::Template'=>0,
		'Getopt::Std'=>0,
		'Term::CallEditor'=>0,
		'Sys::Hostname'=>0,
		'File::Path'=>0,
		'File::Spec'=>0,
		'Time::HiRes'=>0,
		'Date::Parse'=>0,
		'Email::Address'=>0,
		'Time::HiRes'=>0,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Toader-*' },
	);
