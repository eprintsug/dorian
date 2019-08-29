if (typeof jQuery !== 'undefined') { 
	/* tab opening etc  */
	
	function openTab(evt, cityName) {
	 	var i, x, tablinks;

	  	x = document.getElementsByClassName("dorian-panel");
	  	for (i = 0; i < x.length; i++) {
	    		x[i].style.display = "none";
	  	}
	  	tablinks = document.getElementsByClassName("tablink");
	  	for (i = 0; i < x.length; i++) {
	    		tablinks[i].className = tablinks[i].className.replace(" ep-fg", "");
	  	}
	  	document.getElementById(cityName).style.display = "block";
		if(evt.currentTarget == undefined){ //not actually an event but the button itself
			jQuery(evt).addClass("ep-fg");
		}else{
	    	evt.currentTarget.className += " ep-fg";
		}
	}


	(function($) {
	    $(document).ready(function(){


		    /******************/
		    /* Free wall init */
		    /******************/
		    var wall = new Freewall("#image_container");
		    wall.reset({
			selector: '.brick',
			animate: true,
			cellW: 200,
			cellH: 'auto',
			onResize: function() {
			    wall.fitWidth();
			}
		    });

		    wall.fitWidth();

		    wall.container.find('.brick img').load(function() {
			wall.fitWidth();
		    });
		    
		    /*******************************/
		    /* Photo swipe init for images */
		    /******************************/
		    var $pswp = $('.pswp')[0];
		    var image = [];
		    $('.picture').each( function() {
			var $pic     = $(this),
			    getItems = function() {
			var items = [];
			$pic.find('a').each(function() {
			    var $href   = $(this).attr('href'),
			    $size   = $(this).data('size').split('x'),
			    $width  = $size[0],
			    $height = $size[1];

			    var item = {
			    src : $href,
			    w   : $width,
			    h   : $height
			    }

			    items.push(item);
			});
			return items;
			    }

		    var items = getItems();

		    $.each(items, function(index, value) {
			image[index] = new Image();
			image[index].src = value['src'];
		    });

		    $pic.on('click', 'img', function(event) {
			event.preventDefault();

			var $index = $(this).data("index");

			var options = {
			index: $index,
			bgOpacity: 0.7,
			showHideOpacity: true
			}

			var lightBox = new PhotoSwipe($pswp, PhotoSwipeUI_Default, items, options);
			lightBox.init();
		    });
		    });
		
		/*Init tbas*/
		jQuery(".dorian-bar button:visible").each(function(){
		    if(jQuery(this),jQuery(this).data("panel") !== "Images"){
			openTab(jQuery(this),jQuery(this).data("panel"));
		    }
		    return false;
		});
		/*No tabs visible? then we should make the metadata panel visible */
		if(jQuery(".dorian-bar button:visible").length == 0){
		    jQuery("#Metadata").show();
		}

		}); //doc ready


	})(jQuery); //end

}
