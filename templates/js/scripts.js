 $(document).ready( function() {


            scrollFixedElements();
            function resetPositions(){

                var $fixElements = $('.position-absolute');
                if ( $fixElements.length > 0 ) {
                    $($fixElements).addClass('fixed').removeClass('position-absolute');

                    var $header = $('.header');
                    $header.css('margin', ' 0');
                    var $fixedHeader = $("header");
                    $($header).insertAfter( $($fixedHeader) );
                }
            }

            function scrollFixedElements( ) {

                var $banner =  $('.image-container.banner') ;

                var $fixedObjects =  $('.fixed') ;

                var $lastFixedObject = $($fixedObjects[$fixedObjects.length -1] );

                $( document ).scroll( function() {

                    if ( $(window).height() > 450 && $banner.length > 0 && $fixedObjects.length > 0 ) {
                       
                        var posBottomFixed = $lastFixedObject.position().top + parseInt($lastFixedObject.css('height') );
                        
                        var posBottomBanner = $banner.offset().top + parseInt($banner.css('height'));

                        var offsetTopBanner = $(this).scrollTop() + posBottomFixed ;
                        var offsetTop= $(this).scrollTop()


                        if (  offsetTopBanner  > posBottomBanner ){

                            $fixedObjects.addClass('position-absolute').removeClass('fixed');

                            var $header = $('.header');
                            $header.css('margin', '0 -15px');

                            $($header).insertBefore(".page-content");
                        }  

                        if( offsetTop <= $('.header').position().top ){
                            resetPositions();
                        }

                      
                    } else {                      
                        resetPositions();                        
                    }
                        
                });     
            };  
        
    });