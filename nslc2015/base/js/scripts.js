 $(document).ready( function() {   
 console.log("document read"); 
    scrollFixedElements ( $('body') );      
});


function resetPositions(){

    var $fixElements = $('.position-absolute');
    if ( $fixElements.length > 0 ) {
        $($fixElements).addClass('fixed').removeClass('position-absolute');

        var $header =  $('header') ;
        $header.css('margin', ' 0');

        var $fixedHeader = $(".header")  ;
        $($header).insertAfter( $($fixedHeader) );
    }
}

function scrollFixedElements( $container ) {

    var $banner =  $( $($container).find('.shape-container') );

    var $fixedObjects =  $('.fixed' );
    /*var $tabs = $(".fixed.tabs").length == 1 ? $('.fixed.tabs') : false;*/

    var $lastFixedObject = $($fixedObjects[$fixedObjects.length -1] );
    console.log("last fixd object");
    console.log($lastFixedObject);
 
    $( document ).scroll( function() {

        if ( $(window).height() > 450 && $banner.length > 0 && $fixedObjects.length > 0 ) {
            
            var $pageContent = $container.find(".description  p:first");
            console.log($pageContent);

            

            var pageContentTop = $($pageContent).position().top;
            var posBottomFixed = $lastFixedObject.position().top + parseInt($lastFixedObject.css('height')) + parseInt($lastFixedObject.css('padding-top')) + parseInt($lastFixedObject.css('padding-bottom'));
     
            var offsetTop= $(this).scrollTop() + posBottomFixed;

            console.log("pageContent top------------- " + pageContentTop);
            console.log("PosBottom fixed------------- " + posBottomFixed);
            if ( pageContentTop <= offsetTop  ) {


               $lastFixedObject.addClass('position-absolute').removeClass('fixed');
          

               var $header = $("header");



                /*$header.css('margin', '0 -15px');*/

                var $pageContent = $($container.find(".description"));
                if ( parseInt($pageContent.css('margin-top') )> 0  ){
                    $pageContent.css('margin-top', 0);
                }
              

                $("header").insertBefore($($pageContent));
            
            }

            var scrollPositionTop =  $(this).scrollTop() ;
            
            if( scrollPositionTop <= $("header").position().top ){
                resetPositions();
            }

          
        } else {                      
            resetPositions();                        
        }
            
    });     
};  