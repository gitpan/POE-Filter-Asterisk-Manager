package POE::Filter::Asterisk::Manager;

use strict;

our $VERSION = '0.01';

sub DEBUG { 0 };

#------------------------------------------------------------------------------

sub new {
	my $type = shift;
	my $self = {
		buffer => '',
		crlf => "\x0D\x0A",
	};
	bless $self, $type;
	$self;
}

#------------------------------------------------------------------------------

sub get {
	my ($self, $stream) = @_;

	# Accumulate data in a framing buffer.
	$self->{buffer} .= join('', @$stream);

	my $many = [];
	while (1) {
		my $input = $self->get_one([]);
		if ($input) {
			push(@$many,@$input);
		} else {
			last;
		}
	}

	return $many;
}

sub get_one_start {
	my ($self, $stream) = @_;

	DEBUG && do {
		my $temp = join '', @$stream;
		$temp = unpack 'H*', $temp;
		warn "got some raw data: $temp\n";
	};

	# Accumulate data in a framing buffer.
	$self->{buffer} .= join('', @$stream);
}

sub get_one {
	my $self = shift;

	return [] if ($self->{finish});


	if ($self->{buffer} =~ s#^Asterisk Call Manager/(\d+\.\d+)$self->{crlf}##is) {
		return [{ acm_version => $1 }];
	}

	return [] unless ($self->{crlf});
	my $crlf = $self->{crlf};

	# collect lines in buffer until we find a double line
	return [] unless($self->{buffer} =~ m/${crlf}${crlf}/s);


	$self->{buffer} =~ s/(^.*?)(${crlf}${crlf})//s;

	my $buf = "$1${crlf}";
	
	my $kv = {};

	foreach my $line (split(/(:?${crlf})/,$buf)) {
		my $tmp = $line;
		$tmp =~ s/\r|\n//g;
		next unless($tmp);
		if ($line =~ m/([\w\-]+)\s*:\s*(.*)/) {
			$kv->{$1} = $2;
			DEBUG && print "recv key $1: $2\n";
		} else {
			$kv->{content} .= "$line";
		}
	}

	return (keys %$kv) ? [$kv] : [];
}

#------------------------------------------------------------------------------

sub put {
	my ($self, $hrefs) = @_;
	my @raw;
	for my $i ( 0 .. $#{$hrefs} ) {
		if (ref($hrefs->[$i]) eq 'HASH') {
			foreach my $k (keys %{$hrefs->[$i]}) {
				DEBUG && print "send key $k: $hrefs->[$i]{$k}\n";
				push(@raw,"$k: $hrefs->[$i]{$k}$self->{crlf}");
			}
		} elsif (ref($hrefs->[$i]) eq 'ARRAY') {
			push(@raw, join("$self->{crlf}", @$hrefs->[$i], ""));
		} elsif (ref($hrefs->[$i]) eq 'SCALAR') {
			push(@raw, $hrefs->[$i]);
		} else {
			print STDERR "unknown type ".ref($hrefs->[$i])." passed to ".__PACKAGE__."->put()";
		}
		push(@raw,"$self->{crlf}");
	}
	\@raw;
}

#------------------------------------------------------------------------------

sub get_pending {
	my $self = shift;
	return [ $self->{buffer} ] if length $self->{buffer};
	return undef;
}

###############################################################################
1;

__END__

=head1 NAME

POE::Filter::Asterisk::Manager - convert stream to hashref, and hashref to stream

=head1 SYNOPSIS

  $httpd = POE::Filter::Asterisk::Manager->new();
  $arrayref_with_http_response_as_string =
    $httpd->put($full_http_response_object);
  $arrayref_with_http_request_object =
    $line->get($arrayref_of_raw_data_chunks_from_driver);

=head1 DESCRIPTION

POE::Filter::Asterisk::Manager is a filter used to pass back a reference
to a hash with the keys/values of data received from Asterisk manager.
It also works the other way around.

=head1 PUBLIC FILTER METHODS

Please see POE::Filter.

=head1 SEE ALSO

POE::Filter.

The SEE ALSO section in L<POE> contains a table of contents covering
the entire POE distribution.

=head1 TODO

=item *

Add crlf detection.  I'm not sure if this is really needed though
since Asterisk has only been used on linux.

=head1 BUGS

Probably

=head1 AUTHORS & COPYRIGHTS

David Davis. (xantus [at] teknikill.net) (xantus on irc.perl.org)

Please see L<POE> for more information about authors and contributors.

=cut
