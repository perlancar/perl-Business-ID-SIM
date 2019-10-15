package Business::ID::SIM;

# DATE
# VERSION

use 5.010001;
use warnings;
use strict;

use DateTime;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_sim);

# legend: S = lack of samples

# less organized than the convoluted code in NIK

my %provinces = (
    '06' => "Nanggroe Aceh Darussalam",
    '07' => "Sumatera Utara",
    '08' => "Sumatera Barat",
    '09' => "Riau, Kepulauan Riau",
    '10' => undef, # S
    '11' => "Sumatera Selatan",
    '12' => "DKI Jakarta", # most frequently encountered
    '13' => "Jawa Barat",
    '14' => "Jawa Tengah, DI Yogyakarta",
    '15' => "Jawa Timur",
    '16' => "Bali",
    '17' => "Kalimantan Timur",
    '18' => "Kalimantan Selatan",
    '19' => "Sulawesi Selatan",
    '20' => "Sulawesi Utara, Gorontalo",
    '21' => undef, # S
    '22' => 'Papua',
    '23' => 'Kalimantan Tengah',
    '24' => 'Sulawesi Tengah',
    '25' => 'Lampung',
    #'30' => "Banten", # ?, SS

    );

our %SPEC;

$SPEC{parse_sim} = {
    v => 1.1,
    summary => 'Validate Indonesian driving license number (nomor SIM)',
    args => {
        sim => {
            summary => 'Input to be parsed',
            schema => 'str*',
            pos => 0,
            req => 1,
        },
    },
};
sub parse_sim {
    my %args = @_;

    my $sim = $args{sim} or return [400, "Please specify sim"];
    my $res = {};

    $sim =~ s/\D+//g;
    return [400, "Not 12 digit"] unless length($sim) == 12;

    $res->{prov_code} = substr($sim, 4, 2);
    return [400, "Unknown province code"] unless $provinces{$res->{prov_code}};
    $res->{area_code} = substr($sim, 4, 4);

    my ($y, $m) = $sim =~ /^(..)(..)/;
    my $today = DateTime->today;
    $y += int($today->year / 100) * 100;
    $y -= 100 if $y > $today->year;
    eval { $res->{dob} = DateTime->new(day=>1, month=>$m, year=>$y) };
    return [400, "Invalid year and month of birth: $y, $m"] if $@;
    $res->{serial} = $sim =~ /(....)$/;
    return [400, "Serial starts from 1, not 0"] if $res->{serial} < 1;

    [200, "OK", $res];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use Business::ID::SIM qw(parse_sim);

 my $res = parse_sim(sim => "0113 40 00 0001");


=head1 DESCRIPTION

This module can be used to validate Indonesian driving license number, Nomor
Surat Izin Mengemudi (SIM).

SIM is composed of 12 digits as follow:

 yymm.pp.aa.ssss

yy and mm are year and month of birth, pp and aa are area code
(province+district of some sort), ssss is 4-digit serial most probably starting
from 1.

Note that there are several kinds of SIM (A, B1, B2, C) but this is not encoded
in the SIM number and all SIM's have the same number.

=cut
