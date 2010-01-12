use strict;
use warnings;
use utf8;

package Jifty::Plugin::Media;
use base qw/Jifty::Plugin Class::Accessor::Fast/;

=head1 NAME

Jifty::Plugin::Media - Provides upload file and select url for Jifty

=head1 DESCRIPTION

Jifty::Plugin::Media is a Jifty plugin to allow file upload and select url for
any media file for your application.

=head1 SYNOPSIS

In your model class schema description, add the following:

   column color1 => is Media;

In your jifty config.yml under the framework section:

   Plugins:
       - Media:
          default_root: files

<<default_root>> will be added to Your_app_root/share/web/static/ path 
Your process need to have write rights in this directory.

In your Dispatcher manage allowed uploaders :

  use strict;
  use warnings;
  package TestApp::Dispatcher;
  use Jifty::Dispatcher -base;
  before '*' => run {
    Jifty->api->allow('Jifty::Plugin::Media::Action::ManageFile')
        if Jifty->web-current_user->is_supersuser;
    };
  1;

=cut

__PACKAGE__->mk_accessors(qw(real_root default_root));

use File::Path;
use File::Basename;
use Text::Unaccent;

=head2 init

load config values, javascript and css

=cut

sub init {
   my $self = shift;
   my %opt  = @_;

    my $default_root = $opt{default_root} || 'files';
   $self->default_root( $default_root );
    my $root = Jifty::Util->app_root().'/share/web/static/'.$default_root.'/file';
    my $dir = File::Basename::dirname($root);

    if ( ! -d $dir) {
        eval { File::Path::mkpath($dir, 0, 0775); };
        die if $@;
    };
   $self->real_root( $dir );

   Jifty->web->add_javascript(qw( jqueryFileTree.js ) );
   Jifty->web->add_css('jqueryFileTree.css');
};


use Jifty::DBI::Schema;

sub _media {
            my ($column, $from) = @_;
            my $name = $column->name;
            $column->type('text');
}

Jifty::DBI::Schema->register_types(
    Media =>
      sub { _init_handler is \&_media, render_as 'Jifty::Plugin::Media::Widget' },
);

=head2 read_dir

=cut

sub read_dir {
    my $self = shift;
    my $dir = shift;

    # don't allow relative path
    $dir =~ s/\.\.//g;
    # don't allow cached path
    $dir =~ s/^\.//g;

    my ($plugin) = Jifty->find_plugin($self);

    my $root = $plugin->real_root();
    my $fullDir = $root . $dir;

    return if ! -e $fullDir;

    opendir(BIN, $fullDir) or die "Can't open $dir: $!";
    my (@folders, @files);
    my $total = 0;
    while( defined (my $file = readdir BIN) ) {
        next if $file eq '.' or $file eq '..';
        $total++;
        if (-d "$fullDir/$file") {
        push (@folders, $file);
        } else {
        push (@files, $file);
        }
    };
    closedir(BIN);

    return ({ Folders => \@folders, Files => \@files });
};

=head2 conv2ascii

 convert accent character to ascii

=cut

sub conv2ascii {
 my ($self,$string) = @_;
 my $res = unac_string('utf8',$string); # if( !$res);
 return $res;
};


=head2 clean_dir_name

convert dir name in ascii

=cut

sub clean_dir_name {
    my $self = shift;
    my $string = shift;
    $string=~s/[ '"\.\/\\()%&~{}|`,;:!*\$]/-/g;
    $string=~s/--/-/g;
    $string=~s/#/Sharp/g;
    $string=$self->conv2ascii($string);
    return $string;
};

=head2 clean_file_name

convert file name in ascii

=cut


sub clean_file_name {
    my $self = shift;
    my $name = shift;
    my ($string,$ext) = $name =~m/^(.*?)\.(\w+)$/;
    $string=$self->clean_dir_name($string);
    return $string.'.'.$ext;
};


=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2010, Yves Agostini.

This program is free software and may be modified and distributed under the same terms as Perl itself.

Embeded 

=cut

1;
