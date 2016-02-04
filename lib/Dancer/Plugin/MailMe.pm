package Dancer::Plugin::MailMe;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Common;
use Dancer::Plugin::DBIC;

use Net::SMTP::SSL;

use Data::Dump qw(dump);
use FindBin qw($Bin);
use Try::Tiny;
use POSIX 'strftime';

sub send {
    my ( $recipient, $subject, $template, $template_data ) = @_;
    my $doup = config->{plugins}->{Email}->{techdir};
    my $message = template_process($template, $template_data);
    $recipient = config->{plugins}->{MailMe}->{alias}->{$recipient} ? config->{plugins}->{MailMe}->{alias}->{$recipient} : $recipient;
    
};

my $smtp;

sub mail_connect {
    $smtp = Net::SMTP::SSL->new(
            Host => 'smtp.yandex.ru',
            Port => 465,
            Debug => 1,
        );
    #say $smtp->banner;
    $smtp->auth('mail@simple-ip.ru', 'RQ2yyrzPxmPF');
    $smtp->mail('mail@simple-ip.ru');
};

=head2 send

Отправляет письмо указанному получателю. На входе указать получателя, тему,
шаблон для обработки и данные для шаблона.

=cut

sub mail_me {
    my ( $to, $subject, $body ) = @_;
    
    $smtp->recipient("$to\n");
    $smtp->data();
    $smtp->datasend("From: mail\@simple-ip.ru\n");
    $smtp->datasend("To: $to\n");
    $smtp->datasend("Subject: $subject\n");
    $smtp->datasend("\n");
    $smtp->datasend("$body");
    $smtp->dataend();
}

sub mail_disconnect {
    $smtp->quit;
}

mail_connect();
mail_me('galadhon@yandex.ru', 'new message', 'Azazazaza! new test message sended!');
mail_disconnect();

register send   => \&send;

register_plugin;

1;
