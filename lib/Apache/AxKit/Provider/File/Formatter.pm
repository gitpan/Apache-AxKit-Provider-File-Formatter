package Apache::AxKit::Provider::File::Formatter;

#use 5.008004;
use strict;
use warnings;
use Apache::AxKit::Provider::File;
use Apache::AxKit::Exception;

our @ISA = qw(Apache::AxKit::Provider::File);



our $VERSION = '0.93';



=head1 NAME

Apache::AxKit::Provider::File::Formatter - An AxKit Provider that can
use any Formatter API module

=head1 SYNOPSIS

In your Apache config, you can configure this Provider like this example:

  <LocationMatch .textile$>
        PerlHandler AxKit
        AxContentProvider Apache::AxKit::Provider::File::Formatter
	PerlSetVar FormatterModule Formatter::HTML::Textile
  </LocationMatch>

=head1 DESCRIPTION

This is an AxKit Provider that may be used to apply any module that
conforms with the Formatter API (v0.93) to a file. At the time of this
writing, there are two modules in the C<Formatter::> namespace, one
for formatting the L<Text::Textile> syntax, and one to add minimal
HTML markup to a preformatted plain text.

The Provider can be configured like any other Provider, to apply to a
directory, a file ending, etc. The only thing that is special about it
is that it needs a C<FormatterModule> variable to tell it which module
will do the actual formatting. It can be set like in the example in
the SYNOPSIS.

Make sure you have the module you specify installed, otherwise an
error will result.

=cut

sub get_strref {
  my $self = shift;
  my $r = $self->apache_request();
 
  # Let the superclass A:A:P:File handle the request if
  # this is a directory. Nacho++
  if ($self->_is_dir()) {
    return $self->SUPER::get_strref();
  }
  
  # From SUPER:
  my $fh = $self->SUPER::get_fh();
  local $/;
  my $contents = <$fh>;
  
  my $whichformatter = $r->dir_config('FormatterModule');
  unless ($whichformatter =~ m/^Formatter::\w+::\w+$/) {
    throw Apache::AxKit::Exception::Error( -text => "$whichformatter doesn't look like a formatter to me");
  }
  eval "use $whichformatter";
  throw Apache::AxKit::Exception::Error( -text => $whichformatter . " not found, you may need to install it from CPAN") if $@;
  my $formatter = "$whichformatter"->format($contents);
  my $result = $formatter->document;
  return \$result;
}


# We shouldn't output a filehandle, so throw the necessary exception
sub get_fh {
   throw Apache::AxKit::Exception::IO( -text => "Can't get fh for Formatter" );
}


=head1 SEE ALSO

The L<Formatter> API specification.

The currently existing Formatters: L<Formatter::HTML::Preformatted>,
L<Formatter::HTML::Textile>. Some other Providers may also be of
interest: L<Apache::AxKit::Provider::File>,
L<Apache::AxKit::Provider::File::Syntax>

=head1 TODO

It should, in principle, be possible to use a chain of Formatter
modules to process a file in stages. This could be an interesting
exercise for the future, but then there are also many other pipeline
based paradigms that me be better suited.

=head1 AUTHOR

Kjetil Kjernsmo, E<lt>kjetilk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kjetil Kjernsmo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
__END__
