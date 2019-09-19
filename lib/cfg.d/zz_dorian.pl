#Get documents for an eprint by (general) mime type
$c->{dorian}->{get_docs_by_type} = sub {
	my ($repo, $eprint, $type) = @_;
   	my $docs = [];
    	for my $doc ($eprint->get_all_documents){
            if($doc->value("mime_type") =~ m#^$type/# && !grep $_ eq $doc->value("mime_type"), @{$repo->get_conf("dorian","mime_exceptions")}){
                	push @{$docs}, $doc;
        	}
    	}
	return $docs;
};


# calculate image dimensions
$c->add_trigger( EP_TRIGGER_MEDIA_INFO, sub {
    my( %params ) = @_;

    my $epdata = $params{epdata};
    my $filename = $params{filename};
    my $repo = $params{repository};
    my $filepath = $params{filepath};

    return 0 if ! defined $epdata->{mime_type};
    return 0 if $epdata->{mime_type} !~ /image/;
    my $media = $epdata->{media} ||= {};
    if( open(my $fh, 'identify -format "%w,%h" '.quotemeta($filepath)."|") ){
		my $output = <$fh>;
		close($fh);
		chomp($output);
		my( $width,$height ) = split /,\s*/, $output, 2;
		$media->{width} = $width;
		$media->{height} = $height;
   }
   return 0;
}, priority => 5000);


package EPrints::Plugin::ScriptPlugin;

use strict;

our @ISA = qw/EPrints::Plugin/;

#now for the cliever bit

package EPrints::Script::Compiled;

sub run_has_type
{
    my( $self, $state, $eprint, $arg ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $repo = $state->{session}->get_repository;
    my $has = 0;
    my $type = $arg->[0];
    for my $doc ($eprint->[0]->get_all_documents){
        if($doc->value("mime_type") =~ m#^$type/# && !grep $_ eq $doc->value("mime_type"), @{$repo->get_conf("dorian","mime_exceptions")}){
                $has = 1;
                last;
        }
    }
    return [$has, "BOOLEAN"];
}

sub run_has_docs
{
    my( $self, $state, $eprint, $arg ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_docs) must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $docs = $eprint->[0]->get_all_documents;
    my $has = $docs > 0  ? 1 : 0;
    return [$docs, "BOOLEAN"];
}


sub run_get_type
{
    my( $self, $state, $eprint, $arg ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $repo = $state->{session}->get_repository;
    my $type = $arg->[0];
    my $docs = [];
    if( $repo->can_call( "dorian", "get_docs_by_type" ) )
    {
	 $docs = $repo->call( [ "dorian", "get_docs_by_type" ], $repo, $eprint->[0], $type );
    }

    return [$docs, "ARRAY"];
}


sub run_url_is_video
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }

    my $url = $eprint->[0]->get_value($value->[0]);

    return [1, "BOOLEAN"] if $url =~ m#http(s)?://(www\.)?youtube#;
    return [1, "BOOLEAN"] if $url =~ m#http(s)?://(www\.)?vimeo#;
    return [0, "BOOLEAN"];

}


sub run_url_to_embed
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $repo = $state->{session}->get_repository;

    my $url = $eprint->[0]->get_value($value->[0]);

	$url =~ s#http(s)?://(www\.)?youtube.com/watch?v=(.+)#https://www.youtube.com/embed/$3#;
	$url =~ s#http(s)?://(www\.)?youtu.be/(.+)#https://www.youtube.com/embed/$3#;

	$url =~ s#http(s)?://(www\.)?vimeo.com/(.+)#https://player.vimeo.com/video/$3#;
	if($url=~/vimeo/){
		$url.=$repo->get_conf("dorian", "vimeo_options");
	}
	if($url=~/youtube/){
		$url.=$repo->get_conf("dorian", "youtube_options");
	}

    	return [$url, "STRING"];
}

sub run_is_image
{
    my( $self, $state, $doc ) = @_;

    if( ! $doc->[0]->isa( "EPrints::DataObj::Document") )
    {
        $self->runtime_error( "is_image() must be called on a document object." );
    }
    $doc = $doc->[0];
    return [1, "BOOLEAN"] if $doc->value("mime_type") =~ m#^image/#;
    return [0, "BOOLEAN"];

}

sub run_iiif_manifest_enabled {

	my( $self, $state, $eprint, $arg ) = @_;

    	my $repo = $state->{session}->get_repository;
	my $iiif_disable = $repo->get_conf('plugins','Export::IIIFManifest','params','disable');
	print STDERR "iiif diable value: $iiif_disable\n";
	return [1, "BOOLEAN"] if(defined $iiif_disable && $iiif_disable == 0) ;

	return [0, "BOOLEAN"]
}

sub run_url_is_audio
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }

    my $url = $eprint->[0]->get_value($value->[0]);

    return [1, "BOOLEAN"] if $url =~ m#(http(s)?://(www\.)?)?soundcloud#;
    return [0, "BOOLEAN"];
}
