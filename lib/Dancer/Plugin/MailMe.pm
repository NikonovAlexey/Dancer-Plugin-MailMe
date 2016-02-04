package Dancer::Plugin::MailMe;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Common;

use Net::SMTP::SSL;

use Data::Dump qw(dump);
use FindBin qw($Bin);
use Try::Tiny;
use POSIX 'strftime';

use Digest::MD5 qw( md5_hex );
use MIME::Base64 qw( encode_base64 );
use Encode qw( encode );

my $smtp;


sub send {
    my ( $recipient, $subject, $template, $template_data ) = @_;
    my $doup = config->{plugins}->{Email}->{techdir};
    my $message = template_process($template, $template_data);
    $recipient = config->{plugins}->{MailMe}->{alias}->{$recipient} ? config->{plugins}->{MailMe}->{alias}->{$recipient} : $recipient;
};


=head2 recode

Переводит указанное сообщение в формат Base64:UTF-8 и удаляет завершающий перенос строки

=cut

sub recode {
    my $str = shift;
    
    $str = encode_base64(encode('utf-8', $str));
    $str =~ s/\n//g;

    return $str;
}


=head2 mail_connect

Подключиться к серверу.

=cut

sub mail_connect {
    my $config = config->{plugins}->{MailMe};
    $smtp = Net::SMTP::SSL->new(
            Host => $config->{host} || 'smtp.yandex.ru',
            Port => $config->{port} || 465,
            Debug => $config->{debug} || 0,
        );
    $smtp->auth($config->{username}, $config->{password});
};


=head2 mail_disconnect

Завершить почтовую сессию

=cut

sub mail_disconnect {
    $smtp->quit;
}


=head2 mail_send

Отправляет письмо указанному получателю. На входе указать получателя, тему,
и тело письма.

=cut

sub mail_send {
    my ( $to, $subject, $body ) = @_;
    
    $subject    = recode($subject);
    $body       = recode($body);
    
    my $boundary = localtime;
    
    $smtp->mail('mail@simple-ip.ru');
    $smtp->recipient("$to\n");
    $smtp->data();
    $smtp->datasend("From: mail\@simple-ip.ru\n");
    $smtp->datasend("To: $to\n");
    $smtp->datasend("Subject: =?UTF-8?B?$subject?=\n");
    $smtp->datasend("Content-Type: multipart/mixed; boundary=\"$boundary\"\n");
    $smtp->datasend("\n");
    $smtp->datasend("--$boundary\n");
    $smtp->datasend("Content-Type: text/html; charset=\"UTF-8\"\n");
    $smtp->datasend("Content-Transfer-Encoding: base64\n");
    $smtp->datasend("\n");
    $smtp->datasend("$body");
    $smtp->dataend();
}

=head2 mail_template

Надстройка над mail_send, позволяющая автоматически обрабатывать шаблоны почтовых сообщений.
На входе передайте получателя, тему, название файла шаблона и список параметров для шаблона.
Шаблон будет распарсен, на его основе сгенерировано тело сообщения и отправлено по
указанному адресу назначения.

=cut

sub mail_template {
    my ( $to, $subject, $template, $params ) = @_;

    my $message_body = template_process($template, $params);
    mail_send($to, $subject, $message_body);
}


register mail_connect   => \&mail_connect;
register mail_send      => \&mail_send;
register mail_template  => \&mail_template;
register mail_disconnect=> \&mail_disconnect;

register_plugin;

1;
