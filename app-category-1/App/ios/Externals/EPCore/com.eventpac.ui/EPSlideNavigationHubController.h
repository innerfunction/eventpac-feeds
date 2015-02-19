//
//  EPSlideNavigationHubController.h
//  EPCore
//
//  Created by Julian Goacher on 18/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "SWRevealViewController.h"
#import "EPComponent.h"
#import "EPConfiguration.h"
#import "EPView.h"
#import "EPBarButtonItem.h"
#import "UIViewController+EP.h"

// A slide navigation hub controller is a view controller that allows navigation from a main view to sub-views
// using an SWReveal sliding menu controller.
// The sliding menu controller is composed of rear and front views. The navigation hub begins by displaying the
// main view in its rear view, with the rear view fully visible. Navigating from the main view to any sub view
// involves displaying the sub view in the front view and sliding the front view over the rear view.
// A back button is added to the front view's title bar. When tapped, this causes the front view to slide over
// so that the rear view, containing the main view, is partially visible. The user can then navigate from the
// main view to a new sub-view.
@interface EPSlideNavigationHubController : SWRevealViewController <EPComponent, EPView, EPEventHandler, EPNavigationDelegate, SWRevealViewControllerDelegate> {
    EPConfiguration *configuration;
    // The view's navigation button. This is the default button in the title bar's LHS position,
    // and is typically a back button added by a navigation controller, or a menu button added
    // by a navigation drawer.
    UIBarButtonItem *navButton;
    // The view's back button. This is added to the LHS position of the front view controller when
    // made visible, and is used to reveal the rear view controller.
    EPBarButtonItem *backButton;
    // The currently observed navigation item. Used to transfer buttons + titles from the active front/rear view controller
    // to this view's title bar.
    UINavigationItem *observedItem;
}

@end
