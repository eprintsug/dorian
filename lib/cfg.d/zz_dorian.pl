#Get documents for an eprint by (general) mime type
$c->{dorian}->{get_docs_by_type} = sub {
	my ($repo, $eprint, $type) = @_;
   	my $docs = [];
    	for my $doc ($eprint->get_all_documents){
            push (@{$docs}, $doc) if(is_a_valid_dorian_doc($repo, $doc, $type));
    	}
	return $docs;
};

sub is_a_valid_dorian_doc {
    my ($repo, $doc, $type) = @_;
    my $is_valid_mimetype = $doc->value("mime_type") =~ m#^$type/#;
    my $is_not_an_exception = !grep $_ eq $doc->value("mime_type"), 
                                @{$repo->get_conf("dorian","mime_exceptions")};
    my $is_public = $doc->is_public;
    
    return  $is_valid_mimetype && 
            $is_not_an_exception && 
            $is_public;
}

# calculate image dimensions
$c->add_trigger( EP_TRIGGER_MEDIA_INFO, sub {
    my( %params ) = @_;
    my $epdata = $params{epdata};
    my $filename = $params{filename};
    my $repo = $params{repository};
    my $filepath = $params{filepath};

    return 0 if ! defined $epdata->{mime_type};
    return 0 if $epdata->{mime_type} !~ /image/;

    # if there's some orientation data in there we need to flip the height and width or the image will look out of proportion
    my $rotated = 0;
    my $identify = "/usr/bin/identify";

    use Proc::Reliable;
    my $myproc = Proc::Reliable->new();
    my $orientation = $myproc->run( "$identify -format '%[EXIF:Orientation]' $filepath" );
    $rotated = 1 if( defined $orientation && $orientation > 4 && $orientation < 9 );

    my $media = $epdata->{media} ||= {};
    if( open(my $fh, 'identify -format "%w,%h" '.quotemeta($filepath)."|") ){
		my $output = <$fh>;
		close($fh);
		chomp($output);
		my( $width,$height ) = split /,\s*/, $output, 2;
        if( $rotated == 0 )
        {
		    $media->{width} = $width;
    		$media->{height} = $height;
        }
        else
        {
		    $media->{width} = $height;
    		$media->{height} = $width;
        }
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

# does a field contain a url we want to display
sub run_url_is_video
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }

    my $field_name = $value->[0];

    # get the url
    my $url = $eprint->[0]->get_value( $value->[0] );

    # if this url is represented by a document (i.e. it's a downloaded youtube video) don't show it again
    foreach my $doc ($eprint->[0]->get_all_documents)
    {
        foreach my $rel (@{$doc->value( "relation" )})
        {
            if( $rel->{type} eq EPrints::Utils::make_relation( "isYoutubeVideo" ) && 
                ( $url eq $rel->{uri} ) )
            {
                # we already have this url as an upload, so we don't need to display it again
                return [0, "BOOLEAN"];
            }
        }
    }

    return [1, "BOOLEAN"] if defined $url && $url =~ m#http(s)?://(www\.)?youtube#;
    return [1, "BOOLEAN"] if defined $url && $url =~ m#http(s)?://(www\.)?vimeo#;
    return [0, "BOOLEAN"];
}

# is a url a video we want to display
sub run_url_value_is_video
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }

    # get the url
    my $url = $value->[0];

    # don't display if we have this elsewhere - i.e. if we have it in official url
    if( defined $url && $eprint->[0]->is_set( "official_url" ) && $eprint->[0]->get_value( "official_url" ) eq $url )
    {
        return [0, "BOOLEAN"];
    }

    # if this url is represented by a document (i.e. it's a downloaded youtube video) don't show it again
    foreach my $doc ($eprint->[0]->get_all_documents)
    {
        foreach my $rel (@{$doc->value( "relation" )})
        {
            if( $rel->{type} eq EPrints::Utils::make_relation( "isYoutubeVideo" ) && 
                ( $url eq $rel->{uri} ) )
            {
                # we already have this url as an upload, so we don't need to display it again
                return [0, "BOOLEAN"];
            }
        }
    }

    return [1, "BOOLEAN"] if defined $url && $url =~ m#http(s)?://(www\.)?youtube#;
    return [1, "BOOLEAN"] if defined $url && $url =~ m#http(s)?://(www\.)?vimeo#;
    return [0, "BOOLEAN"];
}


# checks if given field (e.g. related_url_url) contains a video URL - used to know if we need to display the video section
sub run_field_has_video {
    my($self, $state, $eprint, $value) = @_;
    if(!$eprint->[0]->isa("EPrints::DataObj::EPrint")) {
        $self->runtime_error( 
            "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my @urls = @{$eprint->[0]->get_value($value->[0])};
    foreach my $url ( @urls )
    {
        return [1, "BOOLEAN"] if $url =~ m#http(s)?://(www\.)?youtube#;
        return [1, "BOOLEAN"] if $url =~ m#http(s)?://(www\.)?vimeo#;
    }
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

	$url =~ s#http(s)?://(www\.)?youtube.com/watch\?v=(.+)#https://www.youtube.com/embed/$3#;
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

sub run_url_value_to_embed
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $repo = $state->{session}->get_repository;

    my $url = $value->[0];

	$url =~ s#http(s)?://(www\.)?youtube.com/watch\?v=(.+)#https://www.youtube.com/embed/$3#;
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

# checks if given field (e.g. official_url) contains an audio URL - used to know if we need to display the audio section and when rendering an individual value
sub run_url_is_audio {
    my($self, $state, $eprint, $value) = @_;

    if(!$eprint->[0]->isa("EPrints::DataObj::EPrint")) {
        $self->runtime_error( 
            "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $url = $eprint->[0]->get_value($value->[0]);
    return [1, "BOOLEAN"] if $url =~ m#(http(s)?://(www\.)?)?soundcloud#;
    return [0, "BOOLEAN"];
}

# checks if given field (e.g. related_url_url) contains an audio URL - used to knwo if we need to display the audio section
# checks all values in a field rather than an individual value, distinguishing it from run_url_value_is_audio
sub run_field_has_audio {
    my($self, $state, $eprint, $value) = @_;
    if(!$eprint->[0]->isa("EPrints::DataObj::EPrint")) {
        $self->runtime_error( 
            "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my @urls = @{$eprint->[0]->get_value($value->[0])};
    foreach my $url ( @urls )
    {
        return [1, "BOOLEAN"] if $url =~ m#(http(s)?://(www\.)?)?soundcloud#;
    }
    return [0, "BOOLEAN"];
}

# pass a URL value from a field (e.g. related_url field) - used when emedding audio urls
sub run_url_value_is_audio {
	my( $self, $state, $eprint, $value ) = @_;
	if( !$eprint->[0]->isa( "EPrints::DataObj::EPrint" ) )
	{
		$self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
	}

	my $url = $value->[0];
    # if this url is already an official url, don't embed the audio again
    if( defined $url && $eprint->[0]->is_set( "official_url" ) && $eprint->[0]->get_value( "official_url" ) eq $url )
    {
		return [0, "BOOLEAN"];
    }
	
	return [1, "BOOLEAN"] if $url =~ m#(http(s)?://(www\.)?)?soundcloud#;
	return [0, "BOOLEAN"];
}
