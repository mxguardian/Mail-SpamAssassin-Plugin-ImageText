package Mail::SpamAssassin::Plugin::ImageText;
use strict;
use warnings FATAL => 'all';

use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::Logger qw(would_log);
use Mail::SpamAssassin::Util qw(compile_regexp &untaint_var);

our @ISA = qw(Mail::SpamAssassin::Plugin);
our $VERSION = 0.01;

=head1 NAME

Mail::SpamAssassin::Plugin::ImageText - SpamAssassin plugin to match text in images

=head1 SYNOPSIS

  loadplugin Mail::SpamAssassin::Plugin::ImageText

  imagetext RULE_NAME /pattern/modifiers

=head1 DESCRIPTION

This plugin allows you to write rules that match text in images. The text must be extracted
from the image by another plugin, such as L<Mail::SpamAssassin::Plugin::ExtractText>

=cut

sub dbg { Mail::SpamAssassin::Logger::dbg ("ImageText: @_"); }
sub info { Mail::SpamAssassin::Logger::info ("ImageText: @_"); }

sub new {
    my $class = shift;
    my $mailsa = shift;

    $class = ref($class) || $class;
    my $self = $class->SUPER::new($mailsa);
    bless($self, $class);

    $self->set_config($mailsa->{conf});

    return $self;
}

sub set_config {
    my ($self, $conf) = @_;
    my @cmds;

    push (@cmds, (
        {
            setting => 'imagetext',
            is_priv => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
            code => sub {
                my ($self, $key, $value, $line) = @_;

                if ($value !~ /^(\S+)\s+(.+)$/) {
                    return $Mail::SpamAssassin::Conf::INVALID_VALUE;
                }
                my $name = $1;
                my $pattern = $2;

                my ($re, $err) = compile_regexp($pattern, 1);
                if (!$re) {
                    dbg("Error parsing rule: invalid regexp '$pattern': $err");
                    return $Mail::SpamAssassin::Conf::INVALID_VALUE;
                }

                $conf->{parser}->{conf}->{imagetext_rules}->{$name} = $re;

                # just define the test so that scores and lint works
                $self->{parser}->add_test($name, undef,
                    $Mail::SpamAssassin::Conf::TYPE_EMPTY_TESTS);


            }
        }
    ));

    $conf->{parser}->register_commands(\@cmds);
}

sub finish_parsing_end {
    my ($self, $opts) = @_;
    my $conf = $opts->{conf};

    # prevent warnings about redefining subs
    undef &_run_imagetext_rules;

    # only compile rules if we have any
    return unless exists $conf->{imagetext_rules};

    # check if we should include calls to dbg()
    my $would_log = would_log('dbg');

    # build eval string
    my $eval = <<'EOF';
package Mail::SpamAssassin::Plugin::ImageText;

sub _run_imagetext_rules {
    my ($self, $opts) = @_;
    my $pms = $opts->{permsgstatus};
    my ($test_qr,$hits);

    # get image text
    my $image_text = $self->_get_image_text($pms);

    # check all script rules
EOF
    my $loopid = 0;
    foreach my $name (keys %{$conf->{imagetext_rules}}) {
        $loopid++;
        my $test_qr = $conf->{imagetext_rules}->{$name};
        my $tflags = $conf->{tflags}->{$name} || '';
        my $score = $conf->{scores}->{$name} || 1;

        my $dbg_running_rule = '';
        my $dbg_ran_rule = '';
        if ( $would_log ) {
            $dbg_running_rule = qq(dbg("running rule $name"););
            $dbg_ran_rule = qq(dbg(qq(ran rule $name ======> got hit "\$match")););
        }

        my $ifwhile = 'if';
        my $last = 'last;';
        my $modifiers = 'p';
        my $init_hits = '';

        if ( $tflags =~ /\bmultiple\b/ ) {
            $ifwhile = 'while';
            $modifiers .= 'g';
            if ($tflags =~ /\bmaxhits=(\d+)\b/) {
                $init_hits = "\$hits = 0;";
                $last = "last rule_$loopid if ++\$hits >= $1;";
            } else {
                $last = '';
            }
        }

        $eval .= <<"EOF";
    $dbg_running_rule
    \$test_qr = \$pms->{conf}->{imagetext_rules}->{$name};
    $init_hits
    rule_$loopid: foreach my \$line (\@\$image_text) {
        $ifwhile ( \$line =~ /\$test_qr/$modifiers ) {
            my \$match = defined \${^MATCH} ? \${^MATCH} : '<negative match>';
            $dbg_ran_rule
            \$pms->{pattern_hits}->{$name} = \$match;
            \$pms->got_hit('$name','ImageText: ','ruletype' => 'body', 'score' => $score);
            $last
        }
    }
EOF

    }
    $eval .= <<'EOF';
}

EOF

    # print "$eval\n";
    # compile the new rules
    eval untaint_var($eval);
    if ($@) {
        die("ImageText: Error compiling rules: $@");
    }

}

sub parsed_metadata {
    my ($self, $opts) = @_;

    $self->_run_imagetext_rules($opts) if $self->can('_run_imagetext_rules');

}

sub _get_image_text {
    my ($self, $pms) = @_;

    if (exists $pms->{image_text}) {
        return $pms->{image_text};
    }

    my @image_text = ();
    #@type Mail::SpamAssassin::Message
    my $msg = $pms->{msg};
    #@type Mail::SpamAssassin::Message::Node
    my $p;

    foreach $p ($msg->find_parts(qr/./, 1)) {
        # my $ct = $p->get_header('content-type', 0);
        my $ct = $p->effective_type();
        if ($ct =~ m@^image/@i) {
            my $text = $p->rendered();
            next unless defined($text);
            # $text =~ s/\s+/ /g;
            # $text =~ s/^\s+//;
            # $text =~ s/\s+$//;
            push @image_text, $text;
        }
    }

    $pms->{image_text} = \@image_text;

}

1;