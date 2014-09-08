//
//  MarkerActionEditController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "MarkerAction.h"
#import "Experience.h"
#import "MarkerActionEditController.h"

@interface MarkerActionEditController ()
@property UIBarButtonItem* addButton;
@end

@implementation MarkerActionEditController
@synthesize addButton;
@synthesize action;

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(action && action.editable)
	{
		return 2;
	}
    return 1;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	UIView* view = cell.contentView;
	for(UIView* subview in view.subviews)
	{
		if([subview isKindOfClass:[UITextView class]])
		{
			[subview becomeFirstResponder];
		}
		else if([subview isKindOfClass:[UIButton class]])
		{
			[(UIButton*)subview sendActionsForControlEvents:UIControlEventTouchUpInside];
		}
	}
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	[self loadValues];
}

-(IBAction)cancel:(UIBarButtonItem*)sender
{
	[self.navigationController popViewControllerAnimated:true];
}


-(IBAction)save:(UIBarButtonItem*)sender
{
	if(!action)
	{
        // if we're creating a new marker:
		action = [[MarkerAction alloc] init];
		action.code = codeView.text;
		action.action = urlView.text;
        action.visible = true;
        action.editable = true;
		[self.experience.markers addObject:action];
		self.experience.changed = true;
	}
	else if(action.editable)
	{
        // if we're edditing an existing marker:
		if(action.code != codeView.text)
		{
			//[self.experience.markers removeObject:action];
			action.code = codeView.text;
			action.action = urlView.text;
			//[self.experience.markers addObject:action];
			self.experience.changed = true;
		}
		else if(action.action != urlView.text)
		{
			action.action = urlView.text;
			self.experience.changed = true;
		}
	}
	
	[self.navigationController popViewControllerAnimated:true];
}

-(void)loadValues
{
	if(action)
	{
		codeView.text = action.code;
		urlView.text = action.action;
		
		codeView.enabled = false;
		urlView.enabled = action.editable;
		
		if(!action.editable)
		{
			//let sections = NSIndexSet(index : 1)
			[self.navigationItem setLeftBarButtonItem:nil];
			[self.navigationItem setRightBarButtonItem:nil];
		}
		
		[urlView becomeFirstResponder];
	}
	else
	{
		codeView.enabled = true;
		
		addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(save:)];
		[self.navigationItem setRightBarButtonItem:addButton];
		
		[codeView becomeFirstResponder];

		[self validate:codeView];
	}
}

-(IBAction)validate:(id)sender
{
	bool valid = true;
	if([self.experience isKeyValid: codeView.text])
	{
		codeView.rightViewMode = UITextFieldViewModeNever;
	}
	else
	{
		codeView.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error.png"]];
		codeView.rightViewMode = UITextFieldViewModeAlways;
		valid = false;
	}
	
	NSString* urlRegEx = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
	
	if([urlView.text rangeOfString:urlRegEx options:NSRegularExpressionSearch].location != NSNotFound)
	{
		urlView.rightViewMode = UITextFieldViewModeNever;
	}
	else
	{
		urlView.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error.png"]];
		urlView.rightViewMode = UITextFieldViewModeAlways;
		valid = false;
	}
	
	if(doneButton)
	{
		doneButton.enabled = valid;
	}
	
	if(addButton)
	{
		addButton.enabled = valid;
	}
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 1:
			[self.experience.markers removeObject:action];
			[self.navigationController popViewControllerAnimated:true];
		default:
			NSLog(@"Delete was cancelled by the user");
	}
}

-(IBAction)deleteItem:(id)sender
{
	UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Confirm Delete";
	alert.message = @"Are you sure you want to delete this marker?";
	alert.delegate = self;
	[alert addButtonWithTitle:@"Cancel"];
	[alert addButtonWithTitle:@"Delete"];
	[alert show];
}
@end
