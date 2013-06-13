//
//  StormModelViewController.h
//  Storm
//  That's how MVC works, right?
//
//  Created by Jacob Farkas on 6/13/13.
//  Copyright (c) 2013 Jacob Farkas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StormModelViewController : UIViewController
@property (nonatomic, strong) IBOutlet UILabel *statusText;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIImageView *icon;
@end
