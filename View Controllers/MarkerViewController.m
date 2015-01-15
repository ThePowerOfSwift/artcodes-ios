/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2015  Aestheticodes
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#import "Marker.h"
#import "MarkerViewController.h"

@interface MarkerViewController ()
@end

@implementation MarkerViewController

@synthesize webView;
@synthesize action;

- (void)viewWillAppear: (BOOL)animated
{
    [super viewWillAppear: animated];
	
	NSString* title;
	if(action.title)
	{
		title = [NSString stringWithFormat:action.title, action.code];
	}
	else
	{
		title = [NSString stringWithFormat:@"Marker %@", action.code];
	}
	
	NSString* description;
	if(action.description)
	{
		description = action.description;
	}
	else if (action.action)
	{
		description = action.action;
	}
	
	NSString* actionURL = action.action;
	
	NSString* image;
	if (action.image)
	{
		image = action.image;
	}
	else
	{
		image = @"aestheticodes.png";
	}
	
	NSError* error = nil;
	NSString *path = [[NSBundle mainBundle] pathForResource: @"marker" ofType: @"html"];
	NSString *res = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];

	NSString* html = [NSString stringWithFormat: res, image, title, actionURL, description];
	
	NSLog(@"%@", html);
	
	[webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
	
	[super viewDidLoad];
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
	if ( inType == UIWebViewNavigationTypeLinkClicked ) {
		[[UIApplication sharedApplication] openURL:[inRequest URL]];
		return NO;
	}
	
	return YES;
}

@end