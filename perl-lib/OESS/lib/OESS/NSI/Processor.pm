#!/usr/bin/perl

package OESS::NSI::Processor;
$ENV{CRYPT_SSLEAY_CIPHER} = 'ALL';
use strict;
use warnings;

use Net::DBus::Exporter qw(org.nddi.nsi);
use Net::DBus qw(:typing);
use Net::DBus::Annotation qw(:call);
use base qw(Net::DBus::Object);

use GRNOC::Log;
use GRNOC::WebService::Client;

use OESS::NSI::Constant;
use OESS::NSI::Reservation;
use OESS::NSI::Provisioning;
use OESS::NSI::Query;
use Data::Dumper;

sub new {
    my $class = shift;
    my $service = shift;
    my $config_file = shift;
    
    my $self = $class->SUPER::new($service, '/controller1');
    bless($self,$class);

    $self->{'config_file'} = $config_file;
    $self->{'watched_circuits'} = [];
    $self->_init();

    #-- dbus methods
    dbus_method("process_request", ["string", ["dict", "string", ["variant"]]], ["int32"]);

    return $self;
}

sub circuit_provision{
    my ($self, $circuit) = @_;

    foreach my $ckt_id (@{$self->{'watched_circuits'}}){
        if($circuit->{'circuit_id'} == $ckt_id){
            ##fire event!
        }
    }
}

sub circuit_modified{
    my ($self, $circuit) = @_;
    foreach my $ckt_id (@{$self->{'watched_circuits'}}){
        if($circuit->{'circuit_id'} == $ckt_id){
            warn "Found a circuit that was modified!\n";
            $self->{'provisioning'}->dataPlaneStateChange($ckt_id);
        }
    }
}

sub circuit_removed{
    my ($self, $circuit) = @_;
    foreach my $ckt_id (@{$self->{'watched_circuits'}}){
        warn "Found a circuit that was removed!\n";
        if($circuit->{'circuit_id'} == $ckt_id){
            $self->{'provisioning'}->dataPlaneStateChange($ckt_id);
        }
    }
}

sub process_request {
    my ($self, $request, $data) = @_;

    log_error("Received method call: $request");

    if($request =~ /^reserve$/){
        my $circuit = $self->{'reservation'}->reserve($data);
        if($circuit > 0 && $circuit < 99999){
            push(@{$self->{'watched_circuits'}},$circuit);
        }
        warn "WATCHED CIRCUIT: " . Data::Dumper::Dumper($self->{'watched_circuits'});
        return $circuit;
    }elsif($request =~ /^reserveCommit$/){
        return $self->{'reservation'}->reserveCommit($data);
    }elsif($request =~ /^provision$/){
        return $self->{'provisioning'}->provision($data);
    }elsif($request =~ /^terminate$/){
        return $self->{'provisioning'}->terminate($data);
    }elsif($request =~ /^release$/){
        return $self->{'provisioning'}->release($data);
    }elsif($request =~ /^querySummary$/){
        return $self->{'query'}->querySummary($data);
    }

    return OESS::NSI::Constant::UNKNOWN_REQUEST;
}

sub process_queues {
    my ($self) = @_;

    $self->{'reservation'}->process_queue();
    $self->{'provisioning'}->process_queue();
    $self->{'query'}->process_queue();
}

sub _init {
    my ($self) = @_;

    $self->{'reservation'} = new OESS::NSI::Reservation(config_file => $self->{'config_file'});
    $self->{'provisioning'} = new OESS::NSI::Provisioning(config_file => $self->{'config_file'});
    $self->{'query'} = new OESS::NSI::Query(config_file => $self->{'config_file'} );

    my $circuits = $self->{'query'}->get_current_circuits();

    foreach my $circuit (@$circuits){
        push(@{$self->{'watched_circuits'}},$circuit->{'circuit_id'});
    }

}

1;