# -*- cperl -*-

use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	      NAME	   => 'POE::Filter::Asterisk::Manager',
	      VERSION_FROM => 'Manager.pm',
	      PREREQ_PM    => {
			       POE => 0.12_03,
			      },
	     );
