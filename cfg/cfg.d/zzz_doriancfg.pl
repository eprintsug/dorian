
#These query string options will be appended to embeded video URLs for youtub or vimeo
$c->{dorian}->{vimeo_options} = "?loop=false&amp;byline=false&amp;portrait=false&amp;title=false&amp;speed=true&amp;transparent=0&amp;gesture=media";
$c->{dorian}->{youtube_options} = "?origin=https://plyr.io&amp;iv_load_policy=3&amp;modestbranding=1&amp;playsinline=1&amp;showinfo=0&amp;rel=0&amp;enablejsapi=1";
#If this is 'TRUE' the plyr will match images with videos and use the images as "posters" for the videos
$c->{dorian}->{use_images_as_posters}  = 'TRUE';


