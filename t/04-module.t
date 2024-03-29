
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp::Foo::Bar::Baz;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Context;

    sub conf_driver {
        my $self = shift;
        return $self->param('conf_driver');
    }

    sub setup {
        my $self = shift;

        $self->header_type('none');
        $self->run_modes(
            'start' => 'default',
        );

        $ENV{'SCRIPT_NAME'} = '/apps/red/users';
        $ENV{'PATH_INFO'}   = '/some/long/path/one';

        my $conf_driver = $self->conf_driver;
        $self->conf->init(
            file   => "t/conf-$conf_driver/04-module.conf",
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );
    }

    sub default {
        my $self = shift;
        my $config = $self->conf->context;

        ok(!$config->{'is_plain_foo'},    $self->conf_driver . ': is_plain_foo');
        is($config->{'is_webapp_foo'}, 1, $self->conf_driver . ': is_webapp_foo');
        ok(!$config->{'is_webapp_fo'},    $self->conf_driver . ': is_webapp_fo');
        is($config->{'has_webapp_fo'}, 1, $self->conf_driver . ': has_webapp_fo');
        is($config->{'has_baz'},       1, $self->conf_driver . ': has_baz');
        ok(!$config->{'ends_with_bar'},   $self->conf_driver . ': ends_with_bar');
        is($config->{'some_location'}, 1, $self->conf_driver . ': some_location');
        ok(!$config->{'long_location'},   $self->conf_driver . ': long_location');

        return "";
    }
}


SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'ConfigGeneral' })->run;
    }
    else {
        skip "Config::General not installed", 8;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'ConfigScoped'  })->run;
    }
    else {
        skip "Config::Scoped not installed", 8;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'XMLSimple'     })->run;
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", 8;
    }
}


sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}

