 $(document).ready( function() {

    var $tabs = $(".tabs.fixed > .tab-btn");
    
    if ($tabs.length > 0) { 

        var $firstTab = $( $tabs[0] ).children('a') ;

        $firstTab.addClass('active');

        var $tabContent = $( '#content-' + $firstTab.attr('href') );
        $tabContent.addClass('visible').removeClass('hide');

        
        scrollFixedElements( $tabContent );

        $('.tab-btn > a').bind('click', function(e) {
            e.preventDefault();

            //get info new tab
            var $this = $(this);
            var target = $this.attr('href');

            var $currentTabContent = $('#content-' + target);

            $($currentTabContent).removeClass('hide').addClass('visible');

            //hide previous tab
            var $previousTab = $(".tab-btn > .active");
            

            var $previousTabContent = $('#content-' + $previousTab.attr('href') );

            $( $previousTabContent).removeClass('visible').addClass('hide');

            $previousTab.removeClass('active');


            //active current tab
            $this.addClass('active');

            resetPositions( $('.position-absolute').addClass('fixed').removeClass('position-absolute') );
            scrollFixedElements( $currentTabContent );
        });
    } else {
        scrollFixedElements ( $('body') );
    }

    
        
});


function resetPositions(){

    var $fixElements = $('.position-absolute');
    if ( $fixElements.length > 0 ) {
        $($fixElements).addClass('fixed').removeClass('position-absolute');

        var $header =  $('.header') ;
        $header.css('margin', ' 0');

        var $fixedHeader = $("header").length > 0 ? $("header") : $(".title.fixed") ;
        $($header).insertAfter( $($fixedHeader) );
    }
}

function scrollFixedElements( $container ) {

    var $banner =  $( $($container).find('.image-container.banner') );

    var $fixedObjects =  $('.fixed' ).not('.tabs');
    var $tabs = $(".fixed.tabs").length == 1 ? $('.fixed.tabs') : false;

    var $lastFixedObject = $($fixedObjects[$fixedObjects.length -1] );

 
    $( document ).scroll( function() {

        if ( $(window).height() > 450 && $banner.length > 0 && $fixedObjects.length > 0 ) {
            
            var $pageContent = $container.find(".page-content");
            console.log($pageContent);

            

            var pageContentTop = $($pageContent).position().top;
            var posBottomFixed = $lastFixedObject.position().top + parseInt($lastFixedObject.css('height') );
     
            var offsetTop= $(this).scrollTop() + posBottomFixed;

            console.log("pageContent top------------- " + pageContentTop);
            console.log("PosBottom fixed------------- " + posBottomFixed);
            if ( pageContentTop <= offsetTop  ) {


               $lastFixedObject.addClass('position-absolute').removeClass('fixed');
          

               var $header = $(".header");



                $header.css('margin', '0 -15px');

                var $pageContent = $($container.find(".page-content"));

              

                $(".header").insertBefore($($pageContent));
            
            }

            var scrollPositionTop = $tabs == false ? $(this).scrollTop() : parseInt( $tabs.css('height') ) + $(this).scrollTop();
            
            if( scrollPositionTop <= $(".header").position().top ){
                resetPositions();
            }

          
        } else {                      
            resetPositions();                        
        }
            
    });     
};  